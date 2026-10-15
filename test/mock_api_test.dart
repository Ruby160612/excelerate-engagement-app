import 'package:excelerate_talent_hub/main.dart';
import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApiService _api(MockApi mock) =>
    ApiService(baseUrl: MockApi.baseUrl, client: mock.client);

void main() {
  late MockApi mock;

  setUp(() => mock = MockApi(latency: Duration.zero));

  Future<ApiService> signIn(String email, String password) async {
    final api = _api(mock);
    addTearDown(api.dispose);
    final session = await api
        .post('/auth/login', {'email': email, 'password': password}) as Map;
    api.sessionToken = session['token'] as String;
    return api;
  }

  test('login accepts known accounts and rejects a wrong password', () async {
    final api = _api(mock);
    addTearDown(api.dispose);
    final session = await api.post('/auth/login',
        {'email': 'learner@example.com', 'password': 'learner123'}) as Map;
    expect((session['user'] as Map)['role'], 'learner');
    await expectLater(
        api.post('/auth/login',
            {'email': 'learner@example.com', 'password': 'nope'}),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
  });

  test('protected routes require a token', () async {
    final api = _api(mock);
    addTearDown(api.dispose);
    await expectLater(api.get('/programs'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 401)));
  });

  test('signup needs the invitation code and creates a learner', () async {
    final api = _api(mock);
    addTearDown(api.dispose);
    final body = {
      'name': 'New Person',
      'email': 'new@example.com',
      'password': 'password1',
    };
    await expectLater(
        api.post('/auth/signup', {...body, 'invitation_code': 'wrong'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 400)));
    final session = await api.post('/auth/signup',
        {...body, 'invitation_code': MockApi.invitationCode}) as Map;
    final user = session['user'] as Map;
    expect(user['role'], 'learner');
    expect(user['profile_completed'], false);
  });

  test('saving a profile completes onboarding', () async {
    final api = await signIn('learner@example.com', 'learner123');
    expect((await api.get('/auth/me') as Map)['profile_completed'], false);
    await api.put('/profiles/me', {'headline': 'Student'});
    expect((await api.get('/auth/me') as Map)['profile_completed'], true);
  });

  test('programs list matches the sample data for a learner', () async {
    final api = await signIn('member@example.com', 'member123');
    final programs = (await api.get('/programs') as List)
        .map((json) => Program.fromJson(json as Map<String, dynamic>))
        .toList();
    expect(programs.length, 8);
    expect(
        programs.where((p) => p.isRegistered).map((p) => p.id), ['prog-008']);
    final details = Program.fromJson(
        await api.get('/programs/prog-003') as Map<String, dynamic>);
    expect(details.title, 'CV and Interview Workshop');
    await expectLater(api.get('/programs/missing'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 404)));
  });

  test('registering marks only that program for that learner', () async {
    final learner = await signIn('member@example.com', 'member123');
    final result = Program.fromJson(await learner
        .post('/programs/prog-001/register', {}) as Map<String, dynamic>);
    expect(result.isRegistered, isTrue);
    final list = (await learner.get('/programs') as List)
        .map((json) => Program.fromJson(json as Map<String, dynamic>));
    expect(list.where((p) => p.isRegistered).map((p) => p.id).toSet(),
        {'prog-001', 'prog-008'});

    final other = await signIn('learner@example.com', 'learner123');
    final otherList = (await other.get('/programs') as List)
        .map((json) => Program.fromJson(json as Map<String, dynamic>));
    expect(
        otherList.where((p) => p.isRegistered).map((p) => p.id), ['prog-008']);
  });

  test('admins can read programs but cannot register', () async {
    final admin = await signIn('admin@example.com', 'admin123');
    final list = (await admin.get('/programs') as List)
        .map((json) => Program.fromJson(json as Map<String, dynamic>));
    expect(list.any((p) => p.isRegistered), isFalse);
    await expectLater(admin.post('/programs/prog-001/register', {}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 403)));
  });

  testWidgets('the app signs in through the mock and shows the dashboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ExcelerateApp(
        preferences: preferences,
        apiBaseUrl: MockApi.baseUrl,
        apiClient: mock.client));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'member@example.com');
    await tester.enterText(fields.at(1), 'member123');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Talent dashboard'), findsOneWidget);
    expect(find.text('Hello, Kofi Member'), findsOneWidget);
  });
}
