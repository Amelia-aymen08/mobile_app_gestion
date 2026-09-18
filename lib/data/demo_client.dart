import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client HTTP de demonstration.
///
/// Il se substitue au vrai client dans [ApiService] et repond en local, sans
/// toucher au back-end ni au code des ecrans : ceux-ci continuent d'appeler
/// l'API normalement et ne savent pas qu'ils parlent a un faux serveur.
///
/// Objectif : parcourir l'app sans compte reel, notamment pour comparer un
/// resident qui ne possede qu'un bien a un resident qui en possede trois.
///
/// A RETIRER AVANT LA MISE EN PRODUCTION. Tant que ce fichier est present,
/// deux adresses ouvrent une session sans passer par le serveur.
class DemoProfile {
  final String email;
  final String fullName;
  final List<Map<String, dynamic>> properties;
  final Map<String, dynamic> chargesSummary;
  final List<Map<String, dynamic>> charges;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> householdMembers;

  const DemoProfile({
    required this.email,
    required this.fullName,
    required this.properties,
    required this.chargesSummary,
    required this.charges,
    required this.tickets,
    required this.announcements,
    required this.notifications,
    required this.householdMembers,
  });
}

/// Mot de passe commun aux deux profils.
const demoPassword = 'demo';

String _iso(int daysAgo) => DateTime.now()
    .subtract(Duration(days: daysAgo))
    .toIso8601String();

String _isoIn(int daysAhead) =>
    DateTime.now().add(Duration(days: daysAhead)).toIso8601String();

Map<String, dynamic> _property({
  required String ownerEmail,
  required String id,
  required String residenceName,
  required String address,
  required String lot,
  required String type,
  required int floor,
  required int surface,
  required String block,
}) =>
    {
      'id': id,
      'lotNumber': lot,
      'type': type,
      'floor': floor,
      'surface': surface,
      'block': block,
      'status': 'ACTIF',
      'residenceId': residenceName,
      // getMyProperties filtre sur owner.email : sans ce champ la liste
      // revient vide, meme si le serveur a bien repondu.
      'owner': {'email': ownerEmail},
      'Residence': {
        'id': residenceName,
        'name': residenceName,
        'address': address,
        // Laisse vide : l'app retombe sur la photo locale, retrouvee a partir
        // du nom de la residence.
        'image': null,
      },
    };

/// Resident avec un seul bien.
final demoSingle = DemoProfile(
  email: 'un.bien@demo.dz',
  fullName: 'Mehdi Messadi',
  properties: [
    _property(
      ownerEmail: 'un.bien@demo.dz',
      id: 'p1',
      residenceName: 'Angélite',
      address: 'Hydra, Alger — Wilaya 16',
      lot: 'A-101',
      type: 'Appartement',
      floor: 3,
      surface: 127,
      block: 'A',
    ),
  ],
  chargesSummary: {
    'annualAmount': 148800,
    'nextPaymentDate': _isoIn(6),
    'daysRemaining': 6,
    'ownerStatus': 'A_JOUR',
  },
  charges: [
    {
      'type': 'Charges communes',
      'description': 'Entretien des parties communes',
      'amount': 12400,
      'status': 'Payé',
      'periodStart': _iso(60),
      'periodEnd': _iso(30),
      'ownerStatus': 'A_JOUR',
    },
    {
      'type': 'Charges communes',
      'description': 'Eau et assainissement',
      'amount': 2400,
      'status': 'En attente',
      'periodStart': _iso(30),
      'periodEnd': _isoIn(1),
      'ownerStatus': 'A_JOUR',
    },
  ],
  tickets: [
    {
      'id': 't1',
      'title': 'Interphone du bloc A hors service',
      'description': "L'interphone ne sonne plus depuis lundi.",
      'category': 'Électricité (Partie Commune)',
      'location': 'Bloc A — entrée',
      'priority': 'HAUTE',
      'status': 'EN_COURS',
      'createdAt': _iso(2),
      'email': 'un.bien@demo.dz',
      'residenceId': 'Angélite',
      'attachmentUrl': null,
      'rejectionReason': null,
    },
    {
      'id': 't2',
      'title': 'Ampoule grillée dans l\'escalier',
      'description': 'Troisième étage, palier.',
      'category': 'Électricité (Partie Commune)',
      'location': 'Escalier — 3e étage',
      'priority': 'BASSE',
      'status': 'TERMINE',
      'createdAt': _iso(21),
      'email': 'un.bien@demo.dz',
      'residenceId': 'Angélite',
      'attachmentUrl': null,
      'rejectionReason': null,
    },
  ],
  announcements: [
    {
      'id': 'a1',
      'title': 'Coupure d\'eau programmée',
      'body':
          'Une intervention sur le réseau d\'eau aura lieu le 2 du mois prochain, de 8 h à 14 h. Pensez à stocker l\'eau nécessaire.',
      'category': 'URGENT',
      'createdAt': _iso(1),
      'publishAt': _iso(1),
      'isRead': false,
      'blocks': ['A', 'B'],
      // Champs proposes a l'equipe back-end, pas encore servis par l'API.
      // Presents ici pour que l'ecran de detail soit visible et testable.
      'scheduledDate': '2026-06-02',
      'scheduledFrom': '08:00',
      'scheduledTo': '14:00',
      'timeline': [
        {'label': "Début de l'intervention", 'time': '08:00'},
        {'label': "Coupure de l'eau", 'time': '08:15'},
        {'label': 'Rétablissement', 'time': '14:00', 'estimated': true},
      ],
      'instructions': [
        "Stockez l'eau nécessaire avant 8 h.",
        'Évitez toute consommation non indispensable.',
        'Rétablissement prévu vers 14 h.',
      ],
    },
    {
      'id': 'a2',
      'title': 'Règlement intérieur mis à jour',
      'body':
          'La nouvelle version du règlement intérieur est disponible dans vos documents.',
      'category': 'INFO',
      'createdAt': _iso(9),
      'publishAt': _iso(9),
      'isRead': true,
      'blocks': ['A', 'B', 'C'],
    },
  ],
  notifications: [
    {
      'id': 'n1',
      'title': 'Votre signalement avance',
      'message': "L'interphone du bloc A est passé en cours de traitement.",
      'type': 'TICKET',
      'createdAt': _iso(1),
      'isRead': false,
    },
    {
      'id': 'n2',
      'title': 'Échéance proche',
      'message': 'Votre prochaine échéance tombe dans 6 jours.',
      'type': 'PAIEMENT',
      'createdAt': _iso(3),
      'isRead': false,
    },
  ],
  householdMembers: [
    {
      'id': 'h1',
      'fullName': 'Amina Messadi',
      'relation': 'Conjoint',
      'phone': '+213 555 01 02 03',
      'accessLevel': 'RESIDENT',
      'photo': null,
    },
  ],
);

/// Resident avec trois biens, pour verifier le changement de bien.
final demoMulti = DemoProfile(
  email: 'trois.biens@demo.dz',
  fullName: 'Yacine Belkacem',
  properties: [
    _property(
      ownerEmail: 'trois.biens@demo.dz',
      id: 'p1',
      residenceName: 'Corail',
      address: 'Hydra, Alger — Wilaya 16',
      lot: 'B-302',
      type: 'Appartement',
      floor: 3,
      surface: 142,
      block: 'B',
    ),
    _property(
      ownerEmail: 'trois.biens@demo.dz',
      id: 'p2',
      residenceName: 'Péridot',
      address: 'Chéraga, Alger — Wilaya 16',
      lot: 'C-12',
      type: 'Appartement',
      floor: 1,
      surface: 96,
      block: 'C',
    ),
    _property(
      ownerEmail: 'trois.biens@demo.dz',
      id: 'p3',
      residenceName: 'Sélénite',
      address: 'Bab Ezzouar, Alger — Wilaya 16',
      lot: 'L-004',
      type: 'Local commercial',
      floor: 0,
      surface: 58,
      block: 'L',
    ),
  ],
  chargesSummary: {
    'annualAmount': 396000,
    'nextPaymentDate': _isoIn(24),
    'daysRemaining': 24,
    'ownerStatus': 'RETARD',
  },
  charges: [
    {
      'type': 'Charges communes',
      'description': 'Corail — entretien',
      'amount': 14200,
      'status': 'En attente',
      'periodStart': _iso(30),
      'periodEnd': _isoIn(24),
      'ownerStatus': 'RETARD',
    },
    {
      'type': 'Charges communes',
      'description': 'Péridot — entretien',
      'amount': 9600,
      'status': 'Payé',
      'periodStart': _iso(60),
      'periodEnd': _iso(30),
      'ownerStatus': 'RETARD',
    },
    {
      'type': 'Charges communes',
      'description': 'Sélénite — local commercial',
      'amount': 7400,
      'status': 'En retard',
      'periodStart': _iso(90),
      'periodEnd': _iso(60),
      'ownerStatus': 'RETARD',
    },
  ],
  tickets: [
    {
      'id': 't1',
      'title': 'Ascenseur B hors service',
      'description': "L'ascenseur s'arrête entre le 2e et le 3e étage.",
      'category': 'Ascenseur (Partie Commune)',
      'location': 'Corail — Bloc B',
      'priority': 'URGENTE',
      'status': 'EN_COURS',
      'createdAt': _iso(3),
      'email': 'trois.biens@demo.dz',
      'residenceId': 'Corail',
      'attachmentUrl': null,
      'rejectionReason': null,
    },
    {
      'id': 't2',
      'title': 'Fuite au parking souterrain',
      'description': 'Infiltration au niveau de la place 14.',
      'category': 'Plomberie (Partie Commune)',
      'location': 'Péridot — parking',
      'priority': 'HAUTE',
      'status': 'OUVERT',
      'createdAt': _iso(5),
      'email': 'trois.biens@demo.dz',
      'residenceId': 'Péridot',
      'attachmentUrl': null,
      'rejectionReason': null,
    },
  ],
  announcements: demoSingle.announcements,
  notifications: [
    {
      'id': 'n1',
      'title': 'Charges en retard',
      'message': 'Une charge du local Sélénite reste impayée.',
      'type': 'PAIEMENT',
      'createdAt': _iso(2),
      'isRead': false,
    },
  ],
  householdMembers: const [],
);

final _profiles = <String, DemoProfile>{
  demoSingle.email: demoSingle,
  demoMulti.email: demoMulti,
};

/// Renvoie le profil correspondant aux identifiants, ou null.
DemoProfile? demoProfileFor(String email, String password) {
  if (password != demoPassword) return null;
  return _profiles[email.trim().toLowerCase()];
}

/// Retrouve un profil par sa seule adresse, sans mot de passe : sert a
/// rebrancher le faux serveur au redemarrage de l'app, quand la session est
/// restauree depuis le stockage local.
DemoProfile? demoProfileByEmail(String email) =>
    _profiles[email.trim().toLowerCase()];

/// Vrai si l'adresse appartient a un profil de demonstration, quel que soit
/// le mot de passe : sert a basculer le client avant l'appel.
bool isDemoEmail(String email) =>
    _profiles.containsKey(email.trim().toLowerCase());

class DemoClient extends http.BaseClient {
  final DemoProfile profile;
  DemoClient(this.profile);

  /// Copies de travail : les ecrans peuvent creer un signalement ou marquer
  /// une notification comme lue, et le changement doit tenir pendant la
  /// session.
  late final List<Map<String, dynamic>> _tickets =
      profile.tickets.map((e) => Map<String, dynamic>.from(e)).toList();
  late final List<Map<String, dynamic>> _notifications =
      profile.notifications.map((e) => Map<String, dynamic>.from(e)).toList();
  late final List<Map<String, dynamic>> _announcements =
      profile.announcements.map((e) => Map<String, dynamic>.from(e)).toList();
  late final List<Map<String, dynamic>> _members =
      profile.householdMembers.map((e) => Map<String, dynamic>.from(e)).toList();

  int _seq = 100;
  String _nextId(String prefix) => '$prefix${_seq++}';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Une legere latence evite un rendu trop instantane, qui masquerait les
    // etats de chargement qu'on cherche justement a verifier.
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final method = request.method.toUpperCase();
    var path = request.url.path;
    final api = path.indexOf('/api');
    if (api >= 0) path = path.substring(api + 4);

    Object? body;
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        body = jsonDecode(request.body);
      } catch (_) {
        body = null;
      }
    }
    final payload = body is Map ? Map<String, dynamic>.from(body) : const {};

    final result = _route(method, path, payload);
    return _respond(result.$1, result.$2);
  }

  (int, Object?) _route(String method, String path, Map payload) {
    // ── Authentification ──────────────────────────────────────────────────
    if (path == '/auth/login') {
      // AuthProvider lit les champs de l'utilisateur au premier niveau de la
      // reponse, pas sous une cle « user » : on respecte cette forme, sans
      // quoi le prenom et le role arrivent vides.
      return (200, {'token': 'demo-token', ..._user()});
    }
    if (path == '/auth/me') return (200, _user());
    if (path == '/auth/logout') return (200, {'ok': true});

    // ── Biens et residences ───────────────────────────────────────────────
    if (path == '/properties') {
      // getMyProperties lit la liste sous la cle « data », pas a la racine.
      return (200, {'data': profile.properties});
    }
    if (path == '/residences') {
      return (
        200,
        profile.properties
            .map((p) => Map<String, dynamic>.from(p['Residence'] as Map))
            .toList()
      );
    }

    // ── Signalements ──────────────────────────────────────────────────────
    if (path == '/maintenance/categories') return (200, const []);
    if (path == '/maintenance' && method == 'GET') return (200, _tickets);
    if (path == '/maintenance' && method == 'POST') {
      final t = <String, dynamic>{
        'id': _nextId('t'),
        'title': payload['title'] ?? 'Signalement',
        'description': payload['description'] ?? '',
        'category': payload['category'] ?? '',
        'location': payload['location'] ?? '',
        'priority': payload['priority'] ?? 'MOYENNE',
        'status': 'OUVERT',
        'createdAt': DateTime.now().toIso8601String(),
        'email': profile.email,
        'residenceId': payload['residenceId'],
        'attachmentUrl': null,
        'rejectionReason': null,
      };
      _tickets.insert(0, t);
      return (201, t);
    }
    if (path.startsWith('/maintenance/')) {
      final id = path.split('/').last;
      final t = _tickets.firstWhere((e) => e['id'] == id,
          orElse: () => <String, dynamic>{});
      if (method != 'GET') t.addAll(Map<String, dynamic>.from(payload));
      return (200, t);
    }
    if (path.startsWith('/messages/ticket/')) {
      if (method == 'POST') {
        return (201, {
          'id': _nextId('m'),
          'message': payload['message'] ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'senderRole': 'RESIDENT',
        });
      }
      return (200, const []);
    }

    // ── Finances ──────────────────────────────────────────────────────────
    if (path == '/financial/my-charges') return (200, profile.charges);
    if (path == '/financial/my-charges-summary') {
      return (200, profile.chargesSummary);
    }
    if (path == '/financial/client-status') {
      return (200, {'status': profile.chargesSummary['ownerStatus']});
    }

    // ── Notifications ─────────────────────────────────────────────────────
    if (path == '/notifications/unread-count') {
      final n = _notifications.where((e) => e['isRead'] != true).length;
      return (200, {'count': n});
    }
    if (path == '/notifications/read-all') {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
      return (200, {'ok': true});
    }
    if (path.startsWith('/notifications/') && path.endsWith('/read')) {
      final id = path.split('/')[2];
      for (final n in _notifications) {
        if (n['id'] == id) n['isRead'] = true;
      }
      return (200, {'ok': true});
    }
    if (path == '/notifications') return (200, _notifications);

    // ── Annonces ──────────────────────────────────────────────────────────
    if (path.startsWith('/announcements/') && path.endsWith('/read')) {
      final id = path.split('/')[2];
      for (final a in _announcements) {
        if (a['id'] == id) a['isRead'] = true;
      }
      return (200, {'ok': true});
    }
    if (path == '/announcements') return (200, _announcements);

    // ── Foyer ─────────────────────────────────────────────────────────────
    if (path == '/household-members' && method == 'GET') return (200, _members);
    if (path == '/household-members' && method == 'POST') {
      final m = <String, dynamic>{
        'id': _nextId('h'),
        'fullName': payload['fullName'] ?? '',
        'relation': payload['relation'] ?? '',
        'phone': payload['phone'] ?? '',
        'accessLevel': payload['accessLevel'] ?? 'VISITEUR',
        'photo': null,
      };
      _members.add(m);
      return (201, m);
    }
    if (path.startsWith('/household-members/')) {
      final id = path.split('/').last;
      if (method == 'DELETE') {
        _members.removeWhere((e) => e['id'] == id);
        return (200, {'ok': true});
      }
      final m = _members.firstWhere((e) => e['id'] == id,
          orElse: () => <String, dynamic>{});
      m.addAll(Map<String, dynamic>.from(payload));
      return (200, m);
    }

    // Tout le reste : une reponse vide vaut mieux qu'une erreur, l'ecran
    // affiche alors son etat « aucune donnee » au lieu de planter.
    return (200, const []);
  }

  Map<String, dynamic> _user() => {
        'id': 'demo-${profile.email}',
        'email': profile.email,
        'fullName': profile.fullName,
        'name': profile.fullName,
        'role': 'RESIDENT',
        'mustChangePassword': false,
      };

  http.StreamedResponse _respond(int status, Object? body) {
    final bytes = utf8.encode(jsonEncode(body ?? {}));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
