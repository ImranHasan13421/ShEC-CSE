import 'package:flutter/material.dart';
import 'package:ShEC_CSE/main.dart'; // Imports global navigatorKey

class SnackBarUtils {
  /// Cleans technical prefixes from error messages (e.g., "Exception: ", "PostgrestException: ", etc.)
  static String cleanErrorMessage(String rawMessage) {
    return rawMessage
        .replaceAll(RegExp(r'^(Exception:\s*|PostgrestException:\s*|Exception:\s*|Error:\s*)'), '')
        .trim();
  }

  /// Displays a premium styled floating error SnackBar.
  static void showError(BuildContext? context, String rawMessage) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final String cleanMessage = cleanErrorMessage(rawMessage);
    final theme = Theme.of(ctx);
    final colors = theme.colorScheme;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cleanMessage.isEmpty ? 'An unexpected error occurred' : cleanMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.error.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a premium styled floating success SnackBar.
  static void showSuccess(BuildContext? context, String message) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final theme = Theme.of(ctx);
    final colors = theme.colorScheme;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
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
        backgroundColor: Colors.green.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays a premium styled floating info SnackBar.
  static void showInfo(BuildContext? context, String message) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final theme = Theme.of(ctx);
    final colors = theme.colorScheme;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
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
        backgroundColor: colors.primary.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
