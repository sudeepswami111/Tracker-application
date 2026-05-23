import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  ThemeMode _themeMode = ThemeMode.dark; // Default: dark
  Color _accentColor = AppColors.voltCyan; // Default: voltCyan

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_prefKey);
    if (savedValue == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedValue == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
    
    final savedAccent = prefs.getInt(_accentKey);
    if (savedAccent != null) {
      _accentColor = Color(savedAccent);
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      _themeMode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val;
    switch (mode) {
      case ThemeMode.light:
        val = 'light';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
      default:
        val = 'dark';
    }
    await prefs.setString(_prefKey, val);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences doesn't have setInt for Color value directly, we use .value for ARGB
    // Using value or (color.a << 24 | color.r << 16 | color.g << 8 | color.b) 
    // In newer flutter, color.value is deprecated in favor of color.toARGB32() but let's use color.value as it's common for older sdks
    // But since flutter 3.11, toARGB32 or a/r/g/b is preferred. Since we don't know exact version, we'll use value (int).
    await prefs.setInt(_accentKey, color.value);
  }
}
