import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandCream,
      body: Center(
        child: Image.asset(
          'assets/app_icon_light_version.png',
          width: 128,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
