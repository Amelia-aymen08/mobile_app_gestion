import 'package:flutter/material.dart';

/// Residence amenities ("commodités"). The backend stores catalogue keys in
/// Residence.amenities (same list as the Aymen Promotion website); anything
/// that isn't a known key is shown as free text.
class AmenityInfo {
  final String labelFr; // also the translation key (see l10n)
  final IconData icon;
  const AmenityInfo(this.labelFr, this.icon);
}

const Map<String, AmenityInfo> kAmenities = {
  'climatisation':
      AmenityInfo('Climatisation centralisée', Icons.ac_unit_rounded),
  'reception': AmenityInfo('Réception', Icons.room_service_outlined),
  'bache_eau': AmenityInfo('Bâche à eau', Icons.water_drop_outlined),
  'ascenseur': AmenityInfo('Ascenseur', Icons.elevator_outlined),
  'cuisine': AmenityInfo('Cuisine équipée', Icons.kitchen_outlined),
  'groupe_electrogene': AmenityInfo('Groupe électrogène', Icons.bolt_outlined),
  'parking':
      AmenityInfo('Parking de stationnement', Icons.local_parking_rounded),
  'domotique': AmenityInfo('Domotique', Icons.settings_remote_outlined),
  'dressing': AmenityInfo('Dressing', Icons.checkroom_outlined),
  'isolation_phonique':
      AmenityInfo('Isolation phonique', Icons.volume_off_outlined),
  'aire_jeux': AmenityInfo('Aire de jeux', Icons.toys_outlined),
  'piscine_commune': AmenityInfo('Piscine commune', Icons.pool_outlined),
  'piscine_privative': AmenityInfo('Piscine privative', Icons.pool_rounded),
  'fenetre': AmenityInfo('Fenêtres double vitrage', Icons.window_outlined),
  'salle_eau': AmenityInfo("Salle d'eau", Icons.bathtub_outlined),
  'salle_sport': AmenityInfo('Salle de sport', Icons.fitness_center_outlined),
  'spa': AmenityInfo('Spa / Hammam / Sauna', Icons.spa_outlined),
  'gestion_copropriete':
      AmenityInfo('Gestion copropriété', Icons.apartment_outlined),
  'creche': AmenityInfo('Crèche / Garderie', Icons.child_friendly_outlined),
};
