import 'package:flutter/material.dart';

/// Icone d'une categorie de signalement.
///
/// Les categories viennent du serveur sous forme de libelles libres
/// ("Plomberie (Partie Commune)", "Problème Bâche à eau"...). On les
/// reconnait par mot-cle, accents et casse ignores, pour qu'un libelle
/// legerement reformule cote back-office garde son icone. L'ordre compte :
/// "Commande TAG d'accès" contient "acces", comme "Ascenseurs & Accès".
IconData ticketCategoryIcon(String category) {
  final s = _fold(category);
  bool has(String k) => s.contains(k);

  if (has('telecommande')) return Icons.settings_remote_rounded;
  if (has('tag') || has('badge')) return Icons.contactless_rounded;
  if (has('ascenseur')) return Icons.elevator_rounded;
  if (has('peinture')) return Icons.format_paint_rounded;
  if (has('plomberie')) return Icons.plumbing_rounded;
  if (has('bache') || has('eau')) return Icons.water_drop_rounded;
  if (has('electrogene') || has('electri')) return Icons.bolt_rounded;
  if (has('hygiene') || has('securite')) return Icons.health_and_safety_rounded;
  if (has('exterieur') || has('jardin') || has('vert')) {
    return Icons.park_rounded;
  }
  return Icons.more_horiz_rounded;
}

String _fold(String value) {
  const from = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = value.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}
