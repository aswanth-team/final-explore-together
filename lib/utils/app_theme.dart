import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final Color loginButtonColor;
  final Color homeBgColor;
  final Color appBarColor;
  final Color textColor;

  AppTheme({
    required this.loginButtonColor,
    required this.homeBgColor,
    required this.appBarColor,
    required this.textColor,
  });
}

// Light and Dark Theme Definitions
final AppTheme lightTheme = AppTheme(
  loginButtonColor: Colors.blue,
  homeBgColor: Colors.white,
  appBarColor: Colors.lightBlue,
  textColor: Colors.black,
);

final AppTheme darkTheme = AppTheme(
  loginButtonColor: Colors.deepPurple,
  homeBgColor: Colors.black,
  appBarColor: Colors.deepPurpleAccent,
  textColor: Colors.white,
);

// Enum for theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeManager extends ChangeNotifier {
  AppThemeMode _appThemeMode = AppThemeMode.system;
  Brightness _platformBrightness =
      PlatformDispatcher.instance.platformBrightness;

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode {
    if (_appThemeMode == AppThemeMode.light) return ThemeMode.light;
    if (_appThemeMode == AppThemeMode.dark) return ThemeMode.dark;
    return ThemeMode.system;
  }

  AppTheme get currentTheme {
    if (_appThemeMode == AppThemeMode.light) {
      return lightTheme;
    } else if (_appThemeMode == AppThemeMode.dark) {
      return darkTheme;
    } else {
      return _platformBrightness == Brightness.light ? lightTheme : darkTheme;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _appThemeMode = mode;
    notifyListeners();
    await _saveThemeMode(mode); // Save the theme locally
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('appThemeMode');
    if (savedTheme != null) {
      _appThemeMode =
          AppThemeMode.values.firstWhere((e) => e.toString() == savedTheme);
    }
    // Listen for system theme changes
    PlatformDispatcher.instance.onPlatformBrightnessChanged =
        _onPlatformBrightnessChanged;
    notifyListeners();
  }

  // Update theme when platform brightness changes
  void _onPlatformBrightnessChanged() {
    final newBrightness = PlatformDispatcher.instance.platformBrightness;
    if (_appThemeMode == AppThemeMode.system &&
        newBrightness != _platformBrightness) {
      _platformBrightness = newBrightness;
      notifyListeners();
    }
  }

  Future<void> _saveThemeMode(AppThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('appThemeMode', mode.toString());
  }
}
