import 'package:flutter/material.dart';

import '../utils/themes.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

/// Reusable button adhering to Excelerate branding and design tokens.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.outlined;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget button;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    if (loading) {
      final spinner = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );

      switch (variant) {
        case AppButtonVariant.primary:
          button = FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(shape: shape),
            child: spinner,
          );
        case AppButtonVariant.secondary:
        case AppButtonVariant.outlined:
          button = OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(shape: shape),
            child: spinner,
          );
        case AppButtonVariant.text:
          button = TextButton(
            onPressed: null,
            style: TextButton.styleFrom(shape: shape),
            child: spinner,
          );
      }
    } else {
      switch (variant) {
        case AppButtonVariant.primary:
          button = icon != null
              ? FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 18),
                  label: Text(label),
                  style: FilledButton.styleFrom(shape: shape),
                )
              : FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(shape: shape),
                  child: Text(label),
                );
        case AppButtonVariant.secondary:
          button = icon != null
              ? FilledButton.tonalIcon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 18),
                  label: Text(label),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primaryDark,
                    shape: shape,
                  ),
                )
              : FilledButton.tonal(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primaryDark,
                    shape: shape,
                  ),
                  child: Text(label),
                );
        case AppButtonVariant.outlined:
          button = icon != null
              ? OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 18),
                  label: Text(label),
                  style: OutlinedButton.styleFrom(shape: shape),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(shape: shape),
                  child: Text(label),
                );
        case AppButtonVariant.text:
          button = icon != null
              ? TextButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 18),
                  label: Text(label),
                  style: TextButton.styleFrom(shape: shape),
                )
              : TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(shape: shape),
                  child: Text(label),
                );
      }
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: button,
    );
  }
}
