import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.calculatorTitle)),
      body: const Center(child: Text(AppStrings.readyMessage)),
    );
  }
}
