// Validación en vivo de fórmulas del RetroDesign Studio (T25, plan V4).
//
// Espejo de la comprobación build-time: delega en el helper compartido para
// que los dos caminos usen los mismos mensajes y las mismas cotas (ADR-0016).
// T27 sigue siendo la barrera de compilación; aquí solo se muestra el error
// mientras se escribe, sin ejecutar la fórmula.

import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';

import '../formula_validation.dart';
export '../formula_validation.dart' show maxFormulaLength;

/// Errores legibles para una fórmula, sin evaluarla numéricamente.
List<String> validateStudioFormula({
  required String name,
  required String expression,
  required List<String> inputs,
  required String capabilityId,
  required Set<String> formulaNames,
}) {
  final CalculatorCapability capability = capabilityId == 'scientific'
      ? const ScientificCapability()
      : const BasicCapability();
  final FormulaValidation result = validateFormula(
    name: name,
    expression: expression,
    inputs: inputs,
    formulaNames: formulaNames,
    functions: capability.functions,
    constants: capability.constants,
  );
  return result.issues
      .map((FormulaIssue issue) => issue.message)
      .toList(growable: false);
}
