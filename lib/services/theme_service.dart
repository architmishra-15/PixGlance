import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeService._internal();

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs.getInt(AppConstants.themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(AppConstants.themeKey, mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      highlightElevation: 8,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      elevation: 4,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      highlightElevation: 8,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      elevation: 4,
    ),
  );
}