import 'package:flutter/material.dart';

abstract final class AppThemes {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4500))
            .copyWith(
                primary: const Color(0xFFFF4500), onPrimary: Colors.white),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      );
}
