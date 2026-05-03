import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/messenger/models/chat_state.dart';
import '../../features/profile/models/profile_state.dart';
import 'notification_service.dart';

class ChatService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Fetch available rooms based on user role
  static Future<void> fetchRooms() async {
    isLoadingChatRooms.value = true;
    try {
      final response = await _client.from('chat_rooms').select();
      chatRoomsList.value = (response as List)
          .map((row) => ChatRoom.fromJson(row))
          .toList();
    } catch (e) {
      print('Error fetching chat rooms: $e');
    } finally {
      isLoadingChatRooms.value = false;
    }
  }

  // Send a message and return the created object
  static Future<ChatMessage?> sendMessage(String roomId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = currentProfile.value;

    final response = await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': user.id,
      'sender_name': profile.name.isEmpty ? 'Member' : profile.name,
      'sender_image': profile.imagePath, // Save the profile image path
      'text': text,
    }).select().single();

    return ChatMessage.fromJson(response, user.id);
  }

  // Subscribe to real-time messages for a room
  static RealtimeChannel subscribeToRoom(String roomId, Function(ChatMessage) onMessage) {
    final userId = _client.auth.currentUser?.id ?? '';
    
    return _client
        .channel('room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final newMessage = ChatMessage.fromJson(payload.newRecord, userId);
            onMessage(newMessage);
          },
        )
        .subscribe();
  }

  // Fetch message history
  static Future<List<ChatMessage>> fetchMessageHistory(String roomId) async {
    final userId = _client.auth.currentUser?.id ?? '';
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: true);
      
      return (response as List)
          .map((row) => ChatMessage.fromJson(row, userId))
          .toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  // Global subscription for background notifications
  static void subscribeToAllMessages() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _client
      .channel('global_messages')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final data = payload.newRecord;
          if (data['sender_id'] != userId) {
            final room = chatRoomsList.value.firstWhere(
              (r) => r.id == data['room_id'],
              orElse: () => ChatRoom(
                id: '', 
                name: 'Group', 
                description: '', 
                type: ChatRoomType.general,
                iconKey: 'groups',
                createdAt: DateTime.now(),
              ),
            );

            NotificationService.incrementUnread('messenger');
            NotificationService.showNotification(
              id: 4,
              title: '${data['sender_name']} (${room.name})',
              body: data['text'] ?? 'Sent a message',
            );
          }
        },
      )
      .subscribe();
  }
}
