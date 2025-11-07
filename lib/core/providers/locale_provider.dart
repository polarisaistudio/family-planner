import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing locale state
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier for managing locale/language preferences
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';

  LocaleNotifier() : super(const Locale('en', '')) {
    print('🌍 [LOCALE] LocaleNotifier constructor called');
    // Load locale asynchronously without blocking
    _loadLocaleAsync();
    print('🌍 [LOCALE] LocaleNotifier initialized with default locale: en');
  }

  /// Load locale asynchronously without blocking the constructor
  void _loadLocaleAsync() {
    Future.microtask(() async {
      await _loadLocale();
    });
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [LOCALE] SharedPreferences timed out after 10s, using default locale');
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      final languageCode = prefs.getString(_localeKey);

      if (languageCode != null) {
        state = Locale(languageCode, '');
      }
    } catch (e) {
      print('❌ [LOCALE] Error loading locale: $e, using default (en)');
      // Keep default locale on error
    }
  }

  /// Change the app locale and persist it
  Future<void> setLocale(Locale locale) async {
    state = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Toggle between English and Chinese
  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? const Locale('zh', '')
        : const Locale('en', '');
    await setLocale(newLocale);
  }
}
