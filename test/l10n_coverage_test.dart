import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestimou_mobile/presentation/l10n/l10n.dart';
import 'package:gestimou_mobile/presentation/l10n/translations_ar.dart';
import 'package:gestimou_mobile/presentation/l10n/translations_en.dart';

/// Returns the raw content of the single-line string literal starting at
/// [start] (which must be a quote), and the index just after it.
({String raw, int end})? _readLiteral(String s, int start) {
  final quote = s[start];
  var i = start + 1;
  while (i < s.length && s[i] != quote) {
    if (s[i] == '\n') return null;
    if (s[i] == r'\') i++;
    i++;
  }
  if (i >= s.length) return null;
  return (raw: s.substring(start + 1, i), end: i + 1);
}

String _unescape(String raw) => raw
    .replaceAllMapped(RegExp(r'''\\(['"$\\])'''), (m) => m[1]!)
    .replaceAll(r'\n', '\n');

bool _followedByTr(String s, int from) {
  final rest = s.substring(from, (from + 40).clamp(0, s.length)).trimLeft();
  return (rest.startsWith('.tr') && !RegExp(r'^\.tr[A-Za-z]').hasMatch(rest)) ||
      rest.startsWith('.trp(');
}

/// Every French string passed through `.tr` / `.trp(` in lib/, including the
/// literals of `(cond ? 'a' : 'b').tr` groups.
Set<String> _usedKeys() {
  final keys = <String>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('translations_') && !f.path.endsWith('l10n.dart'));

  for (final file in files) {
    final s = file.readAsStringSync();
    for (var i = 0; i < s.length; i++) {
      if (s.startsWith('//', i)) {
        while (i < s.length && s[i] != '\n') {
          i++;
        }
        continue;
      }
      final c = s[i];
      if (c == "'" || c == '"') {
        final lit = _readLiteral(s, i);
        if (lit == null) continue;
        if (_followedByTr(s, lit.end)) keys.add(_unescape(lit.raw));
        i = lit.end - 1;
      } else if (c == ')' && _followedByTr(s, i + 1)) {
        // literals inside the parenthesised expression
        var depth = 0;
        var k = i;
        for (; k >= 0; k--) {
          if (s[k] == ')') depth++;
          if (s[k] == '(') {
            depth--;
            if (depth == 0) break;
          }
        }
        final inner = s.substring(k + 1, i);
        for (var p = 0; p < inner.length; p++) {
          if (inner[p] == "'" || inner[p] == '"') {
            final lit = _readLiteral(inner, p);
            if (lit == null) break;
            final text = _unescape(lit.raw);
            if (RegExp(r'[A-Za-zÀ-ÿ{]').hasMatch(text) &&
                !RegExp(r'^[A-Z_]+$').hasMatch(text)) {
              keys.add(text);
            }
            p = lit.end - 1;
          }
        }
      }
    }
  }
  // Dart code such as replaceAll('Exception: ', '').tr isn't a UI string.
  keys.remove('Exception: ');
  return keys;
}

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

void main() {
  test('every UI string passed through .tr has an English and an Arabic translation', () {
    final used = _usedKeys();
    expect(used, isNotEmpty);

    final missingEn = used.where((k) => !kTranslationsEn.containsKey(k)).toList()..sort();
    final missingAr = used.where((k) => !kTranslationsAr.containsKey(k)).toList()..sort();
    expect(missingEn, isEmpty, reason: 'Missing English translations: $missingEn');
    expect(missingAr, isEmpty, reason: 'Missing Arabic translations: $missingAr');
  });

  test('translations keep the {placeholders} of the French source', () {
    final broken = <String>[];
    for (final fr in kTranslationsEn.keys) {
      if (_placeholders(fr).difference(_placeholders(kTranslationsEn[fr]!)).isNotEmpty ||
          _placeholders(kTranslationsEn[fr]!).difference(_placeholders(fr)).isNotEmpty) {
        broken.add('EN: $fr');
      }
      final ar = kTranslationsAr[fr];
      if (ar != null &&
          (_placeholders(fr).difference(_placeholders(ar)).isNotEmpty ||
              _placeholders(ar).difference(_placeholders(fr)).isNotEmpty)) {
        broken.add('AR: $fr');
      }
    }
    expect(broken, isEmpty);
    expect(kTranslationsAr.keys.toSet(), kTranslationsEn.keys.toSet(),
        reason: 'EN and AR dictionaries must cover the same keys');
  });

  group('tr / trp', () {
    tearDown(() => L10n.current = AppLang.fr);

    test('French is the identity', () {
      L10n.current = AppLang.fr;
      expect('Accueil'.tr, 'Accueil');
      expect('Bienvenue {name}'.trp({'name': 'Amel'}), 'Bienvenue {name}'.replaceAll('{name}', 'Amel'));
    });

    test('English and Arabic translate and fill placeholders', () {
      L10n.current = AppLang.en;
      expect('Accueil'.tr, 'Home');
      expect('{count} sur {max} membres'.trp({'count': 2, 'max': 4}), '2 of 4 members');

      L10n.current = AppLang.ar;
      expect('Accueil'.tr, 'الرئيسية');
      expect('{count} sur {max} membres'.trp({'count': 2, 'max': 4}), contains('2'));
    });

    test('an unknown string falls back to French', () {
      L10n.current = AppLang.ar;
      expect('Texte inconnu du dictionnaire'.tr, 'Texte inconnu du dictionnaire');
    });
  });

  testWidgets('Arabic switches the text direction to right-to-left', (tester) async {
    TextDirection? direction;
    await tester.pumpWidget(MaterialApp(
      locale: AppLang.ar.locale,
      supportedLocales: AppLang.values.map((l) => l.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        direction = Directionality.of(context);
        return const SizedBox();
      }),
    ));
    expect(direction, TextDirection.rtl);
  });
}
