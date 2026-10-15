import 'dart:convert';

import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/utils/constants.dart';
import 'package:excelerate_talent_hub/utils/themes.dart';
import 'package:excelerate_talent_hub/views/learner/programs_list.dart';
import 'package:excelerate_talent_hub/widgets/program_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<http.Response> _forward(http.Client target, http.Request request) async {
  final copy = http.Request(request.method, request.url)
    ..headers.addAll(request.headers)
    ..body = request.body;
  return http.Response.fromStream(await target.send(copy));
}

const _learner = ('member@example.com', 'member123');
const _admin = ('admin@example.com', 'admin123');

Future<void> _pump(
  WidgetTester tester, {
  (String, String) account = _learner,
  http.Client Function(http.Client mock)? wrap,
  Size size = const Size(360, 800),
  double textScale = 1,
  void Function(RouteSettings)? onRoute,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final mock = MockApi(latency: Duration.zero).client;
  final api = ApiService(
      baseUrl: MockApi.baseUrl, client: wrap == null ? mock : wrap(mock));
  addTearDown(api.dispose);
  final auth = AuthService(api, StorageService(preferences));
  addTearDown(auth.dispose);
  await auth.login(account.$1, account.$2);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      ChangeNotifierProvider<AuthService>.value(value: auth),
    ],
    child: MaterialApp(
      theme: AppThemes.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const ProgramsListView(),
      onGenerateRoute: (settings) {
        onRoute?.call(settings);
        return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Details page')));
      },
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every program as a card', (tester) async {
    await _pump(tester);
    expect(find.byType(ProgramCard), findsNWidgets(8));
    expect(find.text('Digital Skills Bootcamp'), findsOneWidget);
    expect(find.text('Nov 3, 2026'), findsOneWidget);
  });

  testWidgets('search narrows the list and reports no matches', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'internship');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsOneWidget);
    expect(find.text('Partner Internship Placement'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNothing);
    expect(find.text('No programs match your search.'), findsOneWidget);
  });

  testWidgets('category chips filter and All resets', (tester) async {
    await _pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Workshop'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNWidgets(8));
  });

  testWidgets('learner can register and the card switches to View',
      (tester) async {
    await _pump(tester);
    expect(find.text('Register'), findsNWidgets(7));
    expect(find.text('View'), findsOneWidget);
    await tester.ensureVisible(find.text('Register').first);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    expect(find.text('Register'), findsNWidgets(6));
    expect(find.text('View'), findsNWidgets(2));
  });

  testWidgets('a failed registration keeps Register and shows a message',
      (tester) async {
    await _pump(
      tester,
      wrap: (mock) => MockClient((request) async =>
          request.url.path.endsWith('/register')
              ? http.Response(jsonEncode({'message': 'Closed'}), 500)
              : _forward(mock, request)),
    );
    await tester.ensureVisible(find.text('Register').first);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    expect(find.text('Register'), findsNWidgets(7));
    expect(find.text('Unable to register. Please try again.'), findsOneWidget);
  });

  testWidgets('admins only see View', (tester) async {
    await _pump(tester, account: _admin);
    expect(find.text('Register'), findsNothing);
    expect(find.text('View'), findsNWidgets(8));
  });

  testWidgets('tapping a card opens details with the selected program',
      (tester) async {
    RouteSettings? pushed;
    await _pump(tester, onRoute: (settings) => pushed = settings);
    await tester.tap(find.text('Digital Skills Bootcamp'));
    await tester.pumpAndSettle();
    expect(pushed?.name, AppRoutes.programDetails);
    expect((pushed?.arguments as Program).id, 'prog-001');
    expect(find.text('Details page'), findsOneWidget);
  });

  testWidgets('load failure shows retry and recovers', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      wrap: (mock) => MockClient((request) async =>
          request.url.path.endsWith('/programs') && calls++ == 0
              ? http.Response('{}', 500)
              : _forward(mock, request)),
    );
    expect(find.text('Unable to load this page. Please try again.'),
        findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNWidgets(8));
  });

  testWidgets('empty list shows the empty message', (tester) async {
    await _pump(
      tester,
      wrap: (mock) => MockClient((request) async =>
          request.url.path.endsWith('/programs')
              ? http.Response('[]', 200)
              : _forward(mock, request)),
    );
    expect(find.text('New development programs will appear here.'),
        findsOneWidget);
  });

  for (final size in const [Size(320, 640), Size(360, 800), Size(430, 932)]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}'
          ' with text scale $scale', (tester) async {
        await _pump(tester, size: size, textScale: scale);
        expect(find.byType(ProgramCard), findsNWidgets(8));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
