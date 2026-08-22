import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'app_theme_mode';

  ThemeCubit(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final savedMode = prefs.getString(_themeKey);
    if (savedMode == 'dark') return ThemeMode.dark;
    if (savedMode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    _prefs.setString(_themeKey, mode.name);
    emit(mode);
  }

  void toggleTheme() {
    final currentMode = state == ThemeMode.system
        ? WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light
        : state;

    final newMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }
}
