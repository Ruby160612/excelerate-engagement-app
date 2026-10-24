import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/themes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_card.dart';
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
  String? _category;
  bool _inFlight = false;

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

  Future<void> _load() async {
    if (_inFlight) return;
    _inFlight = true;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final data = await context.read<ApiService>().get('/programs') as List;
      final programs = [
        for (final json in data)
          Program.fromJson(Map<String, dynamic>.from(json as Map)),
      ];
      if (mounted) {
        setState(() {
          _programs = programs;
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      _inFlight = false;
    }
  }

  void _retry() {
    _load();
  }

  Future<void> _register(Program program) async {
    if (_registering.contains(program.id)) return;
    setState(() => _registering.add(program.id));

    try {
      final id = Uri.encodeComponent(program.id);
      final json = await context
          .read<ApiService>()
          .post('/programs/$id/register', {}) as Map;
      final updated = Program.fromJson(Map<String, dynamic>.from(json));
      if (mounted) {
        setState(() => _programs = [
              for (final p in _programs!) p.id == updated.id ? updated : p,
            ]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to register. Please try again.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _register(program),
            ),
          ),
        );
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
          _content(admin),
        ],
      ),
    );
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
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return ErrorCard(
        title: 'Unable to load programs',
        message: "We couldn't load programs. Try again.",
        onRetry: _retry,
      );
    }
    if (_programs!.isEmpty) {
      return const EmptyStateWidget(
        title: 'No programs available',
        message: 'New development programs will appear here.',
        icon: Icons.school_outlined,
      );
    }
    final programs = _visible;
    if (programs.isEmpty) {
      return const EmptyStateWidget(
        title: 'No matching programs',
        message: 'No programs match your search.',
        icon: Icons.search_off_outlined,
      );
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
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.programDetails,
                    arguments: program,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
