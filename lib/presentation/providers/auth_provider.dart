import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthProvider() {
    ApiService.onAccountDisabled = _handleAccountDisabled;
  }

  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _notice;

  /// One-shot message for the login screen (e.g. the account was deactivated).
  String? consumeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  /// Accounts created through a household (not the primary resident).
  bool get isHouseholdMember => _user?['isHouseholdMember'] == true;

  Map<String, dynamic> _userFrom(Map<dynamic, dynamic> data) => {
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

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_user));
  }

  void _handleAccountDisabled() {
    if (_token == null) return;
    _notice = "Ce compte a été désactivé. Veuillez contacter l'administration.";
    // No server round-trip: the API would just refuse it again.
    _clearLocalSession();
  }

  /// Updates the profile picture locally after the API accepted it.
  Future<void> setPhoto(String? photoUrl) async {
    if (_user == null) return;
    _user = {..._user!, 'photo': photoUrl};
    await _persistUser();
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
    final b = r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final c = r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '$a-$b$c';
  }

  Future<Map<String, String>> _getDevicePayload() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null || id.trim().isEmpty) {
      id = _generateDeviceId();
      await prefs.setString('device_id', id);
    }
    final os = Platform.isAndroid
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
        _user = _userFrom(me);
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
      
      _user = _userFrom(data);
      
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

    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    _token = null;
    _user = null;
    _apiService.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    // Preserve device_id so re-login on same device doesn't create a new
    // entry, and the chosen language so the login screen keeps it.
    final deviceId = prefs.getString('device_id');
    final lang = prefs.getString(LocaleProvider.prefsKey);
    await prefs.clear();
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      await prefs.setString('device_id', deviceId);
    }
    if (lang != null) await prefs.setString(LocaleProvider.prefsKey, lang);

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
