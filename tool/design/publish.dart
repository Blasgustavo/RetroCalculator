// Publicación del catálogo del RetroDesign Studio (V7).
//
// Construye el directorio del canal con manifiesto, assets y versión
// incrementada. La firma Ed25519 se calcula si existe la clave privada en el
// entorno (CATALOG_PRIVATE_KEY); en caso contrario se deja vacía y se advierte.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;

void main(List<String> args) async {
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

  // Copiar assets.
  final Directory assetsDir = Directory('design/assets');
  if (assetsDir.existsSync()) {
    for (final FileSystemEntity entity in assetsDir.listSync()) {
      if (entity is File) {
        entity.copySync('${outDir.path}/${entity.path.split(Platform.pathSeparator).last}');
      }
    }
  }

  final String manifest = jsonEncode(<String, Object?>{
    'version': nextVersion,
    'channel': channel,
    'definition': 'design/app.design.json',
    'checksum': sha256.convert(utf8.encode(jsonEncode(design))).toString(),
  });

  File('${outDir.path}/manifest.json').writeAsStringSync(manifest);
  stdout.writeln('Publicado $channel v$nextVersion en ${outDir.path}');
}