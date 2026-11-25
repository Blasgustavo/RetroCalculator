import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el manifiesto declara checksum, versión y duración', () {
    final Map<String, dynamic> manifest =
        jsonDecode(File('assets/catalog/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['schemaVersion'], 1);
    final List<dynamic> entries = manifest['entries'] as List<dynamic>;
    final Map<String, dynamic> entry = entries.single as Map<String, dynamic>;
    expect(entry['id'], 'lcd_classica');
    expect(entry['nameKey'], 'skinLcdClassicaName');
    expect(entry['rewardDurationHours'], 24);
    final String yaml = entry['definitionYaml'] as String;
    expect(
      yaml,
      File(
        entry['definition'] as String,
      ).readAsStringSync().replaceAll('\r\n', '\n'),
    );
    expect(sha256.convert(utf8.encode(yaml)).toString(), entry['checksum']);
    expect(entry['capabilities'], isEmpty);
  });
}
