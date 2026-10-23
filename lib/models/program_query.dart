import 'program.dart';

/// Shared search semantics for the catalogue UI and service implementations.
class ProgramQuery {
  const ProgramQuery({this.search, this.category});

  final String? search;
  final String? category;

  bool matches(Program program) {
    final text = search?.trim().toLowerCase() ?? '';
    final selectedCategory = category?.trim().toLowerCase() ?? '';
    return (selectedCategory.isEmpty ||
            program.category.toLowerCase() == selectedCategory) &&
        (text.isEmpty ||
            program.title.toLowerCase().contains(text) ||
            program.description.toLowerCase().contains(text));
  }

  List<Program> apply(Iterable<Program> programs) =>
      programs.where(matches).toList(growable: false);
}
