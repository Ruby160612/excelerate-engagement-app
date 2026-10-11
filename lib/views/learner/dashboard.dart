import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_layout.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user!;
    final admin = user.role == UserRole.admin;
    final links = admin
        ? <(String, String, String, IconData)>[
            ('Post an opportunity', 'Connect talent to a new role', AppRoutes.postOpportunity, Icons.work_outline),
            ('Review applications', 'View candidate submissions', AppRoutes.applicationReview, Icons.inbox_outlined),
            ('Candidate shortlist', 'View candidates selected for interview', AppRoutes.candidateShortlisting, Icons.people_outline),
            ('Schedule an interview', 'Arrange the next conversation', AppRoutes.interviewScheduler, Icons.calendar_month_outlined),
          ]
        : <(String, String, String, IconData)>[
            ('Upload your CV', 'Share your experience with recruiters', AppRoutes.cvUpload, Icons.upload_file_outlined),
            ('Development programs', 'Discover learning opportunities', AppRoutes.programs, Icons.school_outlined),
            ('Assessments', 'Explore your strengths and progress', AppRoutes.assessments, Icons.quiz_outlined),
            ('Your badges', 'Celebrate your achievements', AppRoutes.badges, Icons.workspace_premium_outlined),
            ('Your applications', 'Follow your recruitment journey', AppRoutes.applications, Icons.work_outline),
          ];
    return PageLayout(title: admin ? 'Recruitment workspace' : 'Talent dashboard',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Hello, ${user.name}', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(admin ? 'Help your next great hire take the next step.'
            : 'Build your skills and take the next step in your career.'),
        const SizedBox(height: 24),
        for (final link in links)
          AppCard(title: link.$1, subtitle: link.$2, icon: link.$4,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, link.$3)),
      ]),
    );
  }
}
