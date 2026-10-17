import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';

class AppPreferences {
  AppPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const _kThemeMode = 'themeMode';
  static const _kWebColorTheme = 'webColorTheme';
  static const _kLocale = 'locale';
  static const _kCurrency = 'currency';

  ThemeMode get themeMode {
    final v = _prefs.getString(_kThemeMode);
    return ThemeMode.values
        .firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  AppColorTheme get webColorTheme {
    final v = _prefs.getString(_kWebColorTheme);
    return AppColorTheme.values
        .firstWhere((t) => t.name == v, orElse: () => AppColorTheme.deepBlue);
  }

  Future<void> setWebColorTheme(AppColorTheme theme) =>
      _prefs.setString(_kWebColorTheme, theme.name);

  Locale get locale {
    final v = _prefs.getString(_kLocale) ?? 'ar';
    return Locale(v);
  }

  Future<void> setLocale(Locale locale) =>
      _prefs.setString(_kLocale, locale.languageCode);

  AppCurrency get currency {
    final v = _prefs.getString(_kCurrency);
    return AppCurrency.fromCode(v ?? 'IQD');
  }

  Future<void> setCurrency(AppCurrency currency) =>
      _prefs.setString(_kCurrency, currency.code);
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);
  final AppPreferences _prefs;
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

class WebColorThemeNotifier extends StateNotifier<AppColorTheme> {
  WebColorThemeNotifier(this._prefs) : super(_prefs.webColorTheme);
  final AppPreferences _prefs;
  Future<void> set(AppColorTheme theme) async {
    state = theme;
    await _prefs.setWebColorTheme(theme);
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_prefs.locale);
  final AppPreferences _prefs;
  Future<void> set(Locale locale) async {
    state = locale;
    await _prefs.setLocale(locale);
  }
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier(this._prefs) : super(_prefs.currency);
  final AppPreferences _prefs;
  Future<void> set(AppCurrency currency) async {
    state = currency;
    await _prefs.setCurrency(currency);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier(ref.watch(appPreferencesProvider)));
final webColorThemeProvider =
    StateNotifierProvider<WebColorThemeNotifier, AppColorTheme>(
        (ref) => WebColorThemeNotifier(ref.watch(appPreferencesProvider)));
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
    (ref) => LocaleNotifier(ref.watch(appPreferencesProvider)));
final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>(
    (ref) => CurrencyNotifier(ref.watch(appPreferencesProvider)));
