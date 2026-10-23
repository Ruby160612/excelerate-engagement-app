import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../services/program_repository.dart';
import '../../widgets/page_layout.dart';
import 'program_details.dart';

class ProgramDetailsLoader extends StatefulWidget {
  const ProgramDetailsLoader({super.key, required this.programId});

  final String programId;

  @override
  State<ProgramDetailsLoader> createState() => _ProgramDetailsLoaderState();
}

class _ProgramDetailsLoaderState extends State<ProgramDetailsLoader> {
  Program? _program;
  ProgramException? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await context
          .read<ProgramRepository>()
          .fetchProgram(widget.programId);
      if (mounted) setState(() => _program = program);
    } catch (error) {
      if (mounted) {
        setState(() => _failure = error is ProgramException
            ? error
            : const ProgramException(ProgramFailure.unavailable,
                'Unable to load this program. Please try again.'));
      }
    }
  }

  void _retry() {
    setState(() => _failure = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program != null) return ProgramDetailsView(program: program);
    final failure = _failure;
    return PageLayout(
      title: 'Program',
      child: failure == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : _FailureView(failure: failure, onRetry: _retry),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.failure, required this.onRetry});

  final ProgramException failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (failure.kind) {
      ProgramFailure.notFound => Icons.search_off,
      ProgramFailure.invalidData => Icons.report_problem_outlined,
      ProgramFailure.unavailable => Icons.cloud_off_outlined,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(failure.message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (failure.retryable)
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Back to programs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
