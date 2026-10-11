import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/app_card.dart';

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
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.interviewScheduler,
                arguments: item['id'].toString())),
      );
}
