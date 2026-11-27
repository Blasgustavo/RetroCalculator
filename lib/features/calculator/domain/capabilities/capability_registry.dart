import 'basic_capability.dart';
import 'capability.dart';
import 'scientific_capability.dart';

/// Registro inmutable de capacidades disponibles (ADR-0007).
class CapabilityRegistry {
  const CapabilityRegistry();

  static const CapabilityRegistry instance = CapabilityRegistry();

  CalculatorCapability resolve(String id) {
    return switch (id) {
      'scientific' => const ScientificCapability(),
      _ => const BasicCapability(),
    };
  }

  bool contains(String id) => id == 'basic' || id == 'scientific';

  Iterable<String> get ids => const <String>['basic', 'scientific'];
}
