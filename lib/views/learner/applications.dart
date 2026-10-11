import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/app_card.dart';

class ApplicationsView extends StatelessWidget {
  const ApplicationsView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
    title: 'Your applications', path: '/applications/me',
    emptyMessage: 'Your submitted applications will appear here.',
    itemBuilder: (item) => AppCard(title: item['opportunity_title'] as String,
      icon: Icons.work_outline,
      subtitle: '${item['status']} • '
          '${DateFormat.yMMMd().format(DateTime.parse(item['created_at'] as String).toLocal())}'),
  );
}
