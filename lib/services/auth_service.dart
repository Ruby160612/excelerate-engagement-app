import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._api, this._storage);

  final ApiService _api;
  final StorageService _storage;
  AppUser? _user;
  bool _initialized = false;
  String? _initializationError;

  AppUser? get user => _user;
  bool get initialized => _initialized;
  String? get initializationError => _initializationError;

  Future<void> restoreSession() async {
    try {
      final token = _storage.sessionToken;
      if (token != null) {
        _api.sessionToken = token;
        _user = AppUser.fromJson(
          await _api.get('/auth/me') as Map<String, dynamic>,
        );
      }
    } catch (error) {
      _api.sessionToken = null;
      _user = null;
      _initializationError = 'Your saved session could not be restored. '
          'Please sign in again.';
      if (error is ApiException && error.statusCode == 401) {
        try { await _storage.clearSession(); } catch (_) { /* Retry on login. */ }
      }
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _acceptSession(await _api.post('/auth/login', {
      'email': email.trim(), 'password': password,
    }) as Map<String, dynamic>);
  }

  Future<void> signup(String name, String email, String password,
      String invitationCode) async {
    await _acceptSession(await _api.post('/auth/signup', {
      'name': name.trim(), 'email': email.trim(), 'password': password,
      'invitation_code': invitationCode.trim(),
    }) as Map<String, dynamic>);
  }

  Future<void> _acceptSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    if (token.isEmpty) throw const ApiException('The session token is missing.');
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveSession(token);
    _api.sessionToken = token;
    _user = user;
    _initializationError = null;
    notifyListeners();
  }

  Future<void> createProfile(Profile profile) async {
    await _api.put('/profiles/me', profile.toJson());
    // Refresh authoritative user state after the server completes onboarding.
    _user = AppUser.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _storage.clearSession();
    } finally {
      _api.sessionToken = null;
      _user = null;
      notifyListeners();
    }
  }
}
