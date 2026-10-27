import 'package:flutter/material.dart';

import '../utils/themes.dart';

/// The Excelerate logo. Every screen uses this one widget so the logo looks
/// the same everywhere (colour, italic style, optional mark and tagline).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.showMark = true,
    this.showTagline = false,
    this.size = 28,
  });

  /// Shows the three-line mark to the left of the name.
  final bool showMark;

  /// Shows "TALENT HUB" under the name.
  final bool showTagline;

  /// Font size of the name; the mark scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          Icon(Icons.menu, color: AppColors.primary, size: size),
          SizedBox(width: size * 0.3),
        ],
        Text(
          'Excelerate',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
          ),
        ),
      ],
    );
    final logo = showTagline
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              name,
              Text(
                'TALENT HUB',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(letterSpacing: 2),
              ),
            ],
          )
        : name;
    // Shrinks the logo instead of overflowing on narrow screens or when the
    // user enlarges the system text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: logo,
    );
  }
}
