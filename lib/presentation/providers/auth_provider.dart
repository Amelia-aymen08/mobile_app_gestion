import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthProvider() {
    // L'administration peut desactiver un compte : n'importe quel appel
    // repond alors 403 ACCOUNT_DISABLED. On coupe la session sur place,
    // quel que soit l'ecran ouvert.
    ApiService.onAccountDisabled = _handleAccountDisabled;
  }

  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _notice;

  /// Message a afficher une seule fois sur l'ecran de connexion, quand la
  /// session a ete coupee par le serveur.
  String? consumeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  /// Compte cree via un foyer, et non par l'administration.
  bool get isHouseholdMember => _user?['isHouseholdMember'] == true;

  /// Photo de profil, deja en URL absolue.
  String? get photoUrl => _apiService.mediaUrl(_user?['photo']);

  void _handleAccountDisabled() {
    if (_token == null) return;
    _notice = 'accountDisabled';
    _token = null;
    _user = null;
    _apiService.setToken(null);
    SharedPreferences.getInstance().then((prefs) async {
      final deviceId = prefs.getString('device_id');
      await prefs.clear();
      if (deviceId != null && deviceId.trim().isNotEmpty) {
        await prefs.setString('device_id', deviceId);
      }
    });
    notifyListeners();
  }

  /// Met a jour la photo apres que l'API l'a acceptee.
  Future<void> setPhoto(String? photo) async {
    if (_user == null) return;
    _user = {..._user!, 'photo': photo};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_user));
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  String get userRole => _user?['role'] ?? 'GUEST';
  bool get mustChangePassword => (_user?['mustChangePassword'] == true);

  String _generateDeviceId() {
    final r = Random.secure();
    final a = DateTime.now().microsecondsSinceEpoch.toString();
    // Sur le web les operateurs de bits travaillent sur 32 bits signes :
    // `1 << 32` y vaut 0, et nextInt(0) leve un RangeError. On tire donc
    // quatre blocs de 16 bits, valides sur toutes les plateformes.
    String hex16() => r.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    final b = '${hex16()}${hex16()}';
    final c = '${hex16()}${hex16()}';
    return '$a-$b$c';
  }

  /// Coffre du systeme : trousseau sur iOS, stockage chiffre sur Android.
  /// Il survit a la desinstallation, la ou les preferences sont effacees.
  static const _coffre = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Identifiant de l'appareil, conserve dans le coffre du systeme.
  ///
  /// Le serveur limite le nombre d'appareils par compte. Range dans les
  /// preferences, l'identifiant disparaissait avec l'application : chaque
  /// reinstallation — et TestFlight en enchaine — se presentait comme un
  /// telephone neuf et consommait une place. Dans le coffre, il survit, et
  /// le meme telephone reste le meme appareil.
  ///
  /// L'identifiant deja tire est repris tel quel s'il existe : la place
  /// enregistree cote serveur reste la sienne, aucune n'est perdue en
  /// chemin.
  Future<Map<String, String>> _getDevicePayload() async {
    final prefs = await SharedPreferences.getInstance();
    String? id;
    try {
      id = await _coffre.read(key: 'device_id');
    } catch (_) {
      // Coffre indisponible — navigateur en navigation privee, appareil
      // verrouille. On retombe sur les preferences.
    }

    id ??= prefs.getString('device_id');
    id ??= _generateDeviceId();

    // Les deux emplacements sont tenus a jour : le coffre pour survivre a
    // la desinstallation, les preferences pour la deconnexion, qui les lit.
    await prefs.setString('device_id', id);
    try {
      await _coffre.write(key: 'device_id', value: id);
    } catch (_) {}
    // AIDE AU TEST — a retirer avant la mise en production.
    // En test local l'app est servie sur plusieurs ports, et le navigateur
    // cloisonne son stockage par port : chaque port tirait son propre
    // identifiant et consommait une place d'appareil sur le compte. Sur
    // 127.0.0.1, les quatre ports comptent donc pour un seul appareil.
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == '127.0.0.1' || host == 'localhost') {
        id = 'web-test-local';
      }
    }
    // `Platform` vient de dart:io et leve une exception sur le web : il faut
    // ecarter ce cas avant toute lecture.
    final os = kIsWeb
        ? 'Web'
        : Platform.isAndroid
            ? 'Android'
            : Platform.isIOS
                ? 'iOS'
                : Platform.operatingSystem;
    return { 'deviceId': id, 'deviceName': os };
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userStr = prefs.getString('user');
      if (token == null) return;
      Map<String, dynamic>? decodedUser;
      if (userStr != null) {
        try {
          final decoded = json.decode(userStr);
          if (decoded is Map) decodedUser = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      _token = token;
      _apiService.setToken(_token);
      _user = decodedUser;
      notifyListeners();

      try {
        final me = await _apiService.me();
        _user = {
          'id': me['id'],
          'name': me['name'],
          'email': me['email'],
          'role': me['role'],
          'profession': me['profession'],
          'zone': me['zone'],
          'photo': me['photo'],
          'isHouseholdMember': me['isHouseholdMember'] == true,
          'mustChangePassword': me['mustChangePassword'] == true,
        };
        await prefs.setString('user', json.encode(_user));
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('restoreSession /me failed (backend may be outdated): $e');
      }
    } catch (e) {
      if (kDebugMode) print('restoreSession: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final device = await _getDevicePayload();
      final data = await _apiService.login(
        normalizedEmail,
        password,
        deviceId: device['deviceId'],
        deviceName: device['deviceName'],
      );

      _token = data['token'];
      _apiService.setToken(_token); // Set token in singleton ApiService
      
      _user = {
        'id': data['id'],
        'name': data['name'],
        'email': data['email'],
        'role': data['role'],
        'profession': data['profession'],
        'zone': data['zone'],
        'photo': data['photo'],
        'isHouseholdMember': data['isHouseholdMember'] == true,
        'mustChangePassword': data['mustChangePassword'] == true,
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', json.encode(_user));
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      
      _isLoading = false;
      notifyListeners();
      // Re-throw to be handled by UI
      rethrow;
    }
  }

  Future<void> logout() async {
    // Notify backend to remove this device (fire-and-forget)
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');
      await _apiService.logout(deviceId: deviceId);
    } catch (_) {}

    _token = null;
    _user = null;
    _apiService.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    // Preserve device_id so re-login on same device doesn't create a new entry
    final deviceId = prefs.getString('device_id');
    await prefs.clear();
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      await prefs.setString('device_id', deviceId);
    }

    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_token == null) throw Exception('Not authenticated');
    await _apiService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    if (_user != null) {
      _user = { ..._user!, 'mustChangePassword': false };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user));
      notifyListeners();
    }
  }
}
