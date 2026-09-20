import 'package:flutter/material.dart';

/// Status colour shared by the resident ticket list and detail screens.
Color ticketStatusColor(String? status) {
  switch (status) {
    case 'Signalé':
      return const Color(0xFFF59E0B);
    case 'En cours':
      return const Color(0xFF3B82F6);
    case 'Terminé':
      return const Color(0xFF16A34A);
    case 'SAV':
      return const Color(0xFF8B5CF6);
    case 'Rejeté':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF94A3B8);
  }
}

/// Older tickets were saved with previous wording; show the current one.
String normalizeTicketTitle(String raw) {
  switch (raw) {
    case 'Peinture écaillée':
    case 'Peinture escaliers':
      return 'Peinture Escalier';
    default:
      return raw;
  }
}
