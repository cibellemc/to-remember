import 'package:flutter/material.dart';

class _HorizontalSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _HorizontalSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class AppTheme {
  static final ThemeData theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF009688), // Teal
      primary: const Color(0xFF009688),
      secondary: const Color(0xFF4CAF50), // Green
      tertiary: const Color(0xFFFFC107), // Amber for highlights
      surface: const Color(0xFFF5F5F5), // Light Grey background
    ),
    useMaterial3: true,

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _HorizontalSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: _HorizontalSlidePageTransitionsBuilder(),
        TargetPlatform.linux: _HorizontalSlidePageTransitionsBuilder(),
        TargetPlatform.macOS: _HorizontalSlidePageTransitionsBuilder(),
        TargetPlatform.windows: _HorizontalSlidePageTransitionsBuilder(),
      },
    ),

    // Component Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
