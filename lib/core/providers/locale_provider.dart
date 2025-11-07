import 'dart:async';
import 'dart:ui' as ui;
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

  /// Get system locale
  Locale _getSystemLocale() {
    final systemLocales = ui.PlatformDispatcher.instance.locales;
    if (systemLocales.isNotEmpty) {
      final systemLocale = systemLocales.first;
      print('🌍 [LOCALE] System locale detected: ${systemLocale.languageCode}');
      // Only support 'en' and 'zh', default to 'en' for others
      if (systemLocale.languageCode == 'zh') {
        return const Locale('zh', '');
      }
    }
    return const Locale('en', '');
  }

  /// Load locale asynchronously without blocking the constructor
  void _loadLocaleAsync() {
    Future.microtask(() async {
      await _loadLocale();
    });
  }

  /// Load saved locale from SharedPreferences, or use system locale for first-time users
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [LOCALE] SharedPreferences timed out after 10s, using system locale');
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      final languageCode = prefs.getString(_localeKey);

      if (languageCode != null) {
        // User has saved preference, use it
        print('🌍 [LOCALE] Loading saved locale: $languageCode');
        state = Locale(languageCode, '');
      } else {
        // First-time user, use system locale
        final systemLocale = _getSystemLocale();
        print('🌍 [LOCALE] First-time user, using system locale: ${systemLocale.languageCode}');
        state = systemLocale;
        // Save it for next time
        await prefs.setString(_localeKey, systemLocale.languageCode);
      }
    } catch (e) {
      print('❌ [LOCALE] Error loading locale: $e, using system locale');
      // On error, use system locale
      state = _getSystemLocale();
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
