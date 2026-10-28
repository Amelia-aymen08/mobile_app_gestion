import 'dart:convert';

import 'package:http/http.dart' as http;

String _ago({int h = 0, int m = 0, int d = 0}) => DateTime.now()
    .subtract(Duration(days: d, hours: h, minutes: m))
    .toUtc()
    .toIso8601String();

/// Faux serveur de l'espace intervenant : un electricien a qui
/// l'administration a confie une mission en cours, trois a commencer et
/// trois deja terminees. Il applique les changements de statut et garde
/// la trace des envois, pour que les tests verifient ce qui part au
/// serveur.
class DemoIntervenantClient extends http.BaseClient {
  /// Chaque `PUT /maintenance/:id` recu : identifiant et corps.
  final updates = <(String, Map)>[];

  /// Nombre de fichiers recus par `POST /maintenance/:id/attachments`.
  int uploadedFiles = 0;

  late final tickets = <Map<String, dynamic>>[
    _t('tk-c3d201', 'Interphone hors service', 'r-angelite', 'Angélite',
        'En cours', 'Moyenne', _ago(d: 1, h: 3),
        updated: _ago(h: 1, m: 20),
        location: 'Angélite · Bloc A — entrée',
        requester: 'Mehdi Messadi',
        description: "L'interphone du bloc A ne sonne plus depuis hier soir."),
    _t('tk-d0e962', 'Éclairage parking en panne', 'r-selenite', 'Sélénite',
        'Signalé', 'Urgente', _ago(h: 2),
        location: 'Sélénite · parking -1', requester: 'Karim Haddad'),
    _t('tk-a3b295', 'Prise du couloir qui chauffe', 'r-corail', 'Corail',
        'Signalé', 'Haute', _ago(h: 5),
        location: 'Corail · Bloc B, 2e étage', requester: 'Yacine Belkacem'),
    _t('tk-e7f310', 'Minuterie du hall trop courte', 'r-peridot', 'Péridot',
        'Signalé', 'Moyenne', _ago(d: 1, h: 6),
        location: 'Péridot · hall C', requester: 'Sarah Kaci'),
    _t('tk-a7b630', 'Ampoule grillée palier 3', 'r-angelite', 'Angélite',
        'Terminé', 'Basse', _ago(d: 3),
        updated: _ago(d: 2), requester: 'Mehdi Messadi'),
    _t('tk-f1c022', 'Disjoncteur local poubelles', 'r-corail', 'Corail',
        'Terminé', 'Haute', _ago(d: 5),
        updated: _ago(d: 4), requester: 'Amel Benelhadj'),
    _t('tk-b9d417', 'Spots de la piscine', 'r-peridot', 'Péridot', 'Terminé',
        'Moyenne', _ago(d: 12),
        updated: _ago(d: 11), requester: 'Sarah Kaci'),
  ];

  static Map<String, dynamic> _t(String id, String title, String residenceId,
          String residence, String status, String priority, String created,
          {String? updated,
          String location = '',
          String requester = '',
          String description = ''}) =>
      {
        'id': id,
        'title': title,
        'category': 'Électricité (Partie Commune)',
        'residenceId': residenceId,
        'residence': {'id': residenceId, 'name': residence},
        'status': status,
        'priority': priority,
        'createdAt': created,
        'updatedAt': updated ?? created,
        'location': location,
        'requester': requester,
        'email': 'resident@demo.dz',
        'assignee': 'Rachid Mansouri',
        'description': description,
        'attachments': const [],
      };

  Map<String, dynamic> ticket(String id) =>
      tickets.firstWhere((t) => t['id'] == id);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var path = request.url.path;
    final api = path.indexOf('/api');
    if (api >= 0) path = path.substring(api + 4);
    Map payload = const {};
    if (request is http.Request && request.body.isNotEmpty) {
      payload = jsonDecode(request.body) as Map;
    }
    final files = request is http.MultipartRequest ? request.files.length : 0;
    final (status, value) =
        _route(request.method.toUpperCase(), path, payload, files);
    return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(value ?? {}))), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
  }

  (int, Object?) _route(String method, String path, Map payload, int files) {
    if (path == '/auth/login' || path == '/auth/me') {
      return (200, {
        'token': 'demo',
        'id': 7,
        'name': 'Rachid Mansouri',
        'email': 'rachid@demo.dz',
        'role': 'INTERVENANT',
        'profession': 'Électricien',
        'mustChangePassword': false,
      });
    }
    if (path == '/maintenance' && method == 'GET') return (200, tickets);
    final parts = path.split('/');
    if (parts.length >= 3 && parts[1] == 'maintenance') {
      final t = ticket(parts[2]);
      if (parts.length == 4 && parts[3] == 'history') {
        return (200, {
          'history': [
            {'id': 1, 'action': 'CREATED', 'toStatus': 'Signalé', 'actorRole': 'RESIDENT', 'actorName': t['requester'], 'createdAt': t['createdAt']},
          ],
        });
      }
      if (parts.length == 4 && parts[3] == 'attachments') {
        uploadedFiles += files;
        return (201, {'attachments': const []});
      }
      if (method == 'PUT') {
        updates.add((parts[2], payload));
        t['status'] = payload['status'];
        t['updatedAt'] = _ago();
        return (200, t);
      }
      return (200, {...t, 'requesterPhone': '+213 555 10 20 30'});
    }
    if (path.startsWith('/residences/')) {
      return (200, {'id': parts.last, 'address': 'Hydra, Alger'});
    }
    if (path == '/notifications/unread-count') return (200, {'count': 2});
    return (200, const []);
  }
}
