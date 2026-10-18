import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.title,
    required this.child,
    this.drawer,
    this.appBarTitle,
    this.maxWidth = 900,
  });
  final String title;
  final Widget child;
  final Widget? drawer;
  final Widget? appBarTitle;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: drawer,
        appBar: AppBar(title: appBarTitle ?? Text(title), actions: [
          if (context.watch<AuthService>().user != null)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await context.read<AuthService>().logout();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Signed out, but the saved session could '
                          'not be removed from this device.'),
                    ));
                  }
                }
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.home, (_) => false);
                }
              },
            ),
        ]),
        body: SafeArea(
            child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24), child: child)),
        )),
      );
}
