import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/program.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

// Same brand orange used on the login screen.
const Color _brandOrange = Color(0xFFFF4500);

class ProgramDetailsView extends StatefulWidget {
  const ProgramDetailsView({super.key, required this.program});

  final Program program;

  @override
  State<ProgramDetailsView> createState() => _ProgramDetailsViewState();
}

class _ProgramDetailsViewState extends State<ProgramDetailsView> {
  late Program _program = widget.program;
  bool _registering = false;

  Future<void> _register() async {
    setState(() => _registering = true);
    try {
      final id = Uri.encodeComponent(_program.id);
      final json = await context
          .read<ApiService>()
          .post('/programs/$id/register', {}) as Map;
      final updated = Program.fromJson(Map<String, dynamic>.from(json));
      if (mounted) setState(() => _program = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to register. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  String get _dateText {
    final format = DateFormat.yMMMd();
    final start = _program.startDate.toLocal();
    final end = _program.endDate?.toLocal();
    final startText = format.format(start);
    if (end == null) return startText;
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return sameDay ? startText : '$startText - ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthService>().user?.role == UserRole.admin;
    final program = _program;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Program Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Banner(program: program),
                  const SizedBox(height: 16),
                  _CategoryPill(category: program.category),
                  const SizedBox(height: 12),
                  Text(
                    program.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(rows: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: _dateText,
                    ),
                    if (program.schedule.isNotEmpty)
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Schedule',
                        value: program.schedule,
                      ),
                  ]),
                  if (program.description.isNotEmpty)
                    _Section(
                      title: 'Description',
                      child: Text(
                        program.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (program.eligibility.isNotEmpty)
                    _Section(
                      title: 'Eligibility',
                      child: _BulletList(items: program.eligibility),
                    ),
                  if (program.outcomes.isNotEmpty)
                    _Section(
                      title: 'Expected outcomes',
                      child: _BulletList(items: program.outcomes),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Admins can view programs but cannot register (the API rejects it).
      bottomNavigationBar: admin
          ? null
          : SafeArea(
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: _RegisterButton(
                      registered: program.isRegistered,
                      busy: _registering,
                      onPressed: _register,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.registered,
    required this.busy,
    required this.onPressed,
  });

  final bool registered;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: registered
          ? OutlinedButton.icon(
              onPressed: null,
              style: OutlinedButton.styleFrom(shape: shape),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'REGISTERED',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandOrange,
                foregroundColor: Colors.white,
                shape: shape,
              ),
              onPressed: busy ? null : onPressed,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'REGISTER',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.program});

  final Program program;

  static IconData _icon(String category) => switch (category) {
        'workshop' => Icons.build_outlined,
        'webinar' => Icons.videocam_outlined,
        'internship' => Icons.work_outline,
        _ => Icons.school_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(_icon(program.category),
            size: 56, color: Colors.grey.shade600),
      ),
    );
    final url = program.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: url == null || url.isEmpty
            ? placeholder
            : Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _brandOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: const TextStyle(
          color: _brandOrange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 12),
                  child: Icon(Icons.circle, size: 6, color: _brandOrange),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
