import '../capabilities/capability.dart';
import '../engine/angle_mode.dart';

enum CalculatorProfileId { normal, scientific }

class CalculatorProfile {
  const CalculatorProfile({
    required this.id,
    required this.labelKey,
    required this.capability,
    required this.defaultAngleMode,
    required this.decimalDigits,
    required this.keyRows,
  });

  final CalculatorProfileId id;
  final String labelKey;
  final CalculatorCapability capability;
  final AngleMode defaultAngleMode;
  final int decimalDigits;
  final List<List<String>> keyRows;

  bool get isScientific => id == CalculatorProfileId.scientific;
}
