import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'page_layout.dart';
import 'brand_logo.dart';

class DashboardAction {
  const DashboardAction({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
}

/// Shared home presentation with role-specific content and navigation.
class DashboardLayout extends StatefulWidget {
  const DashboardLayout({
    super.key,
    required this.title,
    required this.workspace,
    required this.name,
    required this.introduction,
    required this.primaryAction,
    required this.overview,
    required this.announcements,
    required this.actionsTitle,
    required this.actions,
  });

  final String title;
  final String workspace;
  final String name;
  final String introduction;
  final DashboardAction primaryAction;
  final Widget overview;
  final Widget announcements;
  final String actionsTitle;
  final List<DashboardAction> actions;

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _revision = 0;

  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) setState(() => _revision++);
  }

  void _openFromMenu(String route) {
    Navigator.pop(context);
    if (route != AppRoutes.home) _open(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageLayout(
      title: widget.title,
      maxWidth: 1120,
      appBarTitle: const BrandLogo(showMark: false, size: 22),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_graph,
                        color: theme.colorScheme.primary, size: 36),
                    const SizedBox(height: 12),
                    Text('Excelerate Talent Hub',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.workspace, style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
              ListTile(
                selected: true,
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () => _openFromMenu(AppRoutes.home),
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Programs'),
                onTap: () => _openFromMenu(AppRoutes.programs),
              ),
              const Divider(),
              for (final action in widget.actions)
                if (action.route != AppRoutes.programs)
                  ListTile(
                    leading: Icon(action.icon),
                    title: Text(action.title),
                    onTap: () => _openFromMenu(action.route),
                  ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: Icon(Icons.home_outlined,
                    size: 18, color: theme.colorScheme.primary),
                label: const Text('Home'),
                backgroundColor: const Color(0xFFFFF0E8),
                side: BorderSide.none,
              ),
              TextButton.icon(
                onPressed: () => _open(AppRoutes.programs),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Programs'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _welcome(theme),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, constraints) {
            final overview = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('At a glance',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                KeyedSubtree(key: ValueKey(_revision), child: widget.overview),
              ],
            );
            if (constraints.maxWidth >= 860) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: widget.announcements),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: overview),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.announcements,
                const SizedBox(height: 24),
                overview,
              ],
            );
          }),
          const SizedBox(height: 28),
          Text('Quick links',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.actionsTitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF525D70))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final action in widget.actions)
                  SizedBox(width: width, child: _actionCard(action, theme)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _welcome(ThemeData theme) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0E8), Color(0xFFFFF8F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD9C7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.workspace,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF9B3200),
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Welcome back to Excelerate',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Hello, ${widget.name}',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.introduction, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _open(widget.primaryAction.route),
              icon: Icon(widget.primaryAction.icon),
              label: Text(widget.primaryAction.title),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: const Color(0xFF9B3200))),
          ],
        ),
      );

  Widget _actionCard(DashboardAction action, ThemeData theme) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E5ED))),
        child: InkWell(
          onTap: () => _open(action.route),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E8),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(action.icon, color: theme.colorScheme.primary),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward,
                      size: 20, color: Color(0xFF667085)),
                ]),
                const SizedBox(height: 16),
                Text(action.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(action.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF525D70))),
              ],
            ),
          ),
        ),
      );
}
