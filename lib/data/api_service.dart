import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:http_parser/http_parser.dart';


class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A file picked on the device, ready to be uploaded.
class UploadFile {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  const UploadFile(
      {required this.bytes, required this.filename, required this.mimeType});
}

/// Wraps the HTTP client to notice when the administration has deactivated
/// the signed-in account (403 + code ACCOUNT_DISABLED), whatever the endpoint.
class _GuardedClient extends http.BaseClient {
  _GuardedClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode != 403) return response;

    final bytes = await response.stream.toBytes();
    try {
      final body = jsonDecode(utf8.decode(bytes));
      if (body is Map && body['code'] == 'ACCOUNT_DISABLED') {
        ApiService.onAccountDisabled?.call();
      }
    } catch (_) {}
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Called when any request comes back with ACCOUNT_DISABLED.
  static void Function()? onAccountDisabled;

  String? _token;
  void setToken(String? token) => _token = token;

  http.Client _client = _GuardedClient(http.Client());

  /// Remplace le client HTTP. Reserve aux tests, qui font repondre un faux
  /// serveur a la place du back-end ; l'application ne s'en sert jamais.
  @visibleForTesting
  void useClient(http.Client client) => _client = client;
  final String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://landing.aymenpromotion-dz.com/api',
  );

  /// Server root, i.e. [baseUrl] without the trailing /api.
  String get serverRoot => baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  /// Absolute URL of an uploaded file ("/uploads/x.jpg"), or null when empty.
  String? mediaUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http')) return s;
    return '$serverRoot${s.startsWith('/') ? s : '/$s'}';
  }

  static final List<Map<String, dynamic>> _defaultMaintenanceCategories = [
    {
      'category': 'Peinture (Partie Commune)',
      'items': [
        'Retouches peinture couloir',
        'Peinture Escalier',
        "Traces d'humidité",
        'Autre problème de peinture',
      ],
    },
    {
      'category': 'Plomberie (Partie Commune)',
      'items': [
        "Fuite d'eau",
        'Canalisation bouchée',
        'Mauvaise odeur',
        'Autre problème plomberie',
      ],
    },
    {
      'category': 'Problème Bâche à eau',
      'items': [
        "Niveau d'eau bas",
        'Fuite bâche',
        'Pompe défectueuse',
        'Autre problème bâche',
      ],
    },
    {
      'category': 'Problème Groupe électrogène',
      'items': [
        'Panne au démarrage',
        'Niveau carburant bas',
        'Bruit anormal',
        'Eclairage défectueux',
      ],
    },
    {
      'category': 'Ascenseurs & Accès',
      'items': [
        'Ascenseur en panne',
        "Problème TAG d'accès",
        'Rideau parking défaillant',
        'Porte hall bloquée',
      ],
    },
    {
      'category': 'Hygiène & Sécurité',
      'items': [
        'Déchets accumulés',
        'Nettoyage partie communes',
        'Problème de sécurité',
        'Nuisances sonores',
      ],
    },
    {
      'category': 'Espaces Extérieurs',
      'items': [
        'Espace vert',
        'Place de parking occupée',
        'Eclairage extérieur',
      ],
    },
    {
      'category': "Commande TAG d'accès",
      'items': ["Demande de TAG d'accès"],
    },
    {
      'category': 'Commande Télécommande Parking',
      'items': ['Demande de télécommande parking'],
    },
    {
      'category': 'Autres',
      'items': ['Autres'],
    },
  ];

  String _normalizeMaintenanceLabel(String value) {
    final trimmed = value.trim();
    if (trimmed == 'Peinture écaillée' || trimmed == 'Peinture escaliers') {
      return 'Peinture Escalier';
    }
    return trimmed;
  }

  List<Map<String, dynamic>> _normalizeMaintenanceCategories(
      List<Map<String, dynamic>> categories) {
    return categories.map((category) {
      final copy = Map<String, dynamic>.from(category);
      final items = copy['items'];
      if (items is List) {
        copy['items'] = items
            .map((item) => _normalizeMaintenanceLabel((item ?? '').toString()))
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
      }
      return copy;
    }).toList();
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password,
      {String? deviceId, String? deviceName}) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      payload['deviceId'] = deviceId.trim();
    }
    if (deviceName != null && deviceName.trim().isNotEmpty) {
      payload['deviceName'] = deviceName.trim();
    }

    final response = await _client
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    } else {
      // Preserve the backend message. Previously, the exception thrown inside
      // this try block was caught immediately and replaced by a generic error.
      String? serverMessage;
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          serverMessage = body['error'].toString();
        }
      } catch (_) {}
      if (serverMessage != null && serverMessage.trim().isNotEmpty) {
        throw Exception(serverMessage);
      }
      throw Exception('Erreur serveur (${response.statusCode})');
    }
  }

  Future<void> logout({String? deviceId}) async {
    try {
      final payload = <String, dynamic>{};
      if (deviceId != null && deviceId.trim().isNotEmpty) {
        payload['deviceId'] = deviceId.trim();
      }
      await _client
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // fire-and-forget: don't block logout if server is unreachable
    }
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/auth/password'),
          headers: _headers,
          body: jsonEncode(
              {'currentPassword': currentPassword, 'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(
            body['error'] ?? 'Impossible de changer le mot de passe');
      } catch (_) {
        throw Exception('Impossible de changer le mot de passe');
      }
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 20));
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return (body['message'] ??
                'Si un compte existe, un e-mail a été envoyé.')
            .toString();
      }
      throw Exception(body['error'] ?? 'Erreur serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur serveur');
    }
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/auth/me'), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final body = jsonDecode(response.body);
      final msg = body is Map && body['error'] != null
          ? body['error'].toString()
          : 'Erreur serveur (${response.statusCode})';
      throw ApiException(response.statusCode, msg);
    } catch (_) {
      throw ApiException(
          response.statusCode, 'Erreur serveur (${response.statusCode})');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/registrations');
    if (kDebugMode) {
      print('Calling API: $url');
      final safeEmail = (data['email'] ?? '').toString();
      print(
          'Register payload: email=$safeEmail residenceId=${data['residenceId']}');
    }

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 201) {
      if (kDebugMode) {
        final bodySnippet = response.body.length > 400
            ? '${response.body.substring(0, 400)}...'
            : response.body;
        print('Register failed: ${response.statusCode} body=$bodySnippet');
      }
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Erreur lors de l\'inscription');
      } catch (e) {
        // If response is not JSON (e.g. HTML error), show status code and snippet
        String snippet = response.body.length > 100
            ? '${response.body.substring(0, 100)}...'
            : response.body;
        throw Exception('Erreur serveur (${response.statusCode}): $snippet');
      }
    }
  }

  Future<Map<String, dynamic>> getRegistrationOptions(String residenceId,
      {bool forPropertyRequest = false}) async {
    final params = <String, String>{'residenceId': residenceId};
    if (forPropertyRequest) params['forPropertyRequest'] = 'true';
    final uri = Uri.parse('$baseUrl/registrations/options')
        .replace(queryParameters: params);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      String message = 'Erreur serveur (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        } else if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {
        final body = response.body;
        final snippet =
            body.length > 200 ? '${body.substring(0, 200)}...' : body;
        if (snippet.trim().isNotEmpty) {
          message = '$message: $snippet';
        }
      }
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Invalid options response');
  }

  Future<List<dynamic>> getPropertyAddRequests({String? status}) async {
    final uri = Uri.parse('$baseUrl/property-add-requests').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception('Failed to load property add requests');
  }

  Future<void> approvePropertyAddRequest(String id) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/property-add-requests/$id/approve'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      String msg = 'Erreur lors de la validation';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          msg = body['error'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> rejectPropertyAddRequest(String id, {String? reason}) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/property-add-requests/$id/reject'),
          headers: _headers,
          body: jsonEncode({'reason': reason ?? ''}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      String msg = 'Erreur lors du rejet';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          msg = body['error'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> submitPropertyAddRequest({
    required String residenceId,
    required String propertyId,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'residenceId': residenceId.trim(),
      'propertyId': propertyId.trim(),
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _client
        .post(
          Uri.parse('$baseUrl/property-add-requests'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'ok': true};
    }

    String msg = 'Erreur serveur (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) msg = body['error'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  /// [trustServer]: for RESIDENT accounts the backend already returns only the
  /// resident's own properties (a household member's e-mail differs from the
  /// owner's), so the client-side e-mail filter must be skipped.
  Future<List<dynamic>> getMyProperties(String email,
      {bool trustServer = false}) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/properties'), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load properties');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    final list = data is List ? data : [];
    if (trustServer) return list;
    final lowerEmail = email.toLowerCase().trim();
    return list.where((p) {
      if (p is! Map) return false;
      final ownerEmail =
          (p['owner']?['email'] ?? '').toString().toLowerCase().trim();
      return ownerEmail == lowerEmail;
    }).toList();
  }

  Future<List<dynamic>> getResidences({bool forPropertyRequest = false}) async {
    final uri = forPropertyRequest
        ? Uri.parse('$baseUrl/residences')
            .replace(queryParameters: {'scope': 'property_request'})
        : Uri.parse('$baseUrl/residences');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load residences');
  }

  Future<List<dynamic>> getIntervenants() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/users?role=INTERVENANT'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load intervenants');
  }

  Future<List<dynamic>> getUsersByRole(String role) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/users?role=${Uri.encodeComponent(role)}'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load users');
  }

  Future<List<dynamic>> getSubcontractors() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/subcontractors'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load subcontractors');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/dashboard'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load dashboard');
  }

  // --- Registration Management ---

  Future<List<dynamic>> getRegistrationRequests() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/registrations'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load requests');
    }
  }

  Future<void> approveRequest(String id) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/registrations/$id/approve'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Échec de la validation.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Échec de la validation.');
      }
    }
  }

  Future<void> rejectRequest(String id) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/registrations/$id/reject'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Échec du rejet.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Échec du rejet.');
      }
    }
  }

  // --- User Management ---

  Future<List<dynamic>> getUsers() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/users'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<dynamic>> getResidents() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/owners?onlyResidents=true'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load residents');
  }

  Future<void> deleteUser(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/users/$id'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> updateUserPassword(String id, String newPassword) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/users/$id'),
          headers: _headers,
          body: jsonEncode({'password': newPassword}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to update password');
    }
  }

  Future<void> resetUserDevices(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/users/$id/reset-devices'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      final body = _tryDecode(response.body);
      throw Exception(body['error'] ?? 'Erreur réinitialisation appareils');
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map ? Map<String, dynamic>.from(d) : {};
    } catch (_) {
      return {};
    }
  }

  // --- Tags ---

  Future<List<dynamic>> getTags() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/tags'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement tags');
  }

  Future<Map<String, dynamic>> createTag({
    required String residentEmail,
    String? residenceId,
    String? residenceName,
    String? propertyId,
    String? transactionId,
    String? transactionDescription,
    String? notes,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/tags'),
          headers: _headers,
          body: jsonEncode({
            'residentEmail': residentEmail,
            if (residenceId != null) 'residenceId': residenceId,
            if (residenceName != null) 'residenceName': residenceName,
            if (propertyId != null) 'propertyId': propertyId,
            if (transactionId != null) 'transactionId': transactionId,
            if (transactionDescription != null)
              'transactionDescription': transactionDescription,
            if (notes != null) 'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur création TAG');
  }

  // --- Maintenance Tickets ---

  Future<List<dynamic>> getTickets({String? scope, String? residenceId}) async {
    Uri uri = Uri.parse('$baseUrl/maintenance');
    final params = <String, String>{};
    if (scope != null && scope.trim().isNotEmpty) {
      params['scope'] = scope.trim();
    }
    if (residenceId != null && residenceId.trim().isNotEmpty) {
      params['residenceId'] = residenceId.trim();
    }
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    // Si la liste est vide ou s'il y a une erreur 404 (pas de tickets), on renvoie une liste vide
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return [];
    } else {
      // Pour le debug, on peut afficher l'erreur mais on évite de bloquer l'UI
      if (kDebugMode) {
        print(
            'Error fetching tickets: ${response.statusCode} ${response.body}');
      }
      throw Exception('Failed to load tickets (${response.statusCode})');
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceCategories() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/maintenance/categories'), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
            'Categories API unavailable (${response.statusCode}), fallback local categories.');
      }
      return _normalizeMaintenanceCategories(
          List<Map<String, dynamic>>.from(_defaultMaintenanceCategories));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['data'] is List) {
      final list = decoded['data'] as List;
      return _normalizeMaintenanceCategories(
          list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList());
    }
    if (decoded is List) {
      return _normalizeMaintenanceCategories(decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList());
    }
    return _normalizeMaintenanceCategories(
        List<Map<String, dynamic>>.from(_defaultMaintenanceCategories));
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/financial'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load transactions');
  }

  /// Returns 'Payé', 'Impayé', 'Inconnu', 'Aucune charge', etc. for the given client email.
  Future<String> getClientChargeStatus(String email) async {
    final uri = Uri.parse('$baseUrl/financial/client-status')
        .replace(queryParameters: {'email': email});
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['status'] ?? '').toString();
    }
    return '';
  }

  Future<List<dynamic>> getMyCharges() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/financial/my-charges'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to load charges');
    } catch (_) {
      throw Exception('Failed to load charges');
    }
  }

  Future<Map<String, dynamic>> getMyChargesSummary() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/financial/my-charges-summary'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to load charges summary');
    } catch (_) {
      throw Exception('Failed to load charges summary');
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/notifications/unread-count'),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/notifications'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to load notifications');
    } catch (_) {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationRead(String id) async {
    final response = await _client
        .put(Uri.parse('$baseUrl/notifications/$id/read'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to mark notification as read');
      } catch (_) {
        throw Exception('Failed to mark notification as read');
      }
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await _client
        .put(Uri.parse('$baseUrl/notifications/read-all'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(
            body['error'] ?? 'Failed to mark all notifications as read');
      } catch (_) {
        throw Exception('Failed to mark all notifications as read');
      }
    }
  }

  Future<Map<String, dynamic>> updateTransaction(
      {required String id, required Map<String, dynamic> payload}) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/financial/$id'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to update transaction');
      } catch (_) {
        throw Exception('Failed to update transaction');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/maintenance'),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to create ticket');
      } catch (_) {
        throw Exception('Failed to create ticket');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTicket(
      String id, Map<String, dynamic> data) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/maintenance/$id'),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to update ticket');
      } catch (_) {
        throw Exception('Failed to update ticket');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadTicketAttachment({
    required String ticketId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$baseUrl/maintenance/$ticketId/attachment');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed =
        await _client.send(request).timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Upload failed');
      } catch (_) {
        throw Exception('Upload failed (${response.statusCode})');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --- Household Members ---

  Future<List<dynamic>> getHouseholdMembers() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/household-members'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement des membres');
  }

  Future<Map<String, dynamic>> addHouseholdMember({
    required String fullName,
    required String email,
    String? relation,
    String? phone,
    String? photoDataUrl,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/household-members'),
          headers: _headers,
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            if (relation != null) 'relation': relation,
            if (phone != null) 'phone': phone,
            if (photoDataUrl != null) 'photo': photoDataUrl,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(_tryDecode(response.body)['error'] ??
        "Erreur lors de l'ajout du membre");
  }

  Future<Map<String, dynamic>> updateHouseholdMember(
    String id, {
    String? fullName,
    String? email,
    String? relation,
    String? phone,
    String? photoDataUrl,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/household-members/$id'),
          headers: _headers,
          body: jsonEncode({
            if (fullName != null) 'fullName': fullName,
            if (email != null && email.isNotEmpty) 'email': email,
            if (relation != null) 'relation': relation,
            if (phone != null) 'phone': phone,
            if (photoDataUrl != null) 'photo': photoDataUrl,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur lors de la modification');
  }

  /// Sends the member a new temporary password by e-mail. Returns whether the
  /// e-mail could be sent.
  Future<bool> resendMemberAccess(String id) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/household-members/$id/resend-access'),
            headers: _headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return _tryDecode(response.body)['emailSent'] == true;
    }
    throw Exception(_tryDecode(response.body)['error'] ?? 'Erreur');
  }

  Future<void> removeHouseholdMember(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/household-members/$id'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_tryDecode(response.body)['error'] ??
          'Erreur lors de la suppression');
    }
  }

  // --- Announcements ("Avis" / "Notices") ---

  Future<List<dynamic>> getAnnouncements() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/announcements'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement des avis');
  }

  Future<void> markAnnouncementRead(String id) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/announcements/$id/read'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_tryDecode(response.body)['error'] ?? 'Erreur');
    }
  }

  Future<List<dynamic>> getManagedAnnouncements() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/announcements/manage'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement des avis');
  }

  Future<Map<String, dynamic>> createAnnouncement(
      Map<String, dynamic> payload) async {
    final response = await _client
        .post(Uri.parse('$baseUrl/announcements'),
            headers: _headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur création de l’avis');
  }

  // --- Messages (Report Chat + Message Admin) ---

  Future<List<dynamic>> getTicketMessages(String ticketId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/messages/ticket/$ticketId'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement des messages');
  }

  Future<Map<String, dynamic>> sendTicketMessage(
    String ticketId, {
    String? body,
    List<String>? attachmentDataUrls,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/messages/ticket/$ticketId'),
          headers: _headers,
          body: jsonEncode({
            if (body != null) 'body': body,
            if (attachmentDataUrls != null) 'attachments': attachmentDataUrls,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(_tryDecode(response.body)['error'] ??
        "Erreur lors de l'envoi du message");
  }

  // --- Profile photo ---

  Future<Map<String, dynamic>> updateProfilePhoto(String photoDataUrl) async {
    final response = await _client
        .put(Uri.parse('$baseUrl/auth/photo'),
            headers: _headers, body: jsonEncode({'photo': photoDataUrl}))
        .timeout(const Duration(seconds: 40));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur lors de l\'envoi de la photo');
  }

  Future<Map<String, dynamic>> removeProfilePhoto() async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/auth/photo'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(_tryDecode(response.body)['error'] ?? 'Erreur');
  }

  // --- Residence details ---

  Future<Map<String, dynamic>> getResidence(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/residences/$id'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement de la résidence');
  }

  // --- Documents published by the administration ---

  Future<List<dynamic>> getResidentDocuments() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/documents/resident'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement des documents');
  }

  Future<Uint8List> downloadResidentDocument(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/documents/$id/download'), headers: _headers)
        .timeout(const Duration(seconds: 90));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Téléchargement impossible');
  }

  /// Downloads a public uploaded file (e.g. a ticket attachment).
  Future<Uint8List> downloadPublicFile(String pathOrUrl) async {
    final url = mediaUrl(pathOrUrl);
    if (url == null) throw Exception('Fichier introuvable');
    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 90));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Téléchargement impossible');
  }

  // --- Ticket details: attachments, history, information ---

  Future<Map<String, dynamic>> getTicket(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/maintenance/$id'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement du signalement');
  }

  /// Up to 4 files, 10 MB in total (enforced server side too).
  Future<List<dynamic>> uploadTicketAttachments({
    required String ticketId,
    required List<UploadFile> files,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/maintenance/$ticketId/attachments'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    for (final f in files) {
      request.files.add(http.MultipartFile.fromBytes('files', f.bytes,
          filename: f.filename, contentType: MediaType.parse(f.mimeType)));
    }
    final streamed =
        await _client.send(request).timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['attachments'] is List
          ? decoded['attachments'] as List
          : [];
    }
    throw Exception(_tryDecode(response.body)['error'] ??
        'Envoi des pièces jointes impossible (${response.statusCode})');
  }

  /// { history: [...], startedAt, closedAt }
  Future<Map<String, dynamic>> getTicketHistory(String ticketId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/maintenance/$ticketId/history'),
            headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw Exception(
        _tryDecode(response.body)['error'] ?? 'Erreur chargement de l\'historique');
  }
}
