// Scaffolding de una capacidad nueva (T52, plan V8).
//
// Uso: dart run tool/design/new_capability.dart <id>
// Crea lib/features/calculator/domain/capabilities/<id>_capability.dart y un
// test rojo en test/unit/calculator/capabilities/. La lógica la escribe una
// persona (ADR-0007).

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/design/new_capability.dart <id>');
    exit(64);
  }
  final String id = args.first;
  final String className = '${_pascal(id)}Capability';
  final File capFile = File(
    'lib/features/calculator/domain/capabilities/${id}_capability.dart',
  );
  final File testFile = File(
    'test/unit/calculator/capabilities/${id}_capability_test.dart',
  );
  capFile.parent.createSync(recursive: true);
  testFile.parent.createSync(recursive: true);

  capFile.writeAsStringSync('''
import '../capabilities/capability.dart';

class $className implements CalculatorCapability {
  const $className();

  @override
  Set<String> get operators => const <String>{'+', '-', '*', '/'};

  @override
  Set<String> get functions => const <String>{};

  @override
  Set<String> get constants => const <String>{};

  @override
  double constant(String name) => throw UnimplementedError();

  @override
  double callFunction(String name, double value, dynamic mode) =>
      throw UnimplementedError();

  @override
  double factorial(double value) => throw UnimplementedError();
}
''');

  testFile.writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/${id}_capability.dart';

void main() {
  test('$className es una capacidad registrable', () {
    const capability = $className();
    expect(capability, isNotNull);
  });
}
''');

  stdout.writeln('Creado ${capFile.path} y ${testFile.path}');
}

String _pascal(String value) {
  return value
      .split(RegExp(r'[_-]'))
      .where((String part) => part.isNotEmpty)
      .map((String part) => part[0].toUpperCase() + part.substring(1))
      .join();
}
