import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define keys for storing settings
const String _languagePrefKey = 'app_language';
const String _fontSizeFactorPrefKey = 'font_size_factor';

// Default values
const String _defaultLanguage = 'en'; // Default to English
const double _defaultFontSizeFactor = 1.0; // Default font size factor

// Settings Model (Immutable)
@immutable
class AppSettings {
  final String languageCode; // 'en', 'pl', 'ko'
  final double fontSizeFactor; // e.g., 0.8, 1.0, 1.2

  const AppSettings({
    required this.languageCode,
    required this.fontSizeFactor,
  });

  AppSettings copyWith({
    String? languageCode,
    double? fontSizeFactor,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
    );
  }
}

// StateNotifier for managing settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings(languageCode: _defaultLanguage, fontSizeFactor: _defaultFontSizeFactor)) {
    _loadSettings();
  }

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSettings() async {
    await _initPrefs();
    final language = _prefs?.getString(_languagePrefKey) ?? _defaultLanguage;
    final fontSize = _prefs?.getDouble(_fontSizeFactorPrefKey) ?? _defaultFontSizeFactor;
    state = AppSettings(languageCode: language, fontSizeFactor: fontSize);
    print("Settings loaded: Language=$language, FontSizeFactor=$fontSize"); // Debug print
  }

  Future<void> setLanguage(String languageCode) async {
    if (!['en', 'pl', 'ko'].contains(languageCode)) return; // Validate
    await _initPrefs();
    await _prefs?.setString(_languagePrefKey, languageCode);
    state = state.copyWith(languageCode: languageCode);
     print("Settings saved: Language=$languageCode"); // Debug print
  }

  Future<void> setFontSizeFactor(double factor) async {
    // Clamp the factor to a reasonable range (e.g., 0.8 to 1.5)
     final clampedFactor = factor.clamp(0.8, 1.5);
    await _initPrefs();
    await _prefs?.setDouble(_fontSizeFactorPrefKey, clampedFactor);
    state = state.copyWith(fontSizeFactor: clampedFactor);
    print("Settings saved: FontSizeFactor=$clampedFactor"); // Debug print
  }
}

// Provider definition
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

// Selector for font size factor (optional, for convenience)
final fontSizeFactorProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).fontSizeFactor;
});

// Selector for language code (optional, for convenience)
final languageCodeProvider = Provider<String>((ref) {
   return ref.watch(settingsProvider).languageCode;
}); 