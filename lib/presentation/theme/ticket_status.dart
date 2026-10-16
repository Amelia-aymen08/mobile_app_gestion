import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Etapes d'un ticket, quelle que soit l'ecriture du serveur.
///
/// Le back-end a connu deux formes : « Signalé », « En cours »... ecrites par
/// l'ancienne administration, et « OUVERT », « EN_COURS »... renvoyees
/// depuis. Tout l'ecran d'administration passe par cette table : un ticket
/// ne change jamais de couleur selon la forme sous laquelle il est arrive.
enum TicketStage { open, inProgress, sav, done, rejected }

String _plain(String raw) {
  const accents = {'é': 'e', 'è': 'e', 'ê': 'e', 'É': 'E', 'È': 'E'};
  final buffer = StringBuffer();
  for (final ch in raw.split('')) {
    buffer.write(accents[ch] ?? ch);
  }
  return buffer.toString().toUpperCase().trim().replaceAll(' ', '_');
}

TicketStage ticketStage(Object? raw) {
  final s = _plain((raw ?? '').toString());
  if (s.startsWith('TERMIN') || s == 'RESOLU' || s.startsWith('CLOTUR')) {
    return TicketStage.done;
  }
  if (s == 'EN_COURS') return TicketStage.inProgress;
  if (s == 'SAV') return TicketStage.sav;
  if (s.startsWith('REJET')) return TicketStage.rejected;
  return TicketStage.open;
}

extension TicketStageX on TicketStage {
  String get label => switch (this) {
        TicketStage.open => 'Nouveau',
        TicketStage.inProgress => 'En cours',
        TicketStage.sav => 'SAV',
        TicketStage.done => 'Terminé',
        TicketStage.rejected => 'Rejeté',
      };

  /// Valeur envoyee au serveur, celle que l'administration a toujours
  /// ecrite.
  String get apiValue => switch (this) {
        TicketStage.open => 'Signalé',
        TicketStage.inProgress => 'En cours',
        TicketStage.sav => 'SAV',
        TicketStage.done => 'Terminé',
        TicketStage.rejected => 'Rejeté',
      };

  Color get color => switch (this) {
        TicketStage.open => FigBrand.amber,
        TicketStage.inProgress => FigAccent.blue,
        TicketStage.sav => FigAccent.purple,
        TicketStage.done => FigAlert.success,
        TicketStage.rejected => FigAlert.error,
      };

  IconData get icon => switch (this) {
        TicketStage.open => Icons.fiber_new_rounded,
        TicketStage.inProgress => Icons.autorenew_rounded,
        TicketStage.sav => Icons.handyman_rounded,
        TicketStage.done => Icons.check_circle_rounded,
        TicketStage.rejected => Icons.block_rounded,
      };

  /// Un ticket encore a traiter : ni termine, ni rejete.
  bool get isActive => this != TicketStage.done && this != TicketStage.rejected;
}

/// Priorites : le formulaire envoie « Haute », d'anciens tickets portent
/// « HAUTE » ou « Urgent ».
enum TicketPriority { low, medium, high, urgent }

TicketPriority ticketPriority(Object? raw) {
  final s = _plain((raw ?? '').toString());
  if (s.startsWith('URGENT')) return TicketPriority.urgent;
  if (s == 'HAUTE') return TicketPriority.high;
  if (s == 'BASSE') return TicketPriority.low;
  return TicketPriority.medium;
}

extension TicketPriorityX on TicketPriority {
  String get label => switch (this) {
        TicketPriority.low => 'Basse',
        TicketPriority.medium => 'Moyenne',
        TicketPriority.high => 'Haute',
        TicketPriority.urgent => 'Urgente',
      };

  Color get color => switch (this) {
        TicketPriority.low => FigNeutral.n40,
        TicketPriority.medium => FigAccent.blue,
        TicketPriority.high => FigBrand.amber,
        TicketPriority.urgent => FigAlert.error,
      };

  /// Rang de tri : l'urgent passe devant.
  int get rank => switch (this) {
        TicketPriority.urgent => 0,
        TicketPriority.high => 1,
        TicketPriority.medium => 2,
        TicketPriority.low => 3,
      };
}

/// Lecture des champs d'un ticket, tels que le serveur les renvoie.
abstract final class TicketFields {
  static String id(Map t) => (t['id'] ?? '').toString();

  static String title(Map t) {
    final raw = (t['title'] ?? '').toString().trim();
    return raw.isEmpty ? 'Ticket' : raw;
  }

  /// Reference courte, les six derniers caracteres de l'identifiant.
  static String ref(Map t) {
    final id = TicketFields.id(t);
    if (id.isEmpty) return '';
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return '#${tail.toUpperCase()}';
  }

  static String residenceId(Map t) {
    final direct = (t['residenceId'] ?? '').toString();
    if (direct.isNotEmpty) return direct;
    final r = t['residence'] ?? t['Residence'];
    return r is Map ? (r['id'] ?? '').toString() : '';
  }

  static String residenceName(Map t) {
    final r = t['residence'] ?? t['Residence'];
    if (r is Map && (r['name'] ?? '').toString().isNotEmpty) {
      return r['name'].toString();
    }
    return (t['residenceName'] ?? '').toString();
  }

  /// Intervenant retenu : sous-traitant d'abord, puis membre de l'equipe.
  static String assignee(Map t) {
    final sub = t['subcontractor'];
    if (sub is Map && (sub['name'] ?? '').toString().isNotEmpty) {
      return sub['name'].toString();
    }
    return (t['assignee'] ?? '').toString().trim();
  }

  static String requester(Map t) {
    final r = t['requester'];
    if (r is Map) return (r['name'] ?? r['fullName'] ?? '').toString();
    return (r ?? '').toString().trim();
  }

  static DateTime? created(Map t) =>
      DateTime.tryParse((t['createdAt'] ?? '').toString())?.toLocal();
}

/// « Il y a 3 h », « Il y a 2 j », puis la date.
String timeAgoLabel(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
