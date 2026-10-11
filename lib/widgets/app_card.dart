import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.title, required this.subtitle,
    this.icon = Icons.school_outlined, this.onTap, this.trailing});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon), title: Text(title), subtitle: Text(subtitle),
          onTap: onTap, trailing: trailing,
        ),
      );
}
