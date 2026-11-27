import '../capabilities/capability.dart';
import '../engine/angle_mode.dart';

class CalculatorProfile {
  const CalculatorProfile({
    required this.id,
    required this.labelKey,
    required this.capability,
    required this.isScientific,
    required this.defaultAngleMode,
    required this.decimalDigits,
    required this.keyRows,
  });

  final String id;
  final String labelKey;
  final CalculatorCapability capability;
  final bool isScientific;
  final AngleMode defaultAngleMode;
  final int decimalDigits;
  final List<List<String>> keyRows;
}
