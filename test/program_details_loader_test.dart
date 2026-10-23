import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/services/mock_data.dart';
import 'package:excelerate_talent_hub/services/program_repository.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/state/program_store.dart';
import 'package:excelerate_talent_hub/utils/themes.dart';
import 'package:excelerate_talent_hub/views/shared/program_details.dart';
import 'package:excelerate_talent_hub/views/shared/program_details_loader.dart';
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

Future<void> _pump(
  WidgetTester tester,
  String programId, {
  http.Client Function(http.Client mock)? wrap,
  Future<List<Map<String, dynamic>>> Function()? programLoader,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final mock =
      MockApi(latency: Duration.zero, programLoader: programLoader).client;
  final api = ApiService(
      baseUrl: MockApi.baseUrl, client: wrap == null ? mock : wrap(mock));
  addTearDown(api.dispose);
  final auth = AuthService(api, StorageService(preferences));
  addTearDown(auth.dispose);
  await auth.login('member@example.com', 'member123');

  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      Provider<ProgramRepository>.value(value: ApiProgramRepository(api)),
      ChangeNotifierProvider<ProgramStore>(
          create: (_) => ProgramStore(ApiProgramRepository(api))),
      ChangeNotifierProvider<AuthService>.value(value: auth),
    ],
    child: MaterialApp(
      theme: AppThemes.light,
      home: ProgramDetailsLoader(programId: programId),
    ),
  ));
}

void main() {
  late List<Map<String, dynamic>> programs;

  setUpAll(() async => programs = await loadMockPrograms());

  testWidgets('shows a spinner while the program loads', (tester) async {
    await _pump(
      tester,
      'prog-001',
      wrap: (mock) => MockClient((request) async {
        if (request.url.path.endsWith('/programs/prog-001')) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return _forward(mock, request);
      }),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProgramDetailsView), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ProgramDetailsView), findsOneWidget);
  });

  testWidgets('a valid id renders the matching program', (tester) async {
    await _pump(tester, 'prog-005');
    await tester.pumpAndSettle();
    final details =
        tester.widget<ProgramDetailsView>(find.byType(ProgramDetailsView));
    expect(details.program.id, 'prog-005');
    expect(find.text('Careers in Tech Webinar'), findsWidgets);
  });

  testWidgets('an unknown id shows not found and a way back', (tester) async {
    await _pump(tester, 'does-not-exist');
    await tester.pumpAndSettle();
    expect(find.text('This program could not be found.'), findsOneWidget);
    expect(find.text('Back to programs'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(ProgramDetailsView), findsNothing);
  });

  testWidgets('a broken record shows the invalid data message', (tester) async {
    await _pump(
      tester,
      'broken',
      programLoader: () async => [
        ...programs,
        {'id': 'broken', 'title': 'No date or category'},
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text("This program's information is incomplete or invalid."),
        findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(ProgramDetailsView), findsNothing);
  });

  testWidgets('a server error offers Retry and recovers', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      'prog-001',
      wrap: (mock) => MockClient((request) async =>
          request.url.path.endsWith('/programs/prog-001') && calls++ == 0
              ? http.Response('{}', 500)
              : _forward(mock, request)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load this program. Please try again.'),
        findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailsView), findsOneWidget);
  });

  testWidgets('a response for a different program is treated as invalid',
      (tester) async {
    await _pump(
      tester,
      'prog-002',
      wrap: (mock) => MockClient((request) async => request.url.path
              .endsWith('/programs/prog-002')
          ? _forward(
              mock,
              http.Request(
                  'GET', request.url.replace(path: '/api/programs/prog-001'))
                ..headers.addAll(request.headers))
          : _forward(mock, request)),
    );
    await tester.pumpAndSettle();
    expect(find.text("This program's information is incomplete or invalid."),
        findsOneWidget);
    expect(find.byType(ProgramDetailsView), findsNothing);
  });
}
