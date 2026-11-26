// Persistencia del RetroDesign Studio (T28, plan V4).
//
// Dart puro de herramienta: ni Flutter ni UI. Guardar escribe el JSON canónico
// con LF y un único salto final; recargar lo lee y lo reconstruye. No valida ni
// compila: esa barrera pertenece a Aplicar (T27), que reutiliza la misma
// serialización de nodos de `studio_apply.dart`.

import 'dart:convert';
import 'dart:io';

import '../compile.dart' show defaultDesignPath;
import '../schema.dart';
import 'studio_apply.dart' show studioSeedToJson;

/// JSON canónico de [document]: LF y exactamente un `'\n'` final.
String studioEncodeDocument(DesignSeed document) {
  final String encoded = jsonEncode(
    studioSeedToJson(document),
  ).replaceAll('\r\n', '\n');
  return '$encoded\n';
}

/// Resultado de escribir un documento en disco.
class StudioSaveResult {
  const StudioSaveResult({required this.path, required this.bytes});

  /// Ruta efectiva del archivo escrito (absoluta si se resolvió una relativa).
  final String path;

  /// Bytes UTF-8 escritos.
  final int bytes;

  bool get ok => bytes > 0;
}

/// Escribe [document] en [designPath], sin validar ni compilar.
///
/// Las rutas relativas se resuelven dentro de [projectRoot] y las absolutas se
/// usan tal cual. El directorio padre se crea si no existe.
StudioSaveResult saveStudioDocument(
  DesignSeed document, {
  required Directory projectRoot,
  String designPath = defaultDesignPath,
}) {
  final File file = _designFile(projectRoot, designPath);
  final String encoded = studioEncodeDocument(document);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(encoded);
  return StudioSaveResult(path: file.path, bytes: utf8.encode(encoded).length);
}

/// Lee y reconstruye el documento de [designPath].
///
/// Un archivo ausente o vacío produce un `StateError` legible. Un JSON inválido
/// propaga el `FormatException` de `jsonDecode`.
DesignSeed loadStudioDocumentFromDisk({
  required Directory projectRoot,
  String designPath = defaultDesignPath,
}) {
  final File file = _designFile(projectRoot, designPath);
  if (!file.existsSync()) {
    throw StateError('No existe el documento de diseño: ${file.path}');
  }
  final String content = file.readAsStringSync();
  if (content.trim().isEmpty) {
    throw StateError('El documento de diseño está vacío: ${file.path}');
  }
  return DesignSeed.fromJson(jsonDecode(content));
}

/// Misma resolución de rutas que `applyStudioDocument`: relativa a la raíz del
/// proyecto, absoluta tal cual, con separadores tanto `/` como `\`.
File _designFile(Directory projectRoot, String designPath) {
  final File direct = File(designPath);
  if (direct.isAbsolute) return direct;
  return File(_join(projectRoot.path, designPath.split(RegExp(r'[\\/]'))));
}

String _join(String root, List<String> parts) =>
    <String>[root, ...parts].join(Platform.pathSeparator);
