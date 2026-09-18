import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;

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

  Future<Map<String, String>> _getDevicePayload() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null || id.trim().isEmpty) {
      id = _generateDeviceId();
      await prefs.setString('device_id', id);
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
      // MODE DEMONSTRATION — a retirer avant la mise en production.
      final savedEmail = (decodedUser?['email'] ?? '').toString();
      if (savedEmail.isNotEmpty) _apiService.restoreDemoSession(savedEmail);
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
