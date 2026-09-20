import 'package:intl/intl.dart';

/// Calcul des charges, en un seul endroit.
///
/// L'accueil et l'ecran des paiements affichaient deux chiffres differents
/// pour la meme chose : l'accueil montrait le montant annuel renvoye par le
/// resume, l'ecran des paiements la somme des charges impayees. Les deux
/// etaient justes separement, et le rapprochement etait impossible a faire
/// pour le resident.
///
/// Tout ce qui touche a un montant passe donc par ces fonctions.
class Charges {
  Charges._();

  /// Nombre de mois couverts par une charge. Le serveur donne un montant
  /// mensuel et une periode ; une charge trimestrielle vaut trois fois son
  /// montant de base.
  static int periodMonths(Map charge) {
    final start = DateTime.tryParse((charge['periodStart'] ?? '').toString());
    final end = DateTime.tryParse((charge['periodEnd'] ?? '').toString());
    if (start == null || end == null) return 1;
    return ((end.year - start.year) * 12 + (end.month - start.month))
        .clamp(1, 120);
  }

  /// Montant reel d'une charge.
  static int amount(Map charge) {
    final base = int.tryParse((charge['amount'] ?? '0').toString()) ?? 0;
    final months =
        (charge['type'] ?? '').toString() == 'Charge' ? periodMonths(charge) : 1;
    return base * months;
  }

  /// Une charge est reglee quand le serveur le dit. Il ecrit « Payé » avec
  /// son accent ; la comparaison ignore accent et casse pour ne pas dependre
  /// de cette graphie.
  static bool isPaid(Map charge) {
    final status = (charge['status'] ?? '').toString().trim().toLowerCase();
    return status == 'payé' || status == 'paye' || status == 'paid';
  }

  /// Charges restant a regler, de la plus ancienne a la plus recente.
  static List<Map<String, dynamic>> due(List<dynamic> charges) {
    final list = charges
        .whereType<Map>()
        .where((c) => !isPaid(c))
        .map((c) => Map<String, dynamic>.from(c))
        .toList()
      ..sort((a, b) => (a['periodEnd'] ?? '')
          .toString()
          .compareTo((b['periodEnd'] ?? '').toString()));
    return list;
  }

  /// Charges deja reglees, de la plus recente a la plus ancienne.
  static List<Map<String, dynamic>> paid(List<dynamic> charges) {
    final list = charges
        .whereType<Map>()
        .where(isPaid)
        .map((c) => Map<String, dynamic>.from(c))
        .toList()
      ..sort((a, b) => (b['periodEnd'] ?? '')
          .toString()
          .compareTo((a['periodEnd'] ?? '').toString()));
    return list;
  }

  /// Somme restant a regler.
  static int totalDue(List<dynamic> charges) =>
      due(charges).fold<int>(0, (sum, c) => sum + amount(c));

  /// Echeance la plus proche parmi les charges impayees. A defaut, la date
  /// annoncee par le resume du serveur.
  static DateTime? nextDueDate(List<dynamic> charges, Map summary) {
    for (final charge in due(charges)) {
      final end = DateTime.tryParse((charge['periodEnd'] ?? '').toString());
      if (end != null) return end.toLocal();
    }
    return DateTime.tryParse((summary['nextPaymentDate'] ?? '').toString())
        ?.toLocal();
  }

  /// Prochain paiement annonce par le serveur. A defaut, le montant de la
  /// premiere charge impayee.
  static int nextPayment(List<dynamic> charges, Map summary) {
    final announced = int.tryParse((summary['annualAmount'] ?? '').toString());
    if (announced != null && announced > 0) return announced;
    final list = due(charges);
    return list.isEmpty ? 0 : amount(list.first);
  }

  static String format(int value) =>
      '${NumberFormat.decimalPattern('fr_FR').format(value)} DZD';
}
