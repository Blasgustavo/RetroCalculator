import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el JSON descargado basta para recalcular el checksum', () {
    final Map<String, dynamic> manifest =
        jsonDecode(File('assets/catalog/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final Map<String, dynamic> entry =
        (manifest['entries'] as List<dynamic>).single as Map<String, dynamic>;
    final String yaml = File(
      entry['definition'] as String,
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(entry['definitionYaml'], yaml);
    expect(
      sha256.convert(utf8.encode(entry['definitionYaml'] as String)).toString(),
      entry['checksum'],
    );
  });
}
