import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system
  static const String _themeModeKey = 'theme_mode';
  bool _initialized = false;

  ThemeProvider() {
    // Attempt to load theme mode, but don't wait for it
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // For system mode, check the platform brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isInitialized => _initialized;

  Future<void> _loadThemeMode() async {
    try {
      debugPrint('Loading theme mode preferences...');
      final prefs = await SharedPreferences.getInstance();
      final storedThemeMode = prefs.getString(_themeModeKey);

      if (storedThemeMode != null) {
        if (storedThemeMode == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (storedThemeMode == 'light') {
          _themeMode = ThemeMode.light;
        } else if (storedThemeMode == 'system') {
          _themeMode = ThemeMode.system;
        }
        debugPrint('Theme mode loaded: ${_themeMode.toString()}');
      } else {
        // If no preference is stored, use system default
        _themeMode = ThemeMode.system;
        debugPrint('No saved theme mode found, using system default');
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      // Handle SharedPreferences errors gracefully
      debugPrint('Error loading theme mode: $e');
      debugPrint('Using system theme mode due to error');
      _themeMode = ThemeMode.system;
      _initialized =
          true; // Still mark as initialized to prevent further attempts
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    // Cycle through theme modes: system -> light -> dark -> system
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String valueToStore = 'system';

      if (_themeMode == ThemeMode.dark) {
        valueToStore = 'dark';
      } else if (_themeMode == ThemeMode.light) {
        valueToStore = 'light';
      }

      await prefs.setString(_themeModeKey, valueToStore);
      debugPrint('Theme preference saved: ${_themeMode.toString()}');
    } catch (e) {
      // Even if saving fails, we keep the theme change in memory
      debugPrint('Error saving theme mode preference: $e');
      debugPrint('Theme was changed in memory but not persisted');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        String valueToStore = 'system';

        if (_themeMode == ThemeMode.dark) {
          valueToStore = 'dark';
        } else if (_themeMode == ThemeMode.light) {
          valueToStore = 'light';
        }

        await prefs.setString(_themeModeKey, valueToStore);
        debugPrint('Theme preference saved: ${_themeMode.toString()}');
      } catch (e) {
        // Even if saving fails, we keep the theme change in memory
        debugPrint('Error saving theme mode preference: $e');
        debugPrint('Theme was changed in memory but not persisted');
      }
    }
  }
}
