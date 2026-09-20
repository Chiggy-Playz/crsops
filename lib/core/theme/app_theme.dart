import 'package:flutter/material.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5),
      brightness: brightness,
    ),
  );
}
