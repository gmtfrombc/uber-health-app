import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Utility class for safer BuildContext operations
class ContextUtils {
  /// Safely access a provider instance in a way that can be stored for later use
  /// This avoids the common error of using Provider.of in dispose() methods
  static T safeProviderOf<T>(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } catch (e) {
      throw Exception('Safe provider access failed: $e');
    }
  }

  /// Safely navigate when there's a risk of the context being invalid
  static Future<T?> safeNavigate<T>(
    BuildContext context,
    Widget destination, {
    bool replacement = false,
  }) async {
    // First check if context is still valid
    if (!context.mounted) {
      debugPrint('Navigation canceled: context is no longer mounted');
      return null;
    }

    try {
      if (replacement) {
        return await Navigator.pushReplacement(
          context,
          MaterialPageRoute<T>(builder: (_) => destination),
        );
      } else {
        return await Navigator.push(
          context,
          MaterialPageRoute<T>(builder: (_) => destination),
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      return null;
    }
  }

  /// Safely post-frame operations to avoid BuildContext issues
  static void postFrame(BuildContext context, Function(BuildContext) callback) {
    final contextRef = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (contextRef.mounted) {
        callback(contextRef);
      } else {
        debugPrint(
          'Post-frame callback not executed: context is no longer mounted',
        );
      }
    });
  }
}
