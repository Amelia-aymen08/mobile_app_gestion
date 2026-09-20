import '../../l10n/app_localizations.dart';

/// Commodites d'une residence.
///
/// Le back-end enregistre des cles de catalogue dans `Residence.amenities`,
/// les memes que le site Aymen Promotion. Tout ce qui n'est pas une cle
/// connue est affiche tel quel : mieux vaut un libelle brut qu'une commodite
/// silencieusement perdue.
String amenityLabel(AppL10n t, String key) => switch (key.trim()) {
      'climatisation' => t.amenity_climatisation,
      'reception' => t.amenity_reception,
      'bache_eau' => t.amenity_bache_eau,
      'ascenseur' => t.amenity_ascenseur,
      'cuisine' => t.amenity_cuisine,
      'groupe_electrogene' => t.amenity_groupe_electrogene,
      'parking' => t.amenity_parking,
      'domotique' => t.amenity_domotique,
      'dressing' => t.amenity_dressing,
      'isolation_phonique' => t.amenity_isolation_phonique,
      'aire_jeux' => t.amenity_aire_jeux,
      'piscine_commune' => t.amenity_piscine_commune,
      'piscine_privative' => t.amenity_piscine_privative,
      'fenetre' => t.amenity_fenetre,
      'salle_eau' => t.amenity_salle_eau,
      'salle_sport' => t.amenity_salle_sport,
      'spa' => t.amenity_spa,
      'gestion_copropriete' => t.amenity_gestion_copropriete,
      'creche' => t.amenity_creche,
      _ => key.trim(),
    };

/// Cles reconnues, dans l'ordre d'affichage du site.
const kAmenityKeys = <String>[
  'climatisation',
  'reception',
  'bache_eau',
  'ascenseur',
  'cuisine',
  'groupe_electrogene',
  'parking',
  'domotique',
  'dressing',
  'isolation_phonique',
  'aire_jeux',
  'piscine_commune',
  'piscine_privative',
  'fenetre',
  'salle_eau',
  'salle_sport',
  'spa',
  'gestion_copropriete',
  'creche',
];
