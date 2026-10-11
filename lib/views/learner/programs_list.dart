import 'package:flutter/material.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/app_card.dart';

class ProgramsListView extends StatelessWidget {
  const ProgramsListView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
        title: 'Development programs',
        path: '/programs',
        emptyMessage: 'New development programs will appear here.',
        itemBuilder: (item) => AppCard(
            title: item['title'] as String,
            subtitle: item['description'] as String? ?? ''),
      );
}
