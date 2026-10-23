import 'package:excelerate_talent_hub/main.dart';
import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/models/program_responses.dart';
import 'package:excelerate_talent_hub/services/program_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/utils/constants.dart';
import 'package:excelerate_talent_hub/views/shared/program_details.dart';
import 'package:excelerate_talent_hub/widgets/program_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<NavigatorState> _launch(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(ExcelerateApp(
      preferences: preferences,
      apiBaseUrl: MockApi.baseUrl,
      apiClient: MockApi(latency: Duration.zero).client));
  await tester.pumpAndSettle();
  return tester.state<NavigatorState>(find.byType(Navigator));
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.ensureVisible(find.text('LOGIN'));
  await tester.tap(find.text('LOGIN'));
  await tester.pumpAndSettle();
}

// A transport-free replacement proves the app consumes ProgramService only.
class _ReplacementProgramService implements ProgramService {
  Program _program = Program(
    id: 'replacement-1',
    title: 'Service-supplied course',
    description: 'A replacement source.',
    startDate: DateTime.utc(2027),
    schedule: 'Weekly',
    category: 'course',
  );
  @override
  Future<ProgramListResponse> getPrograms(
          {String? search, String? category}) async =>
      ProgramListResponse([_program]);
  @override
  Future<ProgramDetailResponse> getProgramById(String id) async =>
      ProgramDetailResponse(_program);
  @override
  Future<ProgramRegistrationResponse> registerForProgram(String id) async {
    _program = _program.copyWith(isRegistered: true);
    return ProgramRegistrationResponse(_program);
  }
}

void main() {
  testWidgets(
      'swapping ProgramService supplies list, details, registration and dashboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ExcelerateApp(
      preferences: await SharedPreferences.getInstance(),
      apiBaseUrl: MockApi.baseUrl,
      apiClient: MockApi(latency: Duration.zero).client,
      programService: _ReplacementProgramService(),
    ));
    await tester.pumpAndSettle();
    await _signIn(tester, 'member@example.com', 'member123');
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Registered programs')))
            .data,
        '0');
    await tester.tap(find.text('Explore programs'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsOneWidget);
    expect(find.text('Digital Skills Bootcamp'), findsNothing);
    await tester.tap(find.text('Service-supplied course'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register for Program'));
    await tester.tap(find.text('Register for Program'));
    await tester.pumpAndSettle();
    expect(find.text('You are enrolled in this program'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Register'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('metric-Registered programs')))
            .data,
        '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a learner opens the listing and a card opens its details',
      (tester) async {
    final navigator = await _launch(tester);
    await _signIn(tester, 'member@example.com', 'member123');
    navigator.pushNamed(AppRoutes.programs);
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNWidgets(8));

    await tester.ensureVisible(find.text('CV and Interview Workshop'));
    await tester.tap(find.text('CV and Interview Workshop'));
    await tester.pumpAndSettle();
    final details =
        tester.widget<ProgramDetailsView>(find.byType(ProgramDetailsView));
    expect(details.program.id, 'prog-003');
  });

  testWidgets('an admin can open the listing and a program', (tester) async {
    final navigator = await _launch(tester);
    await _signIn(tester, 'admin@example.com', 'admin123');
    navigator.pushNamed(AppRoutes.programs);
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNWidgets(8));
    expect(find.text('Register'), findsNothing);

    await tester.tap(find.text('Digital Skills Bootcamp'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailsView), findsOneWidget);
  });

  testWidgets('a program opens straight from its id route', (tester) async {
    final navigator = await _launch(tester);
    await _signIn(tester, 'member@example.com', 'member123');
    navigator.pushNamed(AppRoutes.programDetailsFor('prog-007'));
    await tester.pumpAndSettle();
    final details =
        tester.widget<ProgramDetailsView>(find.byType(ProgramDetailsView));
    expect(details.program.title, 'Partner Internship Placement');
  });

  testWidgets('an unknown id shows a clear not found message', (tester) async {
    final navigator = await _launch(tester);
    await _signIn(tester, 'member@example.com', 'member123');
    navigator.pushNamed(AppRoutes.programDetailsFor('does not/exist'));
    await tester.pumpAndSettle();
    expect(find.text('This program could not be found.'), findsOneWidget);
    expect(find.byType(ProgramDetailsView), findsNothing);
  });

  testWidgets('guests are sent to login from the listing and details',
      (tester) async {
    final navigator = await _launch(tester);
    navigator.pushNamed(AppRoutes.programs);
    await tester.pumpAndSettle();
    expect(find.byType(ProgramCard), findsNothing);
    expect(find.text('Welcome Back!'), findsOneWidget);

    navigator.pushNamed(AppRoutes.programDetailsFor('prog-001'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailsView), findsNothing);
    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('the details route without an id shows the not found page',
      (tester) async {
    final navigator = await _launch(tester);
    await _signIn(tester, 'member@example.com', 'member123');
    navigator.pushNamed(AppRoutes.programDetails);
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
    expect(find.byType(ProgramDetailsView), findsNothing);
  });
}
