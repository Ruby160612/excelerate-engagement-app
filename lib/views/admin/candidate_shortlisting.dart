import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class CandidateShortlistingView extends StatelessWidget {
  const CandidateShortlistingView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
        title: 'Candidate shortlist',
        path: '/applications?status=shortlisted',
        emptyMessage: 'Shortlisted candidates will appear here.',
        itemBuilder: (item) => AppCard(
            title: item['candidate_name'] as String,
            subtitle: '${item['opportunity_title']} • Reference: ${item['id']}',
            icon: Icons.person_outline,
            statusBadge: const StatusBadge.success(label: 'Shortlisted'),
            trailing: const Tooltip(
              message: 'Schedule interview',
              child: Icon(Icons.calendar_month_outlined, color: Color(0xFFFF4500)),
            ),
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.interviewScheduler,
                arguments: item['id'].toString())),
      );
}
