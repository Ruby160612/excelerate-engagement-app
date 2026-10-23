import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/models/user.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/auth_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/services/program_repository.dart';
import 'package:excelerate_talent_hub/services/storage_service.dart';
import 'package:excelerate_talent_hub/state/program_store.dart';
import 'package:excelerate_talent_hub/utils/themes.dart';
import 'package:excelerate_talent_hub/views/shared/program_details.dart';
import 'package:excelerate_talent_hub/widgets/app_button.dart';
import 'package:excelerate_talent_hub/widgets/app_card.dart';
import 'package:excelerate_talent_hub/widgets/empty_state.dart';
import 'package:excelerate_talent_hub/widgets/section_container.dart';
import 'package:excelerate_talent_hub/widgets/status_badge.dart';

void main() {
  group('Design System & Themes', () {
    test('AppColors preserves Excelerate orange and defines semantic palette',
        () {
      expect(AppColors.primary, const Color(0xFFFF4500));
      expect(AppColors.primaryLight, const Color(0xFFFFF0E8));
      expect(AppColors.background, const Color(0xFFF6F7FB));
      expect(AppColors.surface, Colors.white);
      expect(AppColors.border, const Color(0xFFE2E5ED));
      expect(AppColors.success, const Color(0xFF12B76A));
      expect(AppColors.warning, const Color(0xFFF79009));
      expect(AppColors.error, const Color(0xFFD92D20));
      expect(AppColors.info, const Color(0xFF0BA5EC));
    });

    test('AppThemes.light provides consistent Material 3 styling', () {
      final theme = AppThemes.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.inputDecorationTheme.filled, isTrue);
    });
  });

  group('Shared UI Components', () {
    testWidgets('AppButton primary variant triggers tap and displays loading',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: AppButton(
            label: 'Submit Application',
            onPressed: () => tapped = true,
          ),
        ),
      ));

      expect(find.text('Submit Application'), findsOneWidget);
      await tester.tap(find.text('Submit Application'));
      expect(tapped, isTrue);

      // Loading state
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: AppButton(
            label: 'Submit Application',
            loading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Application'), findsNothing);
    });

    testWidgets('AppButton secondary and outlined variants render properly',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: const Scaffold(
          body: Column(
            children: [
              AppButton.secondary(
                label: 'Secondary Action',
                icon: Icons.star,
              ),
              AppButton.outlined(
                label: 'Outlined Action',
                icon: Icons.file_download,
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.text('Outlined Action'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets(
        'AppCard renders icon, title, subtitle, status badge, and responds to tap',
        (tester) async {
      var cardTapped = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: AppCard(
            title: 'Technical Assessment',
            subtitle: '60 minutes • Score: 95',
            icon: Icons.quiz_outlined,
            statusBadge: const StatusBadge.success(label: 'Passed'),
            onTap: () => cardTapped = true,
          ),
        ),
      ));

      expect(find.text('Technical Assessment'), findsOneWidget);
      expect(find.text('60 minutes • Score: 95'), findsOneWidget);
      expect(find.text('Passed'), findsOneWidget);
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);

      await tester.tap(find.text('Technical Assessment'));
      expect(cardTapped, isTrue);
    });

    testWidgets('StatusBadge displays correct labels and icons across types',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: const Scaffold(
          body: Column(
            children: [
              StatusBadge.success(label: 'Accepted'),
              StatusBadge.warning(label: 'Pending Review'),
              StatusBadge.error(label: 'Rejected'),
              StatusBadge.info(label: 'New'),
              StatusBadge.primary(label: 'Workshop'),
            ],
          ),
        ),
      ));

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);
    });

    testWidgets('EmptyStateWidget renders icon, title, message and button',
        (tester) async {
      var retryTapped = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: Scaffold(
          body: EmptyStateWidget(
            title: 'No Applications',
            message: 'You have not submitted any applications yet.',
            icon: Icons.inbox_outlined,
            actionLabel: 'Browse Jobs',
            onAction: () => retryTapped = true,
          ),
        ),
      ));

      expect(find.text('No Applications'), findsOneWidget);
      expect(find.text('You have not submitted any applications yet.'),
          findsOneWidget);
      expect(find.text('Browse Jobs'), findsOneWidget);

      await tester.tap(find.text('Browse Jobs'));
      expect(retryTapped, isTrue);
    });

    testWidgets('SectionContainer renders title, subtitle, and child',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.light,
        home: const Scaffold(
          body: SectionContainer(
            title: 'Key Milestones',
            subtitle: 'Track your career achievements',
            child: Text('Milestone Content'),
          ),
        ),
      ));

      expect(find.text('Key Milestones'), findsOneWidget);
      expect(find.text('Track your career achievements'), findsOneWidget);
      expect(find.text('Milestone Content'), findsOneWidget);
    });
  });

  group('Program Details View & Registration', () {
    final sampleProgram = Program(
      id: 'prog-001',
      title: 'Digital Skills Bootcamp',
      description: 'Build the everyday digital skills employers expect.',
      startDate: DateTime.parse('2026-11-03T09:00:00Z'),
      endDate: DateTime.parse('2026-12-18T17:00:00Z'),
      schedule: 'Tuesdays and Thursdays, 5:00 PM to 7:00 PM',
      category: 'course',
      eligibility: ['Aged 18 to 30', 'Completed Excelerate onboarding'],
      outcomes: ['Certificate of completion', 'Digital skills badge'],
      isRegistered: false,
    );

    Future<void> pumpDetails(
      WidgetTester tester, {
      required Program program,
      required UserRole role,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final mock = MockApi(latency: Duration.zero);
      final api = ApiService(baseUrl: MockApi.baseUrl, client: mock.client);
      addTearDown(api.dispose);
      final auth = AuthService(api, StorageService(preferences));
      addTearDown(auth.dispose);
      await auth.login(
        role == UserRole.admin ? 'admin@example.com' : 'member@example.com',
        role == UserRole.admin ? 'admin123' : 'member123',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            Provider<ProgramRepository>.value(value: ApiProgramRepository(api)),
            ChangeNotifierProvider<ProgramStore>(
              create: (context) =>
                  ProgramStore(context.read<ProgramRepository>()),
            ),
            ChangeNotifierProvider<AuthService>.value(value: auth),
          ],
          child: MaterialApp(
            theme: AppThemes.light,
            home: ProgramDetailsView(program: program),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders complete program information and learning outcomes',
        (tester) async {
      await pumpDetails(tester, program: sampleProgram, role: UserRole.learner);

      expect(find.text('Digital Skills Bootcamp'), findsNWidgets(2));
      expect(find.text('Build the everyday digital skills employers expect.'),
          findsOneWidget);
      expect(find.text('Tuesdays and Thursdays, 5:00 PM to 7:00 PM'),
          findsOneWidget);
      expect(find.text('Aged 18 to 30'), findsOneWidget);
      expect(find.text('Completed Excelerate onboarding'), findsOneWidget);
      expect(find.text('Certificate of completion'), findsOneWidget);
      expect(find.text('Digital skills badge'), findsOneWidget);
      expect(find.text('Register for Program'), findsOneWidget);
    });

    testWidgets('learner can register from program details and status updates',
        (tester) async {
      await pumpDetails(tester, program: sampleProgram, role: UserRole.learner);

      expect(find.text('Register for Program'), findsOneWidget);
      await tester.ensureVisible(find.text('Register for Program'));
      await tester.tap(find.text('Register for Program'));
      await tester.pumpAndSettle();

      expect(find.text('You are enrolled in this program'), findsOneWidget);
      expect(find.text('Register for Program'), findsNothing);
    });

    testWidgets(
        'admin view displays preview mode without learner register button',
        (tester) async {
      await pumpDetails(tester, program: sampleProgram, role: UserRole.admin);

      expect(find.text('Admin Preview'), findsOneWidget);
      expect(find.text('Register for Program'), findsNothing);
      expect(
          find.text(
              'Learners can register for this program from their portal.'),
          findsOneWidget);
    });
  });
}
