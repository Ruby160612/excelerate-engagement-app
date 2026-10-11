import 'package:flutter/material.dart';
import '../../models/badge.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/badge_widget.dart';

class BadgesView extends StatelessWidget {
  const BadgesView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
    title: 'Your badges', path: '/badges/me',
    emptyMessage: 'Your earned badges will appear here.',
    itemBuilder: (item) => BadgeWidget(badge: TalentBadge.fromJson(item)),
  );
}
