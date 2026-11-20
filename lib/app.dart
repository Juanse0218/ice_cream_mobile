import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

class IceCreamApp extends StatelessWidget {
  const IceCreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICE CREAM',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}