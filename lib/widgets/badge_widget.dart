import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../models/badge.dart';

class BadgeWidget extends StatelessWidget {
  const BadgeWidget({super.key, required this.badge});
  final TalentBadge badge;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: SvgPicture.asset('assets/icons/badge.svg', width: 40),
          title: Text(badge.name),
          subtitle: Text('${badge.description}'
              '${badge.earnedAt == null ? '' : '\nEarned ${DateFormat.yMMMd().format(badge.earnedAt!.toLocal())}'}'),
        ),
      );
}
