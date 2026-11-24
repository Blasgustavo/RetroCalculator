import '../capabilities/basic_capability.dart';
import '../capabilities/scientific_capability.dart';
import '../engine/angle_mode.dart';
import 'calculator_profile.dart';

class CalculatorProfiles {
  const CalculatorProfiles._();

  static const CalculatorProfile normal = CalculatorProfile(
    id: CalculatorProfileId.normal,
    labelKey: 'modeNormal',
    capability: BasicCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 8,
    keyRows: <List<String>>[
      <String>['C', '⌫', '%', '/'],
      <String>['7', '8', '9', '*'],
      <String>['4', '5', '6', '-'],
      <String>['1', '2', '3', '+'],
      <String>['±', '0', '.', '='],
    ],
  );

  static const CalculatorProfile scientific = CalculatorProfile(
    id: CalculatorProfileId.scientific,
    labelKey: 'modeScientific',
    capability: ScientificCapability(),
    defaultAngleMode: AngleMode.degrees,
    decimalDigits: 10,
    keyRows: <List<String>>[
      <String>['sin(', 'cos(', 'tan(', '(', ')'],
      <String>['asin(', 'acos(', 'atan(', '1/x', 'x²'],
      <String>['ln(', 'log(', 'sqrt(', '^', '!'],
      <String>['pi', 'e', '%', 'C', '⌫'],
      <String>['7', '8', '9', '/', '*'],
      <String>['4', '5', '6', '-', '+'],
      <String>['1', '2', '3', '±', '='],
      <String>['0', '.', 'MC', 'MR', 'M+'],
    ],
  );
}
