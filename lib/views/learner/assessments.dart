import 'package:flutter/material.dart';
import '../../models/assessment.dart';
import '../../widgets/api_collection_view.dart';
import '../../widgets/app_card.dart';

class AssessmentsView extends StatelessWidget {
  const AssessmentsView({super.key});
  @override
  Widget build(BuildContext context) => ApiCollectionView(
        title: 'Assessments',
        path: '/assessments/me',
        emptyMessage: 'You have no assigned assessments yet.',
        itemBuilder: (item) {
          final assessment = Assessment.fromJson(item);
          return AppCard(
              title: assessment.title,
              subtitle: '${assessment.durationMinutes} minutes • '
                  '${assessment.completed ? 'Completed' : 'Pending'}'
                  '${assessment.score == null ? '' : ' • Score: ${assessment.score}'}',
              icon: Icons.quiz_outlined);
        },
      );
}
