import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Key for storing theme preference
  static const String _themePreferenceKey = 'theme_mode';
  
  // Default theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Constructor - loads saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Load theme preference from shared preferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themePreferenceKey);
    
    if (savedThemeMode != null) {
      _themeMode = _getThemeModeFromString(savedThemeMode);
      notifyListeners();
    }
  }
  
  // Save theme preference to shared preferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, mode.toString());
  }
  
  // Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    await _saveThemePreference(mode);
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
  
  // Check if dark mode is enabled
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
