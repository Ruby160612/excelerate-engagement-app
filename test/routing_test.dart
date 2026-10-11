import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excelerate_talent_hub/models/user.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/utils/app_router.dart';

void main() {
  for (final scenario in [
    ('learner', true, 'Access restricted'),
    ('admin', true, 'Protected content'),
  ]) {
    testWidgets('${scenario.$1} admin-route access is enforced',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ApiService(
          baseUrl: 'https://example.com',
          client: MockClient((_) async => http.Response(
              jsonEncode({
                'token': 'token',
                'user': {
                  'id': 'u1',
                  'name': 'Ada',
                  'email': 'ada@example.com',
                  'role': scenario.$1,
                  'profile_completed': scenario.$2,
                }
              }),
              200)));
      addTearDown(api.dispose);
      final auth = AuthService(
          api, StorageService(await SharedPreferences.getInstance()));
      addTearDown(auth.dispose);
      await auth.restoreSession();
      await auth.login('ada@example.com', 'password');
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(
              home: AuthGuard(
                  role: UserRole.admin,
                  child: Scaffold(body: Text('Protected content'))))));
      await tester.pumpAndSettle();
      expect(find.text(scenario.$3), findsOneWidget);
    });
  }

  testWidgets('learner onboarding is required before private content',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiService(
        baseUrl: 'https://example.com',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'token': 'token',
              'user': {
                'id': 'u1',
                'name': 'Ada',
                'email': 'ada@example.com',
                'role': 'learner',
                'profile_completed': false,
              }
            }),
            200)));
    addTearDown(api.dispose);
    final auth =
        AuthService(api, StorageService(await SharedPreferences.getInstance()));
    addTearDown(auth.dispose);
    await auth.restoreSession();
    await auth.login('ada@example.com', 'password');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(
            home: AuthGuard(
                role: UserRole.learner,
                child: Scaffold(body: Text('Protected content'))))));
    await tester.pumpAndSettle();
    expect(find.text('Create your profile'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });
}
