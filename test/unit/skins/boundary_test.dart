import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las skins no importan el motor y el motor no importa Flutter', () {
    final List<File> skinFiles =
        <Directory>[
              Directory('lib/features/skins'),
              Directory('lib/core/design_system'),
            ]
            .expand(
              (Directory directory) =>
                  directory.listSync(recursive: true).whereType<File>(),
            )
            .where((File file) => file.path.endsWith('.dart'))
            .toList();
    for (final File file in skinFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('features/calculator/domain')),
        reason: file.path,
      );
    }
    final List<File> engineFiles = Directory('lib/features/calculator/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();
    for (final File file in engineFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains("package:flutter")),
        reason: file.path,
      );
    }
  });
}
