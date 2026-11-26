import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';

import '../../../tool/design/formula_validation.dart';
import '../../../tool/design/validate.dart';

void main() {
  CalculatorCapability capabilityOf(String id) => id == 'scientific'
      ? const ScientificCapability()
      : const BasicCapability();

  FormulaValidation comprobar(
    String expression, {
    List<String> inputs = const <String>[],
    String name = 'resultado',
    String capabilityId = 'basic',
    Set<String> formulaNames = const <String>{},
  }) {
    final CalculatorCapability capability = capabilityOf(capabilityId);
    return validateFormula(
      name: name,
      expression: expression,
      inputs: inputs,
      formulaNames: formulaNames,
      functions: capability.functions,
      constants: capability.constants,
    );
  }

  List<String> mensajes(FormulaValidation result) =>
      result.issues.map((FormulaIssue issue) => issue.message).toList();

  test('acepta una fórmula con variables declaradas en minúsculas', () {
    final FormulaValidation result = comprobar(
      'base*(1+tasa/100)',
      inputs: const <String>['base', 'tasa'],
    );

    expect(result.isValid, isTrue, reason: mensajes(result).toString());
    expect(result.issues, isEmpty);
    expect(result.dependencies, isEmpty);
  });

  test('un input que comparte nombre con otra fórmula no crea dependencia', () {
    final FormulaValidation result = comprobar(
      'base',
      inputs: const <String>['base'],
      formulaNames: const <String>{'base'},
    );

    expect(result.isValid, isTrue, reason: mensajes(result).toString());
    expect(result.dependencies, isEmpty);
  });

  test('un input que comparte nombre con la fórmula no es recursivo', () {
    final FormulaValidation result = comprobar(
      'base',
      name: 'base',
      inputs: const <String>['base'],
      formulaNames: const <String>{'base'},
    );

    expect(result.isValid, isTrue, reason: mensajes(result).toString());
    expect(mensajes(result), isNot(contains('fórmula recursiva: base')));
  });

  test('rechaza entradas que colisionan al normalizar, en cualquier orden', () {
    for (final List<String> inputs in <List<String>>[
      <String>['Base', 'BASE'],
      <String>['BASE', 'Base'],
    ]) {
      final FormulaValidation result = comprobar('base+1', inputs: inputs);

      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'duplicateVariable');
      expect(
        result.issues.single.message,
        startsWith('variable declarada dos veces: '),
      );
      expect(result.issues.single.message, endsWith(' (duplicateVariable)'));
    }
  });

  test('rechaza un identificador no declarado como variable', () {
    final FormulaValidation result = comprobar(
      'base*otro',
      inputs: const <String>['base'],
    );

    expect(mensajes(result), contains('variable no declarada: otro'));
  });

  test('pi solo es válida en la capability que la declara como constante', () {
    final FormulaValidation basica = comprobar('pi', capabilityId: 'basic');
    final FormulaValidation cientifica = comprobar(
      'pi',
      capabilityId: 'scientific',
    );

    expect(mensajes(basica), contains('variable no declarada: pi'));
    expect(cientifica.isValid, isTrue, reason: mensajes(cientifica).toString());
  });

  test('avisa cuando la fórmula excede el presupuesto de 200 nodos', () {
    // 12 grupos de 9 sumandos = 215 nodos con profundidad 20: supera la cota
    // de nodos sin llegar a la de profundidad y cabe en 256 caracteres.
    final String expression = List<String>.generate(
      12,
      (_) => '(${List<String>.generate(9, (_) => '1').join('+')})',
    ).join('+');
    expect(expression.length, lessThanOrEqualTo(maxFormulaLength));

    final FormulaValidation result = comprobar(expression);

    expect(
      mensajes(result),
      contains('fórmula excede el presupuesto de 200 nodos'),
    );
  });

  test('avisa cuando la fórmula excede los 64 niveles de profundidad', () {
    final String expression = List<String>.generate(70, (_) => '1').join('+');

    final FormulaValidation result = comprobar(expression);

    expect(mensajes(result), contains('fórmula demasiado profunda'));
  });

  test('validaJson sitúa las entradas duplicadas en profiles[i].inputs', () {
    final File seedFile = File('design/app.design.json');
    final Map<String, Object?> json =
        jsonDecode(seedFile.readAsStringSync()) as Map<String, Object?>;
    final Map<String, Object?> profile =
        (json['profiles']! as List<Object?>)[2] as Map<String, Object?>;
    profile['inputs'] = <String>['Base', 'BASE'];

    final List<ValidationIssue> issues = validateJson(
      json,
      projectRoot: Directory.current,
      assetsRoot: Directory('design${Platform.pathSeparator}assets'),
    );

    expect(
      issues.map((ValidationIssue issue) => issue.path),
      contains('profiles[2].inputs'),
    );
    expect(
      issues.map((ValidationIssue issue) => issue.message),
      contains(contains('duplicateVariable')),
    );
  });

  test('validaJson informa una sola vez varias colisiones de inputs', () {
    final File seedFile = File('design/app.design.json');
    final Map<String, Object?> json =
        jsonDecode(seedFile.readAsStringSync()) as Map<String, Object?>;
    final Map<String, Object?> profile =
        (json['profiles']! as List<Object?>)[2] as Map<String, Object?>;
    profile['inputs'] = <String>['a', 'A', 'b', 'B'];

    final List<ValidationIssue> issues = validateJson(
      json,
      projectRoot: Directory.current,
      assetsRoot: Directory('design${Platform.pathSeparator}assets'),
    );
    final List<ValidationIssue> duplicates = issues
        .where((ValidationIssue issue) => issue.path == 'profiles[2].inputs')
        .toList();

    expect(duplicates, hasLength(1));
    expect(duplicates.single.message, contains('duplicateVariable'));
  });
}
