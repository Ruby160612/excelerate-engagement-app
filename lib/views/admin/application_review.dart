import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/api_collection_view.dart';

class ApplicationReviewView extends StatelessWidget {
  const ApplicationReviewView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
        title: 'Review applications',
        path: '/applications',
        emptyMessage: 'There are no applications to review yet.',
        itemBuilder: (item) => ApplicationReviewCard(application: item),
      );
}

class ApplicationReviewCard extends StatefulWidget {
  const ApplicationReviewCard({super.key, required this.application});
  final Map<String, dynamic> application;
  @override
  State<ApplicationReviewCard> createState() => _ApplicationReviewCardState();
}

class _ApplicationReviewCardState extends State<ApplicationReviewCard> {
  bool _busy = false;
  late String _status;
  @override
  void initState() {
    super.initState();
    _status = widget.application['status'] as String;
  }

  Future<void> _shortlist() async {
    setState(() => _busy = true);
    try {
      final id = Uri.encodeComponent(widget.application['id'].toString());
      await context
          .read<ApiService>()
          .put('/applications/$id', {'status': 'shortlisted'});
      if (mounted) setState(() => _status = 'shortlisted');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Unable to shortlist this candidate. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.application['candidate_name'] as String,
              style: Theme.of(context).textTheme.titleMedium),
          Text('${widget.application['opportunity_title']} • $_status'),
          Text('Application reference: ${widget.application['id']}'),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _busy || _status == 'shortlisted' ? null : _shortlist,
              child: Text(_busy ? 'Saving…' : 'Shortlist candidate')),
        ]),
      ));
}
