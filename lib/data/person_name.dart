/// Mise en forme d'un nom de personne.
///
/// Les comptes sont crees a la main par la gestion : selon qui saisit, on
/// recoit « amel », « AMEL » ou « Amel Benelhadj ». L'app affiche toujours la
/// meme chose, quelle que soit la frappe.
///
/// Les particules restent en minuscules et les traits d'union comptent comme
/// des separateurs : « jean-pierre de la tour » devient « Jean-Pierre de la
/// Tour ».
class PersonName {
  PersonName._();

  static const _particules = {
    'de', 'du', 'des', 'da', 'del', 'della', 'di', 'la', 'le', 'van', 'von',
    'bin', 'ben', 'el', 'al',
  };

  /// Nom complet mis en forme.
  static String format(Object? raw) {
    final valeur = (raw ?? '').toString().trim();
    if (valeur.isEmpty) return '';

    final mots = valeur.split(RegExp(r'\s+'));
    final sortie = <String>[];
    for (var i = 0; i < mots.length; i++) {
      final mot = mots[i];
      final bas = mot.toLowerCase();
      // Une particule garde sa minuscule, sauf en tete de nom.
      if (i > 0 && _particules.contains(bas)) {
        sortie.add(bas);
        continue;
      }
      sortie.add(_capitaliserComposes(bas));
    }
    return sortie.join(' ');
  }

  /// Premier mot du nom, mis en forme. Sert aux salutations.
  static String firstName(Object? raw) {
    final complet = format(raw);
    if (complet.isEmpty) return '';
    return complet.split(' ').first;
  }

  /// Majuscule apres chaque trait d'union ou apostrophe.
  static String _capitaliserComposes(String mot) {
    final tampon = StringBuffer();
    var debutDeMot = true;
    for (final caractere in mot.split('')) {
      if (debutDeMot && RegExp(r'[a-zà-öø-ÿ]').hasMatch(caractere)) {
        tampon.write(caractere.toUpperCase());
        debutDeMot = false;
      } else {
        tampon.write(caractere);
        if (caractere == '-' || caractere == "'" || caractere == '’') {
          debutDeMot = true;
        }
      }
    }
    return tampon.toString();
  }
}
