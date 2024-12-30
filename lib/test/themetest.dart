import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeManager = ThemeManager();
  await themeManager.loadTheme(); // Load saved theme

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeManager,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      themeMode: themeManager.themeMode,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final appTheme = themeManager.currentTheme;

    return Scaffold(
      backgroundColor: appTheme.homeBgColor,
      appBar: AppBar(
        title: Text('Custom Theme Example'),
        backgroundColor: appTheme.appBarColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose a Theme:',
              style: TextStyle(color: appTheme.textColor),
            ),
            DropdownButton<AppThemeMode>(
              value: themeManager.appThemeMode,
              items: AppThemeMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.toString().split('.').last),
                );
              }).toList(),
              onChanged: (newMode) async {
                if (newMode != null) {
                  await themeManager
                      .setThemeMode(newMode); // Save theme locally
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.loginButtonColor,
              ),
              child: Text('Go to Sub Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<ThemeManager>(context).currentTheme;

    return Scaffold(
      backgroundColor: appTheme.homeBgColor,
      appBar: AppBar(
        title: Text('Sub Page'),
        backgroundColor: appTheme.appBarColor,
      ),
      body: Center(
        child: Text(
          'This is a sub-page.',
          style: TextStyle(color: appTheme.textColor),
        ),
      ),
    );
  }
}

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
