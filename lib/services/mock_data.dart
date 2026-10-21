import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Sample notices for the in-memory demo backend only.
const List<Map<String, dynamic>> mockAnnouncements = [
  {
    'id': 'notice-001',
    'title': 'Welcome to your Excelerate community',
    'body': 'Your home brings together learning opportunities, career tools '
        'and the latest updates from Excelerate. Open Programs to explore '
        'what is available.',
    'published_at': '2026-10-16T09:00:00Z',
    'audience': 'all',
  },
  {
    'id': 'notice-002',
    'title': 'Make your next career move',
    'body': 'Keep your CV up to date and explore development programs '
        'that match the skills you want to build.',
    'published_at': '2026-10-16T10:00:00Z',
    'audience': 'learner',
  },
  {
    'id': 'notice-003',
    'title': 'Keep your recruitment moving',
    'body': 'Review candidate applications, update your shortlist and '
        'schedule interviews from your quick links.',
    'published_at': '2026-10-16T10:00:00Z',
    'audience': 'admin',
  },
];

const programsAsset = 'assets/data/programs.json';

Future<List<Map<String, dynamic>>> loadMockPrograms() async {
  final text = await rootBundle.loadString(programsAsset);
  return [
    for (final item in jsonDecode(text) as List)
      Map<String, dynamic>.from(item as Map),
  ];
}
