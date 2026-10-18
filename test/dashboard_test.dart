import 'dart:convert';

import 'package:excelerate_talent_hub/main.dart';
import 'package:excelerate_talent_hub/models/user.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/utils/constants.dart';
import 'package:excelerate_talent_hub/views/admin/dashboard.dart';
import 'package:excelerate_talent_hub/views/learner/dashboard.dart';
import 'package:excelerate_talent_hub/widgets/dashboard_layout.dart';
import 'package:excelerate_talent_hub/widgets/dashboard_announcements.dart';
import 'package:excelerate_talent_hub/widgets/dashboard_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<NavigatorState> _launch(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ExcelerateApp(
    preferences: await SharedPreferences.getInstance(),
    apiBaseUrl: MockApi.baseUrl,
    apiClient: MockApi(latency: Duration.zero).client,
  ));
  await tester.pumpAndSettle();
  return tester.state<NavigatorState>(find.byType(Navigator));
}

Future<void> _signIn(WidgetTester tester, String account) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), '$account@example.com');
  await tester.enterText(fields.at(1), '${account}123');
  await tester.ensureVisible(find.text('LOGIN'));
  await tester.tap(find.text('LOGIN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('learner login shows personal counts and opens programs',
      (tester) async {
    await _launch(tester);
    await _signIn(tester, 'member');
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.byType(AdminDashboardView), findsNothing);
    expect(find.text('Hello, Kofi Member'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Registered programs')))
            .data,
        '1');
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Your applications')))
            .data,
        '0');
    expect(find.text('Review applications'), findsNothing);

    await tester.tap(find.text('Explore programs'));
    await tester.pumpAndSettle();
    expect(find.text('Digital Skills Bootcamp'), findsOneWidget);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Registered programs')))
            .data,
        '2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin login shows recruitment home and opens opportunity form',
      (tester) async {
    await _launch(tester);
    await _signIn(tester, 'admin');
    expect(find.byType(AdminDashboardView), findsOneWidget);
    expect(find.byType(DashboardView), findsNothing);
    expect(find.text('Hello, Zainab Admin'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Applications received')))
            .data,
        '0');
    expect(find.text('Upload your CV'), findsNothing);
    await tester.tap(find.text('Post an opportunity').first);
    await tester.pumpAndSettle();
    expect(find.text('Publish opportunity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home routes enforce roles and sign out returns to login',
      (tester) async {
    final navigator = await _launch(tester);
    navigator.pushNamed(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    await _signIn(tester, 'member');
    navigator.pushNamed(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();
    expect(find.text('Access restricted'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
    await _signIn(tester, 'admin');
    navigator.pushNamed(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    expect(find.text('Access restricted'), findsOneWidget);
    navigator.pop();
    navigator.pushNamed(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new learner completes profile setup before seeing home',
      (tester) async {
    await _launch(tester);
    await _signIn(tester, 'learner');
    expect(find.text('Create your profile'), findsOneWidget);
    expect(find.byType(DashboardView), findsNothing);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Developer');
    await tester.enterText(fields.at(1), 'Learning to build useful apps.');
    await tester.enterText(fields.at(2), 'Flutter, Dart');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.text('Hello, Ada Learner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final account in ['member', 'admin']) {
    testWidgets('$account home has announcements and a working Programs menu',
        (tester) async {
      await _launch(tester);
      await _signIn(tester, account);
      expect(find.text('Welcome back to Excelerate'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Quick links'), findsOneWidget);
      expect(find.text('Welcome to your Excelerate community'), findsOneWidget);
      expect(
          find.text(account == 'admin'
              ? 'Keep your recruitment moving'
              : 'Make your next career move'),
          findsOneWidget);
      expect(
          find.text(account == 'admin'
              ? 'Make your next career move'
              : 'Keep your recruitment moving'),
          findsNothing);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final menuPrograms = find.descendant(
          of: find.byType(Drawer), matching: find.text('Programs'));
      await tester.tap(menuPrograms);
      await tester.pumpAndSettle();
      expect(find.text('Digital Skills Bootcamp'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardLayout), findsOneWidget);
      await tester.ensureVisible(find.text('Programs'));
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();
      expect(find.text('Digital Skills Bootcamp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saved $account session restores the correct home',
        (tester) async {
      final mock = MockApi(latency: Duration.zero);
      final client = mock.client;
      final response = await client.post(
        Uri.parse('${MockApi.baseUrl}/auth/login'),
        body: jsonEncode({
          'email': '$account@example.com',
          'password': '${account}123',
        }),
      );
      final token = (jsonDecode(response.body) as Map)['token'];
      SharedPreferences.setMockInitialValues(
          {'excelerate.session.token': token});
      await tester.pumpWidget(ExcelerateApp(
        preferences: await SharedPreferences.getInstance(),
        apiBaseUrl: MockApi.baseUrl,
        apiClient: client,
      ));
      await tester.pumpAndSettle();
      expect(
          find.byType(account == 'admin' ? AdminDashboardView : DashboardView),
          findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$account home fits narrow screens with enlarged text',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _launch(tester);
      await _signIn(tester, account);
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      expect(find.byType(DashboardLayout), findsOneWidget);
      final lastAction = find
          .text(
              account == 'admin' ? 'Development programs' : 'Your applications')
          .last;
      await tester.ensureVisible(lastAction);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('announcements can retry errors and show an empty state',
      (tester) async {
    var fail = true;
    final api = ApiService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async =>
          fail ? http.Response('{}', 500) : http.Response('[]', 200)),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(Provider.value(
      value: api,
      child: const MaterialApp(
          home: Scaffold(body: DashboardAnnouncements(role: UserRole.learner))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load announcements.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry announcements'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You’re all caught up.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announcements filter audiences, sort dates and expand',
      (tester) async {
    final api = ApiService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async => http.Response(
          jsonEncode([
            for (var day = 1; day <= 5; day++)
              {
                'id': '$day',
                'title': 'Notice $day',
                'body': 'Message $day',
                'published_at': '2026-10-0${day}T09:00:00Z',
                'audience': day == 5
                    ? 'admin'
                    : day == 4
                        ? 'all'
                        : 'learner',
              },
          ]),
          200)),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(Provider.value(
      value: api,
      child: const MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: DashboardAnnouncements(role: UserRole.learner)))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Notice 5'), findsNothing);
    expect(find.text('Notice 1'), findsNothing);
    expect(tester.getTopLeft(find.text('Notice 4')).dy,
        lessThan(tester.getTopLeft(find.text('Notice 3')).dy));
    await tester.ensureVisible(find.text('View all announcements (4)'));
    await tester.tap(find.text('View all announcements (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Notice 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Show fewer announcements'));
    await tester.tap(find.text('Show fewer announcements'));
    await tester.pumpAndSettle();
    expect(find.text('Notice 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview retries failures and shares collection requests',
      (tester) async {
    var fail = true;
    var requests = 0;
    final api = ApiService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async {
        requests++;
        return fail
            ? http.Response('{}', 500)
            : http.Response(
                jsonEncode([
                  {'status': 'submitted'},
                  {'status': 'shortlisted'},
                  {'status': 'shortlisted'},
                ]),
                200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(Provider.value(
      value: api,
      child: const MaterialApp(
          home: Scaffold(
              body: DashboardOverview(metrics: [
        DashboardMetric(
          label: 'All',
          path: '/applications',
          route: '/all',
          icon: Icons.inbox,
        ),
        DashboardMetric(
          label: 'Shortlisted',
          path: '/applications',
          route: '/shortlist',
          icon: Icons.people,
          filterField: 'status',
          filterValue: 'shortlisted',
        ),
      ]))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Retry overview'), findsOneWidget);
    expect(find.byKey(const ValueKey('metric-All')), findsNothing);
    expect(requests, 1);
    fail = false;
    await tester.tap(find.text('Retry overview'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('metric-All'))).data,
        '3');
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('metric-Shortlisted')))
            .data,
        '2');
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });
}
