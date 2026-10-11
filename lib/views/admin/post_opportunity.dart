import 'package:flutter/material.dart';
import '../../widgets/api_form.dart';

class PostOpportunityView extends StatelessWidget {
  const PostOpportunityView({super.key});
  @override
  Widget build(BuildContext context) => const ApiForm(
        title: 'Post an opportunity',
        path: '/opportunities',
        fields: {
          'title': 'Role title',
          'company': 'Company',
          'location': 'Location',
          'description': 'Description'
        },
        dateKey: 'deadline',
        dateLabel: 'Choose application deadline',
        submitLabel: 'Publish opportunity',
        successMessage: 'Your opportunity was published.',
      );
}
