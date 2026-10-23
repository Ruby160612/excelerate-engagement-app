import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../models/badge.dart';
import '../utils/themes.dart';

class BadgeWidget extends StatelessWidget {
  const BadgeWidget({super.key, required this.badge});
  final TalentBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              SvgPicture.asset('assets/icons/badge.svg', width: 32, height: 32),
        ),
        title: Text(
          badge.name,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${badge.description}'
          '${badge.earnedAt == null ? '' : '\nEarned ${DateFormat.yMMMd().format(badge.earnedAt!.toLocal())}'}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
