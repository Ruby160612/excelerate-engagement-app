import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/dashboard_announcements.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/dashboard_overview.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) => DashboardLayout(
        title: 'Talent dashboard',
        workspace: 'YOUR LEARNING JOURNEY',
        name: context.watch<AuthService>().user!.name,
        introduction:
            'Build your skills and take the next step in your career.',
        announcements: const DashboardAnnouncements(role: UserRole.learner),
        primaryAction: const DashboardAction(
          title: 'Explore programs',
          description: 'Find your next learning opportunity.',
          route: AppRoutes.programs,
          icon: Icons.school_outlined,
        ),
        overview: const DashboardOverview(metrics: [
          DashboardMetric(
            label: 'Registered programs',
            path: '/programs',
            route: AppRoutes.programs,
            icon: Icons.school_outlined,
            filterField: 'is_registered',
            filterValue: true,
          ),
          DashboardMetric(
            label: 'Your badges',
            path: '/badges/me',
            route: AppRoutes.badges,
            icon: Icons.workspace_premium_outlined,
          ),
          DashboardMetric(
            label: 'Your applications',
            path: '/applications/me',
            route: AppRoutes.applications,
            icon: Icons.work_outline,
          ),
        ]),
        actionsTitle: 'Your next steps',
        actions: const [
          DashboardAction(
            title: 'Development programs',
            description:
                'Discover courses, workshops and career opportunities.',
            route: AppRoutes.programs,
            icon: Icons.school_outlined,
          ),
          DashboardAction(
            title: 'Upload your CV',
            description: 'Share your experience with recruiters.',
            route: AppRoutes.cvUpload,
            icon: Icons.upload_file_outlined,
          ),
          DashboardAction(
            title: 'Assessments',
            description: 'Explore your strengths and track your progress.',
            route: AppRoutes.assessments,
            icon: Icons.quiz_outlined,
          ),
          DashboardAction(
            title: 'Your badges',
            description:
                'Celebrate the skills and achievements you have earned.',
            route: AppRoutes.badges,
            icon: Icons.workspace_premium_outlined,
          ),
          DashboardAction(
            title: 'Your applications',
            description: 'Follow the progress of your submitted applications.',
            route: AppRoutes.applications,
            icon: Icons.work_outline,
          ),
        ],
      );
}
