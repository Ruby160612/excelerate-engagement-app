import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const user = {
    'id': 'u1',
    'name': 'Ada',
    'email': 'ada@example.com',
    'role': 'learner',
    'profile_completed': true
  };

  test(
      'login persists a token and restoration verifies the user with the server',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) {
            expect(jsonDecode(request.body)['email'], 'ada@example.com');
            return http.Response(
                jsonEncode({'token': 'session', 'user': user}), 200);
          }
          expect(request.url.path, '/api/auth/me');
          expect(request.headers['Authorization'], 'Bearer session');
          return http.Response(jsonEncode(user), 200);
        }));
    addTearDown(api.dispose);
    final auth = AuthService(api, storage);
    addTearDown(auth.dispose);
    await auth.restoreSession();
    await auth.login(' ada@example.com ', 'password');
    expect(storage.sessionToken, 'session');
    final restored = AuthService(api, storage);
    addTearDown(restored.dispose);
    await restored.restoreSession();
    expect(restored.user?.id, 'u1');
    await restored.logout();
    expect(storage.sessionToken, isNull);
    expect(api.sessionToken, isNull);
    expect(restored.user, isNull);
  });

  test('expired saved sessions are removed without leaving a signed in user',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    await storage.saveSession('expired');
    final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((_) async => http.Response('', 401)));
    addTearDown(api.dispose);
    final auth = AuthService(api, storage);
    addTearDown(auth.dispose);
    await auth.restoreSession();
    expect(auth.initialized, isTrue);
    expect(auth.user, isNull);
    expect(storage.sessionToken, isNull);
    expect(api.sessionToken, isNull);
  });

  test(
      'HTTP failures preserve status and malformed success responses are rejected',
      () async {
    final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((request) async => request.url.path == '/failure'
            ? http.Response('{"message":"Forbidden"}', 403)
            : http.Response('<html>invalid</html>', 200)));
    addTearDown(api.dispose);
    await expectLater(
        api.get('/failure'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 403)));
    await expectLater(api.get('/invalid'), throwsA(isA<ApiException>()));
  });

  test(
      'CV validation rejects unsupported, empty, and oversized files before sending',
      () async {
    var calls = 0;
    final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((_) async {
          calls++;
          return http.Response('', 204);
        }));
    addTearDown(api.dispose);
    await expectLater(api.uploadCv('cv.exe', Uint8List.fromList([1])),
        throwsA(isA<ApiException>()));
    await expectLater(
        api.uploadCv('cv.pdf', Uint8List(0)), throwsA(isA<ApiException>()));
    await expectLater(
        api.uploadCv('cv.pdf', Uint8List(AppConstants.maxCvBytes + 1)),
        throwsA(isA<ApiException>()));
    expect(calls, 0);
    await api.uploadCv('cv.pdf', Uint8List.fromList([1, 2, 3]));
    expect(calls, 1);
  });
}
