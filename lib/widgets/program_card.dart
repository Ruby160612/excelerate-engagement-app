import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/program.dart';

class ProgramCard extends StatelessWidget {
  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
    this.onRegister,
    this.registering = false,
  });

  final Program program;
  final VoidCallback onTap;
  final VoidCallback? onRegister;
  final bool registering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(builder: (context, constraints) {
            final imageSize = constraints.maxWidth < 280 ? 64.0 : 88.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Thumbnail(program: program, size: imageSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  DateFormat.yMMMd()
                                      .format(program.startDate.toLocal()),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            program.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _action(),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _action() {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    if (onRegister != null && !program.isRegistered) {
      return FilledButton(
        onPressed: registering ? null : onRegister,
        style: FilledButton.styleFrom(shape: shape),
        child: registering
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Register'),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(shape: shape),
      child: const Text('View'),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.program, required this.size});

  final Program program;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(_icon(program.category),
            size: size * 0.45, color: Colors.grey.shade600),
      ),
    );
    final url = program.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
      ),
    );
  }

  static IconData _icon(String category) => switch (category) {
        'workshop' => Icons.build_outlined,
        'webinar' => Icons.videocam_outlined,
        'internship' => Icons.work_outline,
        _ => Icons.school_outlined,
      };
}
