import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'interface. Le francais reste la langue par defaut : c'est
/// celle que lisent les residents. L'arabe bascule l'app en RTL, Flutter
/// s'en charge via le `Directionality` pose par MaterialApp.
class LocaleProvider with ChangeNotifier {
  static const _prefsKey = 'app_locale';
  static const fallback = Locale('fr');

  Locale _locale = fallback;

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
