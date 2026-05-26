import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  AppThemeController._();

  static const _keyTheme = 'app_theme_mode';
  static const _keyTextScale = 'app_text_scale';

  static final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<TextScaler> textScalerNotifier =
      ValueNotifier(const TextScaler.linear(1.0));

  static double linearTextScale = 1.0;

  static String _themeToStorage(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        _ => 'light',
      };

  static ThemeMode themeModeFromStorage(String? value) => switch (value) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static String labelForThemeMode(ThemeMode mode) => _themeToStorage(mode);

  static ThemeMode themeModeFromLabel(String label) => themeModeFromStorage(label);

  static String labelForTextScale(double linear) {
    if (linear <= 0.95) return 'small';
    if (linear >= 1.08) return 'large';
    return 'default';
  }

  static double linearScaleFromLabel(String label) => switch (label) {
        'small' => 0.9,
        'large' => 1.15,
        _ => 1.0,
      };

  static Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    modeNotifier.value = themeModeFromStorage(prefs.getString(_keyTheme));
    final scale = (prefs.getDouble(_keyTextScale) ?? 1.0).clamp(0.85, 1.3).toDouble();
    linearTextScale = scale;
    textScalerNotifier.value = TextScaler.linear(scale);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, _themeToStorage(mode));
  }

  static Future<void> setTextLinearScale(double linear) async {
    final scale = linear.clamp(0.85, 1.3).toDouble();
    linearTextScale = scale;
    textScalerNotifier.value = TextScaler.linear(scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, scale);
  }

  static void toggleTheme() {
    final next =
        modeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  /// Apply theme + font 
  static Future<void> applyFromFirestorePrefs(Map<String, dynamic>? preferences) async {
    if (preferences == null) return;
    final themeLabel = preferences['themeMode'] as String?;
    if (themeLabel != null) {
      await setThemeMode(themeModeFromLabel(themeLabel));
    }
    final fontLabel = preferences['fontSize'] as String?;
    if (fontLabel != null) {
      await setTextLinearScale(linearScaleFromLabel(fontLabel));
    }
  }
}
