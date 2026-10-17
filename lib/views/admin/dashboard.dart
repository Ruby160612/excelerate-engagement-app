import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/dashboard_announcements.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/dashboard_overview.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) => DashboardLayout(
        title: 'Recruitment workspace',
        workspace: 'ADMIN WORKSPACE',
        name: context.watch<AuthService>().user!.name,
        introduction:
            'Connect with talent and help your next great hire take the next step.',
        announcements: const DashboardAnnouncements(role: UserRole.admin),
        primaryAction: const DashboardAction(
          title: 'Post an opportunity',
          description: 'Connect talent to a new role.',
          route: AppRoutes.postOpportunity,
          icon: Icons.add,
        ),
        overview: const DashboardOverview(metrics: [
          DashboardMetric(
            label: 'Applications received',
            path: '/applications',
            route: AppRoutes.applicationReview,
            icon: Icons.inbox_outlined,
          ),
          DashboardMetric(
            label: 'Shortlisted candidates',
            path: '/applications',
            route: AppRoutes.candidateShortlisting,
            icon: Icons.people_outline,
            filterField: 'status',
            filterValue: 'shortlisted',
          ),
        ]),
        actionsTitle: 'Manage recruitment',
        actions: const [
          DashboardAction(
            title: 'Post an opportunity',
            description:
                'Create a role and share what your team is looking for.',
            route: AppRoutes.postOpportunity,
            icon: Icons.work_outline,
          ),
          DashboardAction(
            title: 'Review applications',
            description:
                'Review submissions and identify promising candidates.',
            route: AppRoutes.applicationReview,
            icon: Icons.inbox_outlined,
          ),
          DashboardAction(
            title: 'Candidate shortlist',
            description: 'See the candidates selected for the next stage.',
            route: AppRoutes.candidateShortlisting,
            icon: Icons.people_outline,
          ),
          DashboardAction(
            title: 'Schedule an interview',
            description: 'Arrange the next conversation with a candidate.',
            route: AppRoutes.interviewScheduler,
            icon: Icons.calendar_month_outlined,
          ),
          DashboardAction(
            title: 'Development programs',
            description:
                'Browse the learning opportunities available to talent.',
            route: AppRoutes.programs,
            icon: Icons.school_outlined,
          ),
        ],
      );
}
