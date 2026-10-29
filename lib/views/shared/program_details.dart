import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../state/program_store.dart';
import '../../state/submission_controller.dart';
import '../../utils/themes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/status_badge.dart';

class ProgramDetailsView extends StatefulWidget {
  const ProgramDetailsView({super.key, required this.program});

  final Program program;

  @override
  State<ProgramDetailsView> createState() => _ProgramDetailsViewState();
}

class _ProgramDetailsViewState extends State<ProgramDetailsView> {
  final _registration = SubmissionController();

  @override
  void initState() {
    super.initState();
    _registration.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _registration.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final store = context.read<ProgramStore>();
    final ok =
        await _registration.submit((_) => store.register(widget.program.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'You have successfully registered for this program!'
            : _registration.message ??
                'Unable to register. Please try again later.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  static String _categoryLabel(String category) => category.isEmpty
      ? 'Program'
      : category[0].toUpperCase() + category.substring(1);

  static IconData _categoryIcon(String category) =>
      switch (category.toLowerCase()) {
        'workshop' => Icons.build_outlined,
        'webinar' => Icons.videocam_outlined,
        'internship' => Icons.work_outline,
        _ => Icons.school_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().user;
    final isAdmin = user?.role == UserRole.admin;
    final program = context.watch<ProgramStore>().lookup(widget.program.id) ??
        widget.program;

    return PageLayout(
      title: program.title,
      maxWidth: 1040,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb / Back Bar
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Programs'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.textMuted),
              StatusBadge.primary(
                label: _categoryLabel(program.category),
                icon: _categoryIcon(program.category),
              ),
              if (program.isRegistered)
                const StatusBadge.success(
                  label: 'Registered',
                  icon: Icons.check_circle_outline,
                ),
              if (isAdmin)
                const StatusBadge.info(
                  label: 'Admin Preview',
                  icon: Icons.admin_panel_settings_outlined,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Header Hero Banner
          _buildHeroBanner(theme, program),
          const SizedBox(height: 24),

          // Responsive Content Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final mainContent = _buildMainContent(theme, program);
              final sidebar = _buildSidebar(theme, program, isAdmin);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: mainContent),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: sidebar),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sidebar,
                  const SizedBox(height: 24),
                  mainContent,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme, Program program) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primaryLighter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(_categoryIcon(program.category),
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(program.category).toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Excelerate Development Program',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            program.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            program.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, Program program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Learning Outcomes Section
        if (program.outcomes.isNotEmpty) ...[
          _buildCardSection(
            theme: theme,
            title: 'Learning Outcomes & Benefits',
            icon: Icons.emoji_events_outlined,
            children: [
              for (final outcome in program.outcomes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          outcome,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Eligibility Requirements Section
        if (program.eligibility.isNotEmpty) ...[
          _buildCardSection(
            theme: theme,
            title: 'Eligibility & Requirements',
            icon: Icons.fact_check_outlined,
            children: [
              for (final req in program.eligibility)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_alt,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSidebar(ThemeData theme, Program program, bool isAdmin) {
    final startFormatted =
        DateFormat.yMMMd().format(program.startDate.toLocal());
    final endFormatted = program.endDate != null
        ? DateFormat.yMMMd().format(program.endDate!.toLocal())
        : 'Ongoing / Flexible';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Program Overview',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Start Date',
              value: startFormatted,
              theme: theme,
            ),
            const Divider(height: 20),

            _buildDetailRow(
              icon: Icons.event_available_outlined,
              label: 'End Date',
              value: endFormatted,
              theme: theme,
            ),
            const Divider(height: 20),

            _buildDetailRow(
              icon: Icons.schedule_outlined,
              label: 'Schedule',
              value: program.schedule.isNotEmpty
                  ? program.schedule
                  : 'To be announced',
              theme: theme,
            ),
            const Divider(height: 20),

            _buildDetailRow(
              icon: Icons.category_outlined,
              label: 'Format',
              value: _categoryLabel(program.category),
              theme: theme,
            ),
            const SizedBox(height: 24),

            // Action / Status Area
            if (!isAdmin) ...[
              if (program.isRegistered)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'You are enrolled in this program',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                AppButton.primary(
                  label: 'Register for Program',
                  loading: _registration.isSubmitting,
                  isFullWidth: true,
                  icon: Icons.how_to_reg_outlined,
                  onPressed: _register,
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Learners can register for this program from their portal.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
