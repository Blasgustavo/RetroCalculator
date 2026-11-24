import 'package:flutter/material.dart';

import '../features/calculator/presentation/calculator_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const CalculatorPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const CalculatorPage(),
          settings: settings,
        );
    }
  }
}
