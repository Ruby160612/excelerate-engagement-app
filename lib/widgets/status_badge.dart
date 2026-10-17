import 'package:flutter/material.dart';

import '../utils/themes.dart';

enum StatusBadgeType { success, warning, error, info, primary, neutral }

/// A compact status indicator or category tag pill.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  const StatusBadge.success({
    super.key,
    required this.label,
    this.icon,
  }) : type = StatusBadgeType.success;

  const StatusBadge.warning({
    super.key,
    required this.label,
    this.icon,
  }) : type = StatusBadgeType.warning;

  const StatusBadge.error({
    super.key,
    required this.label,
    this.icon,
  }) : type = StatusBadgeType.error;

  const StatusBadge.info({
    super.key,
    required this.label,
    this.icon,
  }) : type = StatusBadgeType.info;

  const StatusBadge.primary({
    super.key,
    required this.label,
    this.icon,
  }) : type = StatusBadgeType.primary;

  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (type) {
      StatusBadgeType.success => (
          AppColors.successLight,
          AppColors.successBorder,
          AppColors.success
        ),
      StatusBadgeType.warning => (
          AppColors.warningLight,
          AppColors.warningBorder,
          AppColors.warning
        ),
      StatusBadgeType.error => (
          AppColors.errorLight,
          AppColors.errorBorder,
          AppColors.error
        ),
      StatusBadgeType.info => (
          AppColors.infoLight,
          AppColors.infoBorder,
          AppColors.info
        ),
      StatusBadgeType.primary => (
          AppColors.primaryLight,
          AppColors.primaryBorder,
          AppColors.primaryDark
        ),
      StatusBadgeType.neutral => (
          AppColors.secondaryLight,
          AppColors.border,
          AppColors.textSecondary
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
