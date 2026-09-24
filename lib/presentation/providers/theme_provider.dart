import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  /// Le sombre est le theme par defaut : c'est dans cette teinte que la
  /// marque se tient, et l'app s'ouvre souvent le soir. Le resident garde
  /// la main dessus depuis les reglages, et son choix est retenu.
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    // Tant que rien n'a ete choisi, on reste sur le sombre. Seul un choix
    // explicite « clair » bascule.
    final saved = prefs.getString(_prefsKey);
    _mode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setDark(!isDark);
}
