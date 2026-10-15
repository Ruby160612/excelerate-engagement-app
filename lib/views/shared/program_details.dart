import 'package:flutter/material.dart';

import '../../models/program.dart';
import '../../widgets/page_layout.dart';

class ProgramDetailsView extends StatelessWidget {
  const ProgramDetailsView({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) =>
      PageLayout(title: program.title, child: Text(program.description));
}
