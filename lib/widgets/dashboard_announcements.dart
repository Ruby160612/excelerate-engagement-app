import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/announcement.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DashboardAnnouncements extends StatefulWidget {
  const DashboardAnnouncements({super.key, required this.role});

  final UserRole role;

  @override
  State<DashboardAnnouncements> createState() => _DashboardAnnouncementsState();
}

class _DashboardAnnouncementsState extends State<DashboardAnnouncements> {
  late Future<List<Announcement>> _announcements;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _announcements = _load();
  }

  Future<List<Announcement>> _load() async {
    final data = await context.read<ApiService>().get('/announcements') as List;
    return [
      for (final json in data)
        Announcement.fromJson(Map<String, dynamic>.from(json as Map)),
    ].where((item) => item.isVisibleTo(widget.role)).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  void _refresh() {
    setState(() {
      _announcements = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E5ED)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Announcements',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'Refresh announcements',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ]),
            const SizedBox(height: 8),
            FutureBuilder<List<Announcement>>(
              future: _announcements,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unable to load announcements.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Retry announcements'),
                      ),
                    ],
                  );
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('You’re all caught up. New announcements '
                        'from Excelerate will appear here.'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in _expanded ? items : items.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(item.publishedAt),
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(color: const Color(0xFF667085))),
                            const SizedBox(height: 5),
                            Text(item.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(item.body,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF525D70))),
                          ],
                        ),
                      ),
                    if (items.length > 3)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(_expanded
                            ? 'Show fewer announcements'
                            : 'View all announcements (${items.length})'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
