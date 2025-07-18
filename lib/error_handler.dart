// error_handler.dart - Clean version without dead code
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  // Simple error logging for development
  static void logError(String operation, dynamic error,
      [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ Error in $operation: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  // Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    }
    if (errorString.contains('storage') || errorString.contains('space')) {
      return 'Storage error. Please free up some space.';
    }
    if (errorString.contains('firebase') || errorString.contains('cloud')) {
      return 'Cloud sync error. Data saved locally.';
    }
    if (errorString.contains('audio') || errorString.contains('microphone')) {
      return 'Audio error. Please check microphone permissions.';
    }
    if (errorString.contains('file') || errorString.contains('path')) {
      return 'File error. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  // Show error message to user
  static void showError(BuildContext context, String operation, dynamic error) {
    logError(operation, error);

    if (!context.mounted) return;

    final message = getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show info message
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Wrapper for async operations with error handling
  static Future<T?> safeAsync<T>(
    String operation,
    Future<T> Function() asyncFunction, {
    BuildContext? context,
  }) async {
    try {
      return await asyncFunction();
    } catch (error, stackTrace) {
      logError(operation, error, stackTrace);

      if (context != null && context.mounted) {
        showError(context, operation, error);
      }

      return null;
    }
  }
}

// Extension for easier error handling
extension ErrorHandlerExtension on BuildContext {
  void showError(String operation, dynamic error) {
    ErrorHandler.showError(this, operation, error);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccess(this, message);
  }

  void showInfo(String message) {
    ErrorHandler.showInfo(this, message);
  }
}
