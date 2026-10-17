import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.path,
    required this.route,
    required this.icon,
    this.filterField,
    this.filterValue,
  });

  final String label;
  final String path;
  final String route;
  final IconData icon;
  final String? filterField;
  final Object? filterValue;

  int count(List<Map<String, dynamic>> items) => filterField == null
      ? items.length
      : items.where((item) => item[filterField] == filterValue).length;
}

/// Reads existing collection endpoints, sharing requests for matching paths.
class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key, required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  late Future<Map<String, List<Map<String, dynamic>>>> _collections;

  @override
  void initState() {
    super.initState();
    _collections = _load();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _load() async {
    final api = context.read<ApiService>();
    final paths = widget.metrics.map((metric) => metric.path).toSet();
    final entries = await Future.wait(paths.map((path) async {
      final data = await api.get(path) as List;
      return MapEntry(path, [
        for (final item in data) Map<String, dynamic>.from(item as Map),
      ]);
    }));
    return Map.fromEntries(entries);
  }

  void _refresh() {
    final collections = _load();
    setState(() {
      _collections = collections;
    });
  }

  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _collections,
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
                const Text('Unable to load your overview. '
                    'You can still use the links below.'),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry overview'),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560
                    ? widget.metrics.length
                    : constraints.maxWidth >= 340
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in widget.metrics)
                      SizedBox(
                        width: width,
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: Colors.white,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFE2E5ED)),
                          ),
                          child: InkWell(
                            onTap: () => _open(metric.route),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(metric.icon,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${metric.count(snapshot.data![metric.path]!)}',
                                    key: ValueKey('metric-${metric.label}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(metric.label),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh overview'),
                ),
              ),
            ],
          );
        },
      );
}
