// Publicación del catálogo del RetroDesign Studio (V7).
//
// Construye el directorio del canal con manifiesto, assets y versión
// incrementada. Firma Ed25519 si existe CATALOG_PRIVATE_KEY en el entorno.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  String channel = 'prod';
  int? rollback;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--channel' && i + 1 < args.length) {
      channel = args[++i];
    } else if (args[i] == '--rollback' && i + 1 < args.length) {
      rollback = int.tryParse(args[++i]);
    }
  }

  final File designFile = File('design/app.design.json');
  if (!designFile.existsSync()) {
    stderr.writeln('No existe design/app.design.json');
    exit(1);
  }
  final Map<String, Object?> design =
      jsonDecode(designFile.readAsStringSync()) as Map<String, Object?>;

  final int version = (design['version'] as num?)?.toInt() ?? 1;
  final int nextVersion = rollback ?? version + 1;

  final Directory outDir = Directory('build/catalog/$channel/v$nextVersion');
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);

  final Directory assetsDir = Directory('design/assets');
  if (assetsDir.existsSync()) {
    for (final FileSystemEntity entity in assetsDir.listSync()) {
      if (entity is File) {
        entity.copySync(
          '${outDir.path}/${entity.path.split(Platform.pathSeparator).last}',
        );
      }
    }
  }

  final String payload = jsonEncode(design);
  final String checksum = sha256.convert(utf8.encode(payload)).toString();

  String signature = '';
  final String? privateKeyHex = Platform.environment['CATALOG_PRIVATE_KEY'];
  if (privateKeyHex != null && privateKeyHex.isNotEmpty) {
    try {
      final List<int> seed = _hexToBytes(privateKeyHex);
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPairFromSeed(seed);
      final sig = await algorithm.sign(utf8.encode(payload), keyPair: keyPair);
      signature = sig.bytes
          .map((int b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      stdout.writeln('Firma calculada con Ed25519.');
    } catch (error) {
      stderr.writeln('No se pudo firmar: $error');
    }
  } else {
    stderr.writeln('CATALOG_PRIVATE_KEY no definida: manifiesto sin firma.');
  }

  final String manifest = jsonEncode(<String, Object?>{
    'version': nextVersion,
    'channel': channel,
    'definition': 'design/app.design.json',
    'checksum': checksum,
    'signature': signature,
  });

  File('${outDir.path}/manifest.json').writeAsStringSync(manifest);
  stdout.writeln('Publicado $channel v$nextVersion en ${outDir.path}');
}

List<int> _hexToBytes(String hex) {
  final List<int> bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes;
}
