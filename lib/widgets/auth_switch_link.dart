import 'package:flutter/material.dart';

import '../utils/themes.dart';

/// "Don't have an account? Sign Up" style link used at the bottom of Login and
/// Sign Up, so both screens switch between each other the same way.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  /// Plain text before the link, for example `Don't have an account?`.
  final String prompt;

  /// The tappable text, for example `Sign Up`.
  final String action;

  /// Null disables the link (used while a request is running).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$prompt ',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
}
