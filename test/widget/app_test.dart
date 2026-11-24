import 'package:flutter_test/flutter_test.dart';

import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/core/constants/app_strings.dart';

void main() {
  testWidgets('la app arranca y muestra la calculadora', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RetroCalculatorApp());

    expect(find.text(AppStrings.calculatorTitle), findsOneWidget);
    expect(find.text(AppStrings.readyMessage), findsOneWidget);
  });
}
