// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navNotice => 'Avis';

  @override
  String get navReport => 'Signaler';

  @override
  String get navPayment => 'Paiements';

  @override
  String get navMore => 'Plus';

  @override
  String greeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get myResidence => 'Ma résidence';

  @override
  String apartmentBadge(String unit) {
    return 'Apt. $unit';
  }

  @override
  String get floor => 'Étage';

  @override
  String get area => 'Surface';

  @override
  String get status => 'Statut';

  @override
  String get statusActive => 'Actif';

  @override
  String get nextPayment => 'Prochain paiement';

  @override
  String paymentDeadline(String date) {
    return 'Échéance : $date';
  }

  @override
  String get reports => 'Signalements';

  @override
  String reportsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ouverts',
      one: '1 ouvert',
      zero: 'Aucun ouvert',
    );
    return '$_temp0';
  }

  @override
  String reportsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours',
      one: '1 en cours',
    );
    return '$_temp0';
  }

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get notices => 'Avis';

  @override
  String get payments => 'Paiements';

  @override
  String get documents => 'Documents';

  @override
  String get profile => 'Profil';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get loginTitle => 'Bienvenue chez vous';

  @override
  String get loginSubtitle => 'Connectez-vous à votre résidence.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get emailHint => 'nom@exemple.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginCta => 'Se connecter';

  @override
  String get firstLoginQuestion => 'Première connexion ?';

  @override
  String get firstLoginHelp =>
      ' Utilisez les identifiants remis à la livraison des clés.';

  @override
  String get emailRequired => 'Adresse e-mail requise';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get noAccountQuestion =>
      'Vous êtes résident et n\'avez pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';
}
