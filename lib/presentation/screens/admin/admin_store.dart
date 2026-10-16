import 'package:flutter/foundation.dart';

import '../../../data/api_service.dart';
import '../../theme/ticket_status.dart';

/// Option d'intervenant : valeur envoyee au serveur, nom et precision.
class AssigneeOption {
  /// `sub:<id>` pour un sous-traitant, `staff:<nom>` pour l'equipe.
  final String value;
  final String name;
  final String detail;
  final bool subcontractor;
  const AssigneeOption(this.value, this.name, this.detail,
      {this.subcontractor = false});
}

/// Donnees partagees par tout l'espace d'administration.
///
/// L'accueil, la liste des tickets et les fiches de residence lisent la meme
/// liste : un ticket traite depuis l'une disparait des « a traiter » de
/// toutes, et les compteurs de la barre de navigation disent la meme chose
/// que les ecrans.
class AdminStore extends ChangeNotifier {
  AdminStore({this.role = ''});

  final ApiService _api = ApiService();
  final String role;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> tickets = const [];
  List<Map<String, dynamic>> residences = const [];
  Map<String, dynamic> dashboard = const {};

  List<Map<String, dynamic>>? _residents;
  List<AssigneeOption>? _assignees;

  bool get canAssign =>
      role == 'ADMIN' || role == 'MANAGER' || role == 'RESPONSABLE_ZONE';
  bool get canReject => role == 'ADMIN' || role == 'RESPONSABLE_ZONE';
  bool get canTerminate => canReject;
  bool get isAdmin => role == 'ADMIN';

  /// Statuts que ce role peut poser sur un ticket.
  List<TicketStage> get allowedStages => canTerminate
      ? const [
          TicketStage.open,
          TicketStage.inProgress,
          TicketStage.sav,
          TicketStage.done,
        ]
      : const [TicketStage.open, TicketStage.inProgress, TicketStage.sav];

  static List<Map<String, dynamic>> _maps(List<dynamic> raw) =>
      raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  Future<void> load() async {
    error = null;
    final results = await Future.wait<Object?>([
      _api.getTickets().then<Object?>((v) => v).catchError((Object e) => e),
      _api.getResidences().then<Object?>((v) => v).catchError((Object e) => e),
      _api.getDashboard().then<Object?>((v) => v).catchError((Object e) => e),
    ]);
    final t = results[0];
    if (t is List) {
      tickets = _maps(t)
        ..sort((a, b) => (b['createdAt'] ?? '')
            .toString()
            .compareTo((a['createdAt'] ?? '').toString()));
    } else {
      error = t.toString().replaceFirst('Exception: ', '');
    }
    final r = results[1];
    if (r is List) {
      residences = _maps(r)
        ..sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
    }
    final d = results[2];
    if (d is Map<String, dynamic>) dashboard = d;
    loading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> residents({bool refresh = false}) async {
    if (_residents != null && !refresh) return _residents!;
    _residents = _maps(await _api.getResidents());
    return _residents!;
  }

  // ─── Lectures ─────────────────────────────────────────────

  Iterable<Map<String, dynamic>> where(bool Function(Map t) test) =>
      tickets.where(test);

  int count(bool Function(Map t) test) => tickets.where(test).length;

  List<Map<String, dynamic>> ticketsOf(String residenceId) =>
      tickets.where((t) => TicketFields.residenceId(t) == residenceId).toList();

  Map<String, dynamic>? residence(String id) {
    for (final r in residences) {
      if ((r['id'] ?? '').toString() == id) return r;
    }
    return null;
  }

  /// Nom de residence d'un ticket : le ticket le porte rarement, la liste
  /// des residences le connait.
  String residenceNameOf(Map t) {
    final direct = TicketFields.residenceName(t);
    if (direct.isNotEmpty) return direct;
    final r = residence(TicketFields.residenceId(t));
    return (r?['name'] ?? '').toString();
  }

  /// Tickets qui attendent une decision : nouveaux et sans intervenant, ou
  /// urgents et pas encore termines. Les plus urgents, puis les plus
  /// anciens, en tete : c'est l'ordre dans lequel on les traite.
  List<Map<String, dynamic>> get needsAction {
    final list = tickets.where((t) {
      final stage = ticketStage(t['status']);
      if (!stage.isActive) return false;
      final urgent = ticketPriority(t['priority']) == TicketPriority.urgent;
      return (stage == TicketStage.open && TicketFields.assignee(t).isEmpty) ||
          urgent;
    }).toList()
      ..sort((a, b) {
        final p = ticketPriority(a['priority'])
            .rank
            .compareTo(ticketPriority(b['priority']).rank);
        if (p != 0) return p;
        return (a['createdAt'] ?? '')
            .toString()
            .compareTo((b['createdAt'] ?? '').toString());
      });
    return list;
  }

  // ─── Ecritures ────────────────────────────────────────────

  /// Remplace un ticket par sa version a jour, partout ou il s'affiche.
  void merge(Map<String, dynamic> updated) {
    final id = TicketFields.id(updated);
    if (id.isEmpty) return;
    var found = false;
    tickets = [
      for (final t in tickets)
        if (TicketFields.id(t) == id)
          (() {
            found = true;
            return {...t, ...updated};
          })()
        else
          t,
    ];
    if (!found) tickets = [updated, ...tickets];
    notifyListeners();
  }

  /// [local] complete la reponse pour l'affichage : le serveur ne renvoie
  /// pas toujours l'objet sous-traitant qu'on vient de designer.
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload,
      {Map<String, dynamic> local = const {}}) async {
    final updated = await _api.updateTicket(id, payload);
    final merged = <String, dynamic>{'id': id, ...payload, ...local};
    updated.forEach((k, v) {
      if (v != null || !merged.containsKey(k)) merged[k] = v;
    });
    merge(merged);
    return merged;
  }

  Future<String> chargeStatus(String email) =>
      _api.getClientChargeStatus(email);

  /// Intervenants proposables : sous-traitants, responsables de zone,
  /// managers securite et equipe interne. Charge une fois par session.
  Future<List<AssigneeOption>> assignees() async {
    if (_assignees != null) return _assignees!;
    final results = await Future.wait([
      _api.getSubcontractors().catchError((_) => <dynamic>[]),
      _api.getUsersByRole('RESPONSABLE_ZONE').catchError((_) => <dynamic>[]),
      _api.getUsersByRole('MANAGER').catchError((_) => <dynamic>[]),
      _api.getUsersByRole('INTERVENANT').catchError((_) => <dynamic>[]),
    ]);
    final options = <AssigneeOption>[];
    for (final s in results[0].whereType<Map>()) {
      final id = (s['id'] ?? '').toString();
      final name = (s['name'] ?? '').toString();
      if (id.isEmpty || name.isEmpty) continue;
      options.add(AssigneeOption(
          'sub:$id', name, (s['specialty'] ?? 'Sous-traitant').toString(),
          subcontractor: true));
    }
    for (final u in results[1].whereType<Map>()) {
      final name = (u['name'] ?? '').toString();
      if (name.isEmpty) continue;
      final zone = (u['zone'] ?? '').toString().trim();
      final label = zone.isEmpty
          ? 'Responsable de zone'
          : 'Responsable ${zone.toUpperCase() == 'ALL' ? 'toutes les zones' : zone}';
      options.add(AssigneeOption('staff:$name', name, label));
    }
    for (final u in results[2].whereType<Map>()) {
      final prof = (u['profession'] ?? '').toString();
      final lower = prof.toLowerCase();
      if (!lower.contains('sécur') && !lower.contains('secur')) continue;
      final name = (u['name'] ?? '').toString();
      if (name.isEmpty) continue;
      options.add(AssigneeOption('staff:$name', name, prof));
    }
    for (final u in results[3].whereType<Map>()) {
      final name = (u['name'] ?? '').toString();
      if (name.isEmpty) continue;
      final prof = (u['profession'] ?? '').toString();
      options.add(AssigneeOption(
          'staff:$name', name, prof.isEmpty ? 'Intervenant' : prof));
    }
    _assignees = options;
    return options;
  }

  /// Valeur d'intervenant actuelle d'un ticket, au format des options.
  static String assigneeValue(Map t) {
    final sub = t['subcontractor'];
    final subId = sub is Map ? (sub['id'] ?? '').toString() : '';
    if (subId.isNotEmpty) return 'sub:$subId';
    final subRaw = (t['subcontractorId'] ?? '').toString();
    if (subRaw.isNotEmpty) return 'sub:$subRaw';
    final name = (t['assignee'] ?? '').toString();
    return name.isEmpty ? '' : 'staff:$name';
  }
}
