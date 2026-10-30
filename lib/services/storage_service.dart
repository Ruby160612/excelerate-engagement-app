import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._preferences);

  final SharedPreferences _preferences;
  static const _sessionKey = 'excelerate.session.token';

  String? get sessionToken => _preferences.getString(_sessionKey);

  Future<void> saveSession(String token) async {
    if (!await _preferences.setString(_sessionKey, token)) {
      throw StateError('Unable to save your session. Please try again.');
    }
  }

  Future<void> clearSession() async {
    if (!await _preferences.remove(_sessionKey)) {
      throw StateError('Unable to clear your saved session.');
    }
  }

  String? cvName(String userId) =>
      _preferences.getString('excelerate.cv.$userId');

  Future<void> saveCvName(String userId, String filename) async {
    await _preferences.setString('excelerate.cv.$userId', filename);
  }
}
