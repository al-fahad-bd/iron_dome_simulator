import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Iron Dome Simulation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          titleMedium: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          bodyLarge: TextStyle(fontFamily: 'monospace', letterSpacing: 0.5,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
