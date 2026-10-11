import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import 'page_layout.dart';

/// Shared loading, empty, error, and retry handling for collection screens.
class ApiCollectionView extends StatefulWidget {
  const ApiCollectionView(
      {super.key,
      required this.title,
      required this.path,
      required this.emptyMessage,
      required this.itemBuilder});
  final String title;
  final String path;
  final String emptyMessage;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  State<ApiCollectionView> createState() => _ApiCollectionViewState();
}

class _ApiCollectionViewState extends State<ApiCollectionView> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await context.read<ApiService>().get(widget.path) as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Widget build(BuildContext context) => PageLayout(
        title: widget.title,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(children: [
                const Text('Unable to load this page. Please try again.'),
                TextButton(
                    onPressed: () => setState(() => _items = _load()),
                    child: const Text('Retry')),
              ]);
            }
            final items = snapshot.data!;
            if (items.isEmpty) return Text(widget.emptyMessage);
            return Column(children: items.map(widget.itemBuilder).toList());
          },
        ),
      );
}
