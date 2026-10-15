import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
  String? _category;

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
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

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
      final id = Uri.encodeComponent(program.id);
      final json = await context
          .read<ApiService>()
          .post('/programs/$id/register', {}) as Map;
      final updated = Program.fromJson(Map<String, dynamic>.from(json));
      if (mounted) {
        setState(() => _programs = [
              for (final p in _programs!) p.id == updated.id ? updated : p,
            ]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to register. Please try again.')));
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
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Column(children: [
        const Text('Unable to load this page. Please try again.'),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return ProgramCard(
          program: program,
          registering: _registering.contains(program.id),
          onRegister: admin ? null : () => _register(program),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.programDetails,
            arguments: program,
          ),
        );
      },
    );
  }
}
