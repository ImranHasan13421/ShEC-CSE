import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ShEC_CSE/main.dart'; // Imports the global navigatorKey

class ConnectivityService {
  /// Asynchronously checks for active internet connection via a robust Google DNS lookup.
  static Future<bool> hasInternet() async {
    if (kIsWeb) {
      // On web, dart:io InternetAddress lookup is not supported and will throw.
      // We assume online, letting standard network calls fail naturally or fallback to kIsWeb check.
      return true;
    }
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Displays an aesthetic, floating glassmorphic-styled toast notification at the bottom
  /// of the screen using the global navigator Context.
  static void showNoInternetToast({String message = 'Internet connection required for this action.'}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
