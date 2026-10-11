import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excelerate_talent_hub/main.dart';
import 'package:excelerate_talent_hub/utils/constants.dart';

void main() {
  testWidgets('guest starts at login and invitation signup validates inputs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ExcelerateApp(preferences: preferences));
    await tester.pumpAndSettle();
    expect(find.text(AppConstants.name), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Have an invitation? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Invitation code'), findsOneWidget);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your invitation code'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct admin route requires a session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ExcelerateApp(preferences: preferences));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.postOpportunity);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Publish opportunity'), findsNothing);
  });
}
