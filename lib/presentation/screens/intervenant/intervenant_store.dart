import 'package:flutter/foundation.dart';

import '../../../data/api_service.dart';
import '../../theme/ticket_status.dart';

/// Les missions de l'intervenant, partagees par ses trois onglets et la
/// fiche d'une mission.
///
/// Le serveur ne renvoie que les tickets qui lui sont confies. On les range
/// en trois piles, dans l'ordre ou il les traite : celle qu'il a en main,
/// celles qui attendent qu'il commence, celles qu'il a terminees.
class IntervenantStore extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _tickets = const [];
  bool loading = true;
  String? error;

  /// Missions en train de changer de statut : leur bouton tourne et ne
  /// repond plus a un second appui.
  final Set<String> busy = {};

  List<Map<String, dynamic>> get tickets => _tickets;

  Future<void> load() async {
    try {
      final raw = await _api.getTickets();
      _tickets = raw
          .whereType<Map>()
          .map((t) => Map<String, dynamic>.from(t))
          .toList();
      error = null;
    } catch (e) {
      error = _clean(e);
    }
    loading = false;
    notifyListeners();
  }

  static TicketStage stageOf(Map t) => ticketStage(t['status']);

  /// L'urgent d'abord, puis le plus ancien : celui qui attend depuis le plus
  /// longtemps passe avant le dernier arrive.
  static int _byUrgency(Map a, Map b) {
    final p = ticketPriority(a['priority'])
        .rank
        .compareTo(ticketPriority(b['priority']).rank);
    if (p != 0) return p;
    return (a['createdAt'] ?? '')
        .toString()
        .compareTo((b['createdAt'] ?? '').toString());
  }

  List<Map<String, dynamic>> _where(bool Function(TicketStage) test) =>
      _tickets.where((t) => test(stageOf(t))).toList();

  /// Ce qu'il a commence : en cours ou repris en SAV.
  List<Map<String, dynamic>> get current => _where(
      (s) => s == TicketStage.inProgress || s == TicketStage.sav)
    ..sort(_byUrgency);

  /// Ce qui l'attend : confie mais pas encore commence.
  List<Map<String, dynamic>> get toStart =>
      _where((s) => s == TicketStage.open)..sort(_byUrgency);

  /// Termine, le plus recent en tete.
  List<Map<String, dynamic>> get done => _where((s) => s == TicketStage.done)
    ..sort((a, b) => _updated(b).compareTo(_updated(a)));

  int get doneThisWeek {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return done.where((t) => _updated(t).isAfter(since)).length;
  }

  static DateTime _updated(Map t) =>
      DateTime.tryParse((t['updatedAt'] ?? t['createdAt'] ?? '').toString())
          ?.toLocal() ??
      DateTime(2000);

  /// Depuis quand la mission est en cours. La liste ne porte pas l'heure de
  /// demarrage : la derniere mise a jour en est la meilleure approche, la
  /// fiche lit l'heure exacte dans l'historique.
  static DateTime? startedAt(Map t) {
    final s = stageOf(t);
    if (s != TicketStage.inProgress && s != TicketStage.sav) return null;
    return _updated(t);
  }

  Map<String, dynamic>? byId(String id) {
    for (final t in _tickets) {
      if (TicketFields.id(t) == id) return t;
    }
    return null;
  }

  /// Demarre la mission. La carte change tout de suite ; si le serveur
  /// refuse, elle revient a son etat et l'erreur remonte.
  Future<Map<String, dynamic>> start(String id) =>
      _move(id, TicketStage.inProgress);

  /// Termine la mission : photos d'abord, pour qu'elles accompagnent le
  /// compte rendu, puis le statut.
  Future<Map<String, dynamic>> finish(String id,
      {String note = '', List<UploadFile> photos = const []}) async {
    if (photos.isNotEmpty) {
      busy.add(id);
      notifyListeners();
      try {
        final attachments =
            await _api.uploadTicketAttachments(ticketId: id, files: photos);
        _patch(id, {'attachments': attachments});
      } catch (e) {
        busy.remove(id);
        notifyListeners();
        rethrow;
      }
    }
    return _move(id, TicketStage.done, note: note);
  }

  /// Ajoute des photos sans changer le statut.
  Future<void> addPhotos(String id, List<UploadFile> photos) async {
    final attachments =
        await _api.uploadTicketAttachments(ticketId: id, files: photos);
    _patch(id, {'attachments': attachments});
    notifyListeners();
  }

  Future<Map<String, dynamic>> _move(String id, TicketStage to,
      {String note = ''}) async {
    final before = byId(id);
    final previous = before == null ? null : Map<String, dynamic>.from(before);
    busy.add(id);
    _patch(id, {
      'status': to.apiValue,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    notifyListeners();
    try {
      final saved = await _api.updateTicket(id, {
        'status': to.apiValue,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      });
      _patch(id, saved);
      return byId(id) ?? saved;
    } catch (e) {
      if (previous != null) _replace(id, previous);
      throw Exception(_clean(e));
    } finally {
      busy.remove(id);
      notifyListeners();
    }
  }

  void _patch(String id, Map<String, dynamic> values) {
    _tickets = [
      for (final t in _tickets)
        TicketFields.id(t) == id ? {...t, ...values} : t,
    ];
  }

  void _replace(String id, Map<String, dynamic> ticket) {
    _tickets = [
      for (final t in _tickets) TicketFields.id(t) == id ? ticket : t,
    ];
  }

  /// La fiche recharge le ticket complet : la liste en profite.
  void merge(Map<String, dynamic> fresh) {
    final id = TicketFields.id(fresh);
    if (id.isEmpty || byId(id) == null) return;
    _patch(id, fresh);
    notifyListeners();
  }

  static String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
