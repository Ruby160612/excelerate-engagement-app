import 'package:flutter/material.dart';
import '../../widgets/api_form.dart';

class InterviewSchedulerView extends StatelessWidget {
  const InterviewSchedulerView({super.key, this.applicationId});
  final String? applicationId;
  @override
  Widget build(BuildContext context) => ApiForm(
        title: 'Schedule an interview',
        path: '/interviews',
        fields: const {
          'application_id': 'Application reference',
          'location': 'Location or meeting link'
        },
        initialValues: {
          if (applicationId != null) 'application_id': applicationId!
        },
        dateKey: 'scheduled_at',
        dateLabel: 'Choose interview date and time',
        includeTime: true,
        submitLabel: 'Schedule interview',
        successMessage: 'The interview was scheduled.',
      );
}
