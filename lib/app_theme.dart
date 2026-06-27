import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: Brightness.dark,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardColor: const Color(0xFF121212),
    colorScheme: _darkColorScheme,
    typography: Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: _darkColorScheme,
    ),
    fontFamily: 'Roboto',
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),
  );
}
