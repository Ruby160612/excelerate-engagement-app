import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/program_query.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/program_repository.dart';
import '../../state/program_store.dart';
import '../../utils/constants.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/program_card.dart';

class ProgramsListView extends StatefulWidget {
  const ProgramsListView({super.key});

  @override
  State<ProgramsListView> createState() => _ProgramsListViewState();
}

class _ProgramsListViewState extends State<ProgramsListView> {
  final _search = TextEditingController();
  String? _category;

  static const _loadFailed = 'Unable to load this page. Please try again.';

  @override
  void initState() {
    super.initState();
    // Wait until the first frame so the store is not changed while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProgramStore>().loadPrograms();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _messageOf(Object error, String fallback) =>
      error is ProgramException ? error.message : fallback;

  void _retry() => context.read<ProgramStore>().loadPrograms();

  Future<void> _register(Program program) async {
    try {
      await context.read<ProgramStore>().register(program.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _messageOf(error, 'Unable to register. Please try again.'))));
      }
    }
  }

  List<String> _categoriesOf(List<Program> programs) =>
      {for (final program in programs) program.category}.toList();

  List<Program> _visibleOf(List<Program> programs) =>
      ProgramQuery(search: _search.text, category: _category).apply(programs);

  static String _label(String category) =>
      category[0].toUpperCase() + category.substring(1);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthService>().user?.role == UserRole.admin;
    final store = context.watch<ProgramStore>();
    final categories = _categoriesOf(store.programs);
    return PageLayout(
      title: 'Development programs',
      maxWidth: 1040,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search programs',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_search.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _chips(Theme.of(context).colorScheme, categories),
          ],
          const SizedBox(height: 16),
          if (store.listStatus == LoadStatus.loaded && store.skipped > 0)
            _skippedNotice(store.skipped),
          _content(store, admin),
        ],
      ),
    );
  }

  Widget _skippedNotice(int skipped) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(skipped == 1
                  ? 'One program could not be shown.'
                  : '$skipped programs could not be shown.'),
            ),
          ],
        ),
      );

  Future<void> _open(Program program) async {
    await Navigator.pushNamed(context, AppRoutes.programDetailsFor(program.id));
    if (mounted) context.read<ProgramStore>().loadPrograms(silent: true);
  }

  Widget _chips(ColorScheme scheme, List<String> categories) => SizedBox(
        height: MediaQuery.textScalerOf(context).scale(44),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final category in [null, ...categories])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category == null ? 'All' : _label(category)),
                  selected: _category == category,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: scheme.primary,
                  labelStyle: TextStyle(
                    color: _category == category ? scheme.onPrimary : null,
                  ),
                  onSelected: (_) => setState(() => _category = category),
                ),
              ),
          ],
        ),
      );

  Widget _content(ProgramStore store, bool admin) {
    final status = store.listStatus;
    if (status == LoadStatus.idle || status == LoadStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (status == LoadStatus.error) {
      return Column(children: [
        Text(store.listError ?? _loadFailed),
        TextButton(onPressed: _retry, child: const Text('Retry')),
      ]);
    }
    if (store.programs.isEmpty) {
      return const Text('New development programs will appear here.');
    }
    final programs = _visibleOf(store.programs);
    if (programs.isEmpty) {
      return const Text('No programs match your search.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMultiColumn = constraints.maxWidth >= 700;
        final cardWidth = isMultiColumn
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 0,
          children: [
            for (final program in programs)
              SizedBox(
                width: cardWidth,
                child: ProgramCard(
                  program: program,
                  registering: store.isRegistering(program.id),
                  onRegister: admin ? null : () => _register(program),
                  onTap: () => _open(program),
                ),
              ),
          ],
        );
      },
    );
  }
}
