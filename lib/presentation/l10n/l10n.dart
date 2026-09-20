import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations_ar.dart';
import 'translations_en.dart';

/// Languages offered by the app. French is the source language of every UI
/// string, so it is also the fallback when a translation is missing.
enum AppLang { fr, en, ar }

extension AppLangX on AppLang {
  Locale get locale => Locale(name);
  bool get isRtl => this == AppLang.ar;

  /// Name of the language written in that language (shown in the picker).
  String get nativeName {
    switch (this) {
      case AppLang.fr:
        return 'Français';
      case AppLang.en:
        return 'English';
      case AppLang.ar:
        return 'العربية';
    }
  }

  String get shortLabel {
    switch (this) {
      case AppLang.fr:
        return 'FR';
      case AppLang.en:
        return 'EN';
      case AppLang.ar:
        return 'ع';
    }
  }
}

/// Holds the selected language and persists it. The whole app is rebuilt when
/// it changes (see main.dart), so strings can be resolved through the global
/// [L10n.current] without every widget depending on this provider.
class LocaleProvider with ChangeNotifier {
  static const prefsKey = 'app_lang';

  AppLang _lang = AppLang.fr;
  AppLang get lang => _lang;
  Locale get locale => _lang.locale;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey);
    _lang = AppLang.values.firstWhere(
      (l) => l.name == saved,
      orElse: () => AppLang.fr,
    );
    L10n.current = _lang;
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    if (lang == _lang) return;
    _lang = lang;
    L10n.current = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, lang.name);
  }
}

class L10n {
  L10n._();

  static AppLang current = AppLang.fr;

  static String tr(String fr) {
    switch (current) {
      case AppLang.fr:
        return fr;
      case AppLang.en:
        return kTranslationsEn[fr] ?? _missing(fr);
      case AppLang.ar:
        return kTranslationsAr[fr] ?? _missing(fr);
    }
  }

  static String _missing(String fr) {
    if (kDebugMode) debugPrint('[l10n] missing ${current.name} translation: "$fr"');
    return fr;
  }
}

extension TranslateX on String {
  /// Translates a French UI string to the current language.
  String get tr => L10n.tr(this);

  /// Same as [tr] for strings with `{placeholders}`:
  /// `'Bonjour {name}'.trp({'name': user})`.
  String trp(Map<String, Object?> params) {
    var out = L10n.tr(this);
    params.forEach((key, value) => out = out.replaceAll('{$key}', '${value ?? ''}'));
    return out;
  }
}
