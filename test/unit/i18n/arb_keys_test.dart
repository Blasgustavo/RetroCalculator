import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los cinco ARB tienen exactamente las mismas 44 claves', () {
    const List<String> files = <String>[
      'app_en.arb',
      'app_es.arb',
      'app_es_PE.arb',
      'app_pt.arb',
      'app_pt_BR.arb',
    ];
    final List<Set<String>> keySets = files.map((String file) {
      final Object? decoded = jsonDecode(
        File('lib/l10n/$file').readAsStringSync(),
      );
      return (decoded! as Map<String, Object?>).keys.toSet();
    }).toList();
    for (final Set<String> keys in keySets) {
      expect(keys, keySets.first);
    }
    expect(keySets.first, hasLength(44));
  });
}
