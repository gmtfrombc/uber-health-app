import 'package:flutter/foundation.dart';

/// Utility class for debugging functionality
class DebugUtils {
  /// Intentionally trigger an error to test error handling functionality
  static void triggerTestError({required String message}) {
    if (kDebugMode) {
      debugPrint('⚠️ Triggering test error: $message');

      // Trigger an intentional exception
      try {
        // Create different types of exceptions for testing
        switch (message) {
          case 'async':
            _triggerAsyncError();
            break;
          case 'firebase':
            throw Exception('Simulated Firebase Authentication failure');
          case 'null':
            String? nullString;
            // ignore: unnecessary_null_comparison
            print(nullString!.length); // This will throw a null error
            break;
          default:
            throw Exception('Manually triggered test exception: $message');
        }
      } catch (e, stack) {
        debugPrint('🔥 Test error triggered successfully:');
        debugPrint('Error: $e');
        debugPrint('Stack: $stack');
        rethrow; // Rethrow to be caught by the error handler
      }
    } else {
      debugPrint('Test errors can only be triggered in debug mode');
    }
  }

  /// Trigger an async error for testing error handling with async gaps
  static Future<void> _triggerAsyncError() async {
    debugPrint('Triggering async error after delay...');
    await Future.delayed(const Duration(milliseconds: 500));
    throw Exception('Simulated asynchronous operation failure');
  }

  /// Get app version info for diagnostics
  static String getVersionInfo() {
    // In a real app, you would pull this from your pubspec or package info
    return 'Version: 0.9.0+10 (Test Build)';
  }

  /// Print a list of available debug commands
  static void printDebugCommands() {
    if (kDebugMode) {
      debugPrint('''
=====================================================
DEBUG COMMANDS AVAILABLE:
-----------------------------------------------------
• DebugUtils.triggerTestError(message: 'async');
  - Test async error handling
  
• DebugUtils.triggerTestError(message: 'firebase');
  - Test Firebase error handling
  
• DebugUtils.triggerTestError(message: 'null');
  - Test null pointer exception handling
  
• DebugUtils.triggerTestError(message: 'custom message');
  - Test with your own error message
=====================================================
''');
    }
  }
}
