import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import 'empty_state.dart';
import 'error_card.dart';
import 'page_layout.dart';

/// Shared loading, empty, error, and retry handling for collection screens.
class ApiCollectionView extends StatefulWidget {
  const ApiCollectionView({
    super.key,
    required this.title,
    required this.path,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final String title;
  final String path;
  final String emptyMessage;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  State<ApiCollectionView> createState() => _ApiCollectionViewState();
}

class _ApiCollectionViewState extends State<ApiCollectionView> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  bool _failed = false;
  String? _errorMessage;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_inFlight) return;
    _inFlight = true;
    setState(() {
      _loading = true;
      _failed = false;
      _errorMessage = null;
    });

    try {
      final data = await context.read<ApiService>().get(widget.path) as List;
      final items =
          data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _failed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
          _errorMessage = e is ApiException
              ? e.message
              : 'Unable to load this page. Please try again.';
        });
      }
    } finally {
      _inFlight = false;
    }
  }

  void _retry() {
    _load();
  }

  @override
  Widget build(BuildContext context) => PageLayout(
        title: widget.title,
        child: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return ErrorCard(
        title: 'Unable to load content',
        message: _errorMessage ?? 'Unable to load this page. Please try again.',
        onRetry: _retry,
      );
    }
    final items = _items ?? const [];
    if (items.isEmpty) {
      return EmptyStateWidget(
        title: 'Nothing here yet',
        message: widget.emptyMessage,
        icon: Icons.inbox_outlined,
      );
    }
    return Column(children: items.map(widget.itemBuilder).toList());
  }
}
