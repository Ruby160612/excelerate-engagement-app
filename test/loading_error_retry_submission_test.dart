import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/state/submission_controller.dart';
import 'package:excelerate_talent_hub/utils/themes.dart';
import 'package:excelerate_talent_hub/views/learner/feedback.dart';
import 'package:excelerate_talent_hub/widgets/api_collection_view.dart';
import 'package:excelerate_talent_hub/widgets/api_form.dart';
import 'package:excelerate_talent_hub/widgets/app_button.dart';
import 'package:excelerate_talent_hub/widgets/auth_form.dart';
import 'package:excelerate_talent_hub/widgets/empty_state.dart';
import 'package:excelerate_talent_hub/widgets/error_card.dart';

Future<Widget> _createAppWithAuth({
  required ApiService api,
  required Widget child,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final auth = AuthService(api, storage);
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      ChangeNotifierProvider<AuthService>.value(value: auth),
    ],
    child: MaterialApp(
      theme: AppThemes.light,
      home: child,
    ),
  );
}

void main() {
  group('SubmissionController', () {
    test('initial state is idle and canSubmit is true', () {
      final controller = SubmissionController(
        initialValues: {'name': 'Ada'},
      );
      addTearDown(controller.dispose);

      expect(controller.status, SubmissionStatus.idle);
      expect(controller.isIdle, isTrue);
      expect(controller.isSubmitting, isFalse);
      expect(controller.isSuccess, isFalse);
      expect(controller.isError, isFalse);
      expect(controller.canSubmit, isTrue);
      expect(controller.valueOf('name'), 'Ada');
    });

    test('validation failure sets error status and retains values', () async {
      final controller = SubmissionController(
        initialValues: {'email': 'invalid-email'},
        validators: {
          'email': (v) => v.contains('@') ? null : 'Enter a valid email',
        },
      );
      addTearDown(controller.dispose);

      var actionCalled = false;
      final result = await controller.submit((values) async {
        actionCalled = true;
      });

      expect(result, isFalse);
      expect(actionCalled, isFalse);
      expect(controller.status, SubmissionStatus.error);
      expect(controller.isError, isTrue);
      expect(controller.errorOf('email'), 'Enter a valid email');
      expect(controller.message, 'Please fix the highlighted fields.');
      // Values are preserved
      expect(controller.valueOf('email'), 'invalid-email');
      // User can submit again once field is corrected
      expect(controller.canSubmit, isTrue);
    });

    test('failed submissions retain user input and preserve diagnostics',
        () async {
      final controller = SubmissionController(
        initialValues: {'title': 'Senior Engineer', 'location': 'Remote'},
      );
      addTearDown(controller.dispose);

      final result = await controller.submit((values) async {
        throw const ApiException('Server rejected request', statusCode: 500);
      });

      expect(result, isFalse);
      expect(controller.status, SubmissionStatus.error);
      expect(controller.isError, isTrue);
      expect(controller.message, 'Server rejected request');
      expect(controller.rawError, isA<ApiException>());
      // Input values are preserved!
      expect(controller.valueOf('title'), 'Senior Engineer');
      expect(controller.valueOf('location'), 'Remote');
      expect(controller.canSubmit, isTrue);
      expect(controller.canRetry, isTrue);
    });

    test('prevents duplicate submissions while in-flight and after success',
        () async {
      final controller = SubmissionController(
        initialValues: {'note': 'Important'},
      );
      addTearDown(controller.dispose);

      final completer = Completer<void>();
      var runCount = 0;

      final firstSubmission = controller.submit((_) async {
        runCount++;
        await completer.future;
      });

      expect(controller.isSubmitting, isTrue);
      expect(controller.canSubmit, isFalse);

      // Attempting second submission while in-flight must be rejected
      final secondSubmission = controller.submit((_) async {
        runCount++;
      });

      expect(await secondSubmission, isFalse);
      expect(runCount, 1);

      completer.complete();
      expect(await firstSubmission, isTrue);

      expect(controller.status, SubmissionStatus.success);
      expect(controller.isSuccess, isTrue);
      expect(controller.canSubmit, isFalse);

      // Attempting submission after success is also rejected
      final thirdSubmission = controller.submit((_) async {
        runCount++;
      });
      expect(await thirdSubmission, isFalse);
      expect(runCount, 1);
    });

    test('freezes field values during submission', () async {
      final controller = SubmissionController(
        initialValues: {'content': 'Original'},
      );
      addTearDown(controller.dispose);

      final completer = Completer<void>();
      final submission = controller.submit((_) async {
        await completer.future;
      });

      expect(controller.isSubmitting, isTrue);
      controller.setValue('content', 'Modified While Submitting');
      expect(controller.valueOf('content'), 'Original');

      completer.complete();
      await submission;
    });

    test('retry executes previous action upon failure', () async {
      final controller = SubmissionController(
        initialValues: {'feedback': 'Great app'},
      );
      addTearDown(controller.dispose);

      var attempts = 0;
      Future<void> action(Map<String, String> values) async {
        attempts++;
        if (attempts == 1) throw const ApiException('Network timeout');
      }

      final firstTry = await controller.submit(action);
      expect(firstTry, isFalse);
      expect(controller.isError, isTrue);
      expect(attempts, 1);

      final retryResult = await controller.retry();
      expect(retryResult, isTrue);
      expect(controller.isSuccess, isTrue);
      expect(attempts, 2);
    });

    test('setValue and clearError restore form to idle state', () {
      final controller = SubmissionController(
        initialValues: {'field': 'val'},
        validators: {'field': (_) => 'Error message'},
      );
      addTearDown(controller.dispose);

      controller.submit((_) async {});
      expect(controller.isError, isTrue);

      controller.setValue('field', 'new-val');
      expect(controller.isIdle, isTrue);
      expect(controller.message, isNull);
      expect(controller.errorOf('field'), isNull);
      expect(controller.valueOf('field'), 'new-val');
    });

    test('describe sanitizes technical network exceptions', () {
      expect(
        SubmissionController.describe(
          const ApiException('Specific business rule violation'),
        ),
        'Specific business rule violation',
      );
      expect(
        SubmissionController.describe(
          Exception('SocketException: Connection refused (OS Error: 111)'),
        ),
        'Unable to connect to the service. Please check your connection and try again.',
      );
      expect(
        SubmissionController.describe(
          Exception('ClientException: Software caused connection abort'),
        ),
        'Unable to connect to the service. Please check your connection and try again.',
      );
      expect(
        SubmissionController.describe(
          Exception('Something understandable'),
        ),
        'Something understandable',
      );
    });
  });

  group('ApiCollectionView UX Layer', () {
    testWidgets('shows loading indicator, then items on success',
        (tester) async {
      final completer = Completer<http.Response>();
      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) => completer.future),
      );
      addTearDown(api.dispose);

      final app = await _createAppWithAuth(
        api: api,
        child: ApiCollectionView(
          title: 'Test Items',
          path: '/items',
          emptyMessage: 'No items found.',
          itemBuilder: (item) => Text(item['name'] as String),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(http.Response(
        jsonEncode([
          {'name': 'Item 1'},
          {'name': 'Item 2'},
        ]),
        200,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('shows ErrorCard on failure and recovers via Retry button',
        (tester) async {
      var calls = 0;
      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response('{"message":"Database down"}', 500);
          }
          return http.Response(
            jsonEncode([
              {'name': 'Recovered Item'},
            ]),
            200,
          );
        }),
      );
      addTearDown(api.dispose);

      final app = await _createAppWithAuth(
        api: api,
        child: ApiCollectionView(
          title: 'Test Items',
          path: '/items',
          emptyMessage: 'No items found.',
          itemBuilder: (item) => Text(item['name'] as String),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorCard), findsOneWidget);
      expect(find.text('Database down'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorCard), findsNothing);
      expect(find.text('Recovered Item'), findsOneWidget);
    });

    testWidgets('shows EmptyStateWidget when empty response returned',
        (tester) async {
      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      addTearDown(api.dispose);

      final app = await _createAppWithAuth(
        api: api,
        child: ApiCollectionView(
          title: 'Test Items',
          path: '/items',
          emptyMessage: 'No test items available yet.',
          itemBuilder: (item) => Text(item['name'] as String),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No test items available yet.'), findsOneWidget);
    });
  });

  group('ApiForm Submission UX Layer', () {
    testWidgets(
        'disables inputs during submission, shows spinner, and prevents duplicates',
        (tester) async {
      final completer = Completer<http.Response>();
      var postCount = 0;

      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) {
          postCount++;
          return completer.future;
        }),
      );
      addTearDown(api.dispose);

      final app = await _createAppWithAuth(
        api: api,
        child: const ApiForm(
          title: 'Schedule Interview',
          path: '/schedule',
          fields: {'notes': 'Notes'},
          dateKey: 'date',
          dateLabel: 'Pick Date',
          submitLabel: 'Submit Schedule',
          successMessage: 'Scheduled successfully!',
          initialValues: {'notes': 'Candidate Notes'},
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Pick future date
      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Submit Schedule'));
      await tester.pump();

      // Loading state: AppButton shows progress spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Form controls disabled
      final textFormField =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textFormField.enabled, isFalse);

      // Rapid tap to verify duplicate prevention
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(postCount, 1);

      // Complete request
      completer.complete(http.Response('{}', 200));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Scheduled successfully!'), findsOneWidget);
    });

    testWidgets(
        'preserves user input on submission failure and provides retry',
        (tester) async {
      var calls = 0;
      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response('{"message":"Slot is full"}', 409);
          }
          return http.Response('{}', 200);
        }),
      );
      addTearDown(api.dispose);

      final app = await _createAppWithAuth(
        api: api,
        child: const ApiForm(
          title: 'Schedule Interview',
          path: '/schedule',
          fields: {'notes': 'Notes'},
          dateKey: 'date',
          dateLabel: 'Pick Date',
          submitLabel: 'Submit Schedule',
          successMessage: 'Scheduled successfully!',
          initialValues: {'notes': 'Important meeting notes'},
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Pick date
      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Submit Schedule'));
      await tester.pumpAndSettle();

      // Failed submission preserves user input
      expect(find.text('Important meeting notes'), findsOneWidget);
      expect(find.text('Slot is full'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Retrying succeeds
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Scheduled successfully!'), findsOneWidget);
    });
  });

  group('FeedbackPage Submission UX Layer', () {
    testWidgets('disables inputs while submitting and shows loading spinner',
        (tester) async {
      final completer = Completer<void>();
      var submitted = false;

      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: FeedbackPage(
          onSubmit: (_) async {
            submitted = true;
            await completer.future;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Fill valid inputs
      await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'learner@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField,
              'Tell us what happened or what you\'d like to see...'),
          'The workshop was insightful and very engaging.');
      await tester.pumpAndSettle();

      // Tap submit
      await tester.ensureVisible(find.text('SUBMIT FEEDBACK'));
      await tester.tap(find.text('SUBMIT FEEDBACK'));
      await tester.pump();

      expect(submitted, isTrue);
      // Loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify controls are disabled during submission
      final emailField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'learner@example.com'));
      expect(emailField.enabled, isFalse);

      final commentsField = tester.widget<TextFormField>(find.widgetWithText(
          TextFormField, 'The workshop was insightful and very engaging.'));
      expect(commentsField.enabled, isFalse);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Thank you! Your feedback has been submitted.'),
          findsOneWidget);
    });

    testWidgets('failed submission retains input and provides in-form retry',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: FeedbackPage(
          onSubmit: (_) async {
            calls++;
            if (calls == 1) {
              throw const ApiException('Network error: server unreachable');
            }
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField,
              'Tell us what happened or what you\'d like to see...'),
          'Detailed constructive feedback.');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SUBMIT FEEDBACK'));
      await tester.tap(find.text('SUBMIT FEEDBACK'));
      await tester.pumpAndSettle();

      // Input retained
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Detailed constructive feedback.'), findsOneWidget);

      // Error message and retry option available
      expect(find.text('Network error: server unreachable'), findsWidgets);
      expect(find.text('Retry'), findsWidgets);

      // Tapping retry re-executes submission
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Thank you! Your feedback has been submitted.'),
          findsOneWidget);
    });
  });

  group('AuthForm UX Layer', () {
    testWidgets('disables inputs during submission and shows loading spinner',
        (tester) async {
      final completer = Completer<http.Response>();
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) => completer.future),
      );
      addTearDown(api.dispose);
      final auth = AuthService(api, StorageService(preferences));
      addTearDown(auth.dispose);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthService>.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppThemes.light,
          home: const Scaffold(body: AuthForm()),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'member@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      // Spinner active
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Fields disabled
      final emailField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'member@example.com'));
      expect(emailField.enabled, isFalse);

      completer.complete(http.Response(
        jsonEncode({
          'token': 'tok',
          'user': {
            'id': 'u1',
            'name': 'Ada',
            'email': 'member@example.com',
            'role': 'learner',
            'profile_completed': true,
          }
        }),
        200,
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('preserves input on failure and provides retry',
        (tester) async {
      var calls = 0;
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final api = ApiService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response(
                jsonEncode({'message': 'Invalid credentials'}), 401);
          }
          return http.Response(
            jsonEncode({
              'token': 'tok',
              'user': {
                'id': 'u1',
                'name': 'Ada',
                'email': 'member@example.com',
                'role': 'learner',
                'profile_completed': true,
              }
            }),
            200,
          );
        }),
      );
      addTearDown(api.dispose);
      final auth = AuthService(api, StorageService(preferences));
      addTearDown(auth.dispose);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthService>.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppThemes.light,
          home: const Scaffold(body: AuthForm()),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'member@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Inputs preserved
      expect(find.text('member@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });
  });

  group('ErrorCard UI Component', () {
    testWidgets('renders title, message, and triggers onRetry', (tester) async {
      var retryClicked = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: ErrorCard(
            title: 'Failed to connect',
            message: 'Unable to reach backend servers.',
            onRetry: () => retryClicked = true,
          ),
        ),
      ));

      expect(find.text('Failed to connect'), findsOneWidget);
      expect(find.text('Unable to reach backend servers.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });

    testWidgets('compact mode renders inline alert with retry', (tester) async {
      var retryClicked = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: ErrorCard(
            isCompact: true,
            message: 'Quick warning notice',
            onRetry: () => retryClicked = true,
          ),
        ),
      ));

      expect(find.text('Quick warning notice'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });
  });
}
