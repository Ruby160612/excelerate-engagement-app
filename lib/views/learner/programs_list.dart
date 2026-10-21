import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/program_repository.dart';
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
  final _registering = <String>{};
  List<Program>? _programs;
  bool _loading = true;
  bool _failed = false;
  String _errorMessage = _loadFailed;
  int _skipped = 0;
  String? _category;

  static const _loadFailed = 'Unable to load this page. Please try again.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final result = await context.read<ProgramRepository>().fetchPrograms();
      if (mounted) {
        setState(() {
          _programs = result.programs;
          _skipped = result.skipped;
          _failed = false;
          _loading = false;
        });
      }
    } catch (error) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = _messageOf(error, _loadFailed);
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  static String _messageOf(Object error, String fallback) =>
      error is ProgramException ? error.message : fallback;

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
  }

  Future<void> _register(Program program) async {
    setState(() => _registering.add(program.id));
    try {
      final updated =
          await context.read<ProgramRepository>().register(program.id);
      if (mounted) {
        setState(() => _programs = [
              for (final p in _programs!) p.id == updated.id ? updated : p,
            ]);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _messageOf(error, 'Unable to register. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _registering.remove(program.id));
    }
  }

  List<String> get _categories => {
        for (final program in _programs ?? const <Program>[]) program.category,
      }.toList();

  List<Program> get _visible {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final program in _programs ?? const <Program>[])
        if ((_category == null || program.category == _category) &&
            (query.isEmpty ||
                program.title.toLowerCase().contains(query) ||
                program.description.toLowerCase().contains(query)))
          program,
    ];
  }

  static String _label(String category) =>
      category[0].toUpperCase() + category.substring(1);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthService>().user?.role == UserRole.admin;
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
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _chips(Theme.of(context).colorScheme),
          ],
          const SizedBox(height: 16),
          if (_programs != null && _skipped > 0) _skippedNotice(),
          _content(admin),
        ],
      ),
    );
  }

  Widget _skippedNotice() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_skipped == 1
                  ? 'One program could not be shown.'
                  : '$_skipped programs could not be shown.'),
            ),
          ],
        ),
      );

  Future<void> _open(Program program) async {
    await Navigator.pushNamed(context, AppRoutes.programDetailsFor(program.id));
    if (mounted) _load(silent: true);
  }

  Widget _chips(ColorScheme scheme) => SizedBox(
        height: MediaQuery.textScalerOf(context).scale(44),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final category in [null, ..._categories])
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

  Widget _content(bool admin) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Column(children: [
        Text(_errorMessage),
        TextButton(onPressed: _retry, child: const Text('Retry')),
      ]);
    }
    if (_programs!.isEmpty) {
      return const Text('New development programs will appear here.');
    }
    final programs = _visible;
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
                  registering: _registering.contains(program.id),
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
