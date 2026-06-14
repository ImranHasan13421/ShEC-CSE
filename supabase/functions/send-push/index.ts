import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { decodeBase64 } from "https://deno.land/std@0.208.0/encoding/base64.ts";

// Helper function to encode Uint8Array to base64url
function base64url(source: Uint8Array): string {
  const binString = String.fromCharCode(...source);
  return btoa(binString)
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

// Pure WebCrypto Google OAuth Access Token Fetcher (Sandbox Safe - no filesystem access)
async function getGoogleAccessToken(
  clientEmail: string,
  privateKeyPem: string
): Promise<string> {
  // Clean private key string from PEM headers, literal '\n', real newlines, and whitespace
  const cleanKey = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\n/g, "")
    .replace(/\r/g, "")
    .replace(/\s/g, "");

  const binaryKey = decodeBase64(cleanKey);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encoder = new TextEncoder();
  const encodedHeader = base64url(encoder.encode(JSON.stringify(header)));
  const encodedPayload = base64url(encoder.encode(JSON.stringify(payload)));

  const securedInput = `${encodedHeader}.${encodedPayload}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(securedInput)
  );

  const signedJwt = `${securedInput}.${base64url(new Uint8Array(signature))}`;

  // Exchange JWT for Access Token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error("Failed to exchange JWT for token: " + await tokenResponse.text());
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const { table, record, type } = payload;

    if (type !== "INSERT") {
      return new Response("Skipping non-INSERT event", { status: 200 });
    }

    // Initialize Supabase Client using local environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    let title = "";
    let body = "";
    let recipientTokens: string[] = [];

    if (table === "messages") {
      const { room_id, sender_id, sender_name, text } = record;

      // 1. Fetch the chat room details to get type and name
      const { data: room } = await supabase
        .from("chat_rooms")
        .select("name, type")
        .eq("id", room_id)
        .single();

      if (!room) return new Response("Room not found", { status: 404 });

      title = `${sender_name} (${room.name})`;
      body = text || "Sent a message";

      // 2. Query target user tokens excluding the sender
      let query = supabase
        .from("profiles")
        .select("fcm_token")
        .is("is_approved", true)
        .neq("id", sender_id);

      if (room.type === "committee") {
        query = query.in("role", ["committee", "superuser"]);
      }
      
      const { data: profiles } = await query;
      recipientTokens = profiles?.map(p => p.fcm_token).filter(Boolean) || [];

    } else if (table === "notices") {
      title = `New Notice: ${record.title}`;
      body = record.subtitle || "A new notice has been posted.";

      const { data: profiles } = await supabase
        .from("profiles")
        .select("fcm_token")
        .is("is_approved", true);
      recipientTokens = profiles?.map(p => p.fcm_token).filter(Boolean) || [];

    } else if (table === "jobs") {
      title = `New Job Opportunity`;
      body = `${record.role} at ${record.company}`;

      const { data: profiles } = await supabase
        .from("profiles")
        .select("fcm_token")
        .is("is_approved", true);
      recipientTokens = profiles?.map(p => p.fcm_token).filter(Boolean) || [];

    } else if (table === "contests") {
      title = `New Contest Scheduled`;
      body = record.title;

      const { data: profiles } = await supabase
        .from("profiles")
        .select("fcm_token")
        .is("is_approved", true);
      recipientTokens = profiles?.map(p => p.fcm_token).filter(Boolean) || [];
    }

    if (recipientTokens.length === 0) {
      return new Response("No recipients to notify", { status: 200 });
    }

    // 3. Get Google FCM Access Token from service account credentials (env or vault RPC)
    let projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    let privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
    let clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");

    if (!projectId || !privateKey || !clientEmail) {
      // Query secrets from vault via RPC helper
      const { data: secrets, error: secretsError } = await supabase.rpc("get_firebase_secrets");
      if (secretsError || !secrets) {
        throw new Error("Failed to fetch Firebase secrets from vault RPC: " + (secretsError?.message || "No data"));
      }
      
      for (const secret of secrets) {
        if (secret.name === "FIREBASE_PROJECT_ID") projectId = secret.secret;
        if (secret.name === "FIREBASE_CLIENT_EMAIL") clientEmail = secret.secret;
        if (secret.name === "FIREBASE_PRIVATE_KEY") privateKey = secret.secret;
      }
    }

    if (!projectId || !privateKey || !clientEmail) {
      throw new Error("Firebase secrets are missing in both environment and database vault.");
    }

    const accessToken = await getGoogleAccessToken(clientEmail, privateKey);

    // 4. Send Notifications in Parallel via FCM REST API v1
    const sendPromises = recipientTokens.map(async (fcmToken) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: {
                title,
                body,
              },
              data: {
                table,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
          }),
        }
      );
      if (!response.ok) {
        console.error(`FCM send failed for token ${fcmToken}:`, await response.text());
      }
    });

    await Promise.all(sendPromises);

    return new Response(`Successfully sent push notifications to ${recipientTokens.length} devices.`, { status: 200 });
  } catch (error) {
    console.error("Error sending push notifications:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
