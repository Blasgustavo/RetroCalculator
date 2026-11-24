import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'core/design_system/design_system.dart';

class RetroCalculatorApp extends StatelessWidget {
  const RetroCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroCalculator',
      debugShowCheckedModeBanner: false,
      theme: DSTheme.toMaterialTheme(Brightness.light),
      darkTheme: DSTheme.toMaterialTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
