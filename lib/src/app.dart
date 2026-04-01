import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class UjikomApp extends StatelessWidget {
  const UjikomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D8B73),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Nokomi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF0F1419),
          foregroundColor: Color(0xFFE8EAED),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1F2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2D3748)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
