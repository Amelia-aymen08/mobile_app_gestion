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

  /// Langues proposees par l'app.
  static const supported = ['fr', 'en', 'ar'];

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) _locale = Locale(code);

    // AIDE AU TEST — a retirer avant la mise en production.
    // Sur le web, ?lang=ar ouvre directement l'app dans cette langue, pour
    // verifier la mise en page de droite a gauche sans passer par les
    // reglages. Le choix est memorise comme s'il avait ete fait a la main.
    final forced = Uri.base.queryParameters['lang'];
    if (forced != null && supported.contains(forced)) {
      _locale = Locale(forced);
      await prefs.setString(_prefsKey, forced);
    }
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
