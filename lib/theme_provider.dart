import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeModeOption _themeModeOption = ThemeModeOption.system;

  ThemeProvider() {
    _loadPreferences();
  }

  ThemeModeOption get themeModeOption => _themeModeOption;

  ThemeMode get themeMode {
    switch (_themeModeOption) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _themeModeOption = ThemeModeOption.values[prefs.getInt('themeMode') ?? 0];
    notifyListeners();
  }

  void updateThemeMode(ThemeModeOption option) async {
    _themeModeOption = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', option.index);
    notifyListeners();
  }
}
