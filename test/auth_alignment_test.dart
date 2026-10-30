import 'package:excelerate_talent_hub/main.dart';
import 'package:excelerate_talent_hub/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(ExcelerateApp(preferences: preferences));
  await tester.pumpAndSettle();
}

void main() {
  group('Validators', () {
    test('email accepts normal addresses and rejects blank or malformed ones',
        () {
      expect(Validators.email('member@example.com'), isNull);
      expect(Validators.email('  member@example.com  '), isNull);
      expect(Validators.email(null), 'Enter a valid email');
      expect(Validators.email(''), 'Enter a valid email');
      expect(Validators.email('member@'), 'Enter a valid email');
      expect(Validators.email('member example@x.com'), 'Enter a valid email');
    });

    test('password needs a value; length is only checked when asked', () {
      expect(Validators.password(null), 'Enter your password');
      expect(Validators.password(''), 'Enter your password');
      expect(Validators.password('abc12'), isNull);
      expect(Validators.password('abc12', checkLength: true),
          'Use at least 8 characters');
      expect(Validators.password('abc12345', checkLength: true), isNull);
    });

    test('required rejects blank text with the given message', () {
      expect(Validators.required('  ', 'Enter your name'), 'Enter your name');
      expect(Validators.required('Ama', 'Enter your name'), isNull);
    });
  });

  group('Login and Sign Up screens', () {
    testWidgets('both show the same email and password messages',
        (tester) async {
      await _openApp(tester);

      await tester.ensureVisible(find.text('LOGIN'));
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sign Up enforces the 8 character password rule',
        (tester) async {
      await _openApp(tester);
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), 'abc12');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters'), findsOneWidget);
    });

    testWidgets('Forgot Password shows a placeholder message', (tester) async {
      await _openApp(tester);

      await tester.ensureVisible(find.text('Forgot Password?'));
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();
      expect(find.textContaining('Password reset is not available yet'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('both screens link to each other', (tester) async {
      await _openApp(tester);
      expect(find.textContaining("Don't have an account?"), findsOneWidget);

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Already a member?'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back!'), findsOneWidget);
    });
  });
}
