// Entrypoint del compiler v2: valida la semilla antes de escribir nada y
// reutiliza los modelos y el validador de tool/design/. Los archivos v1
// (manifest.json y skin_tokens_lcd_classica.dart) no se reescriben aquí.

import 'dart:convert';
import 'dart:io';

import 'artifacts.dart';
import 'schema.dart';
import 'validate.dart';

const String defaultDesignPath = 'design/app.design.json';

class CompileReport {
  const CompileReport({required this.issues, required this.written});

  final List<ValidationIssue> issues;
  final List<String> written;

  bool get ok => issues.isEmpty;
}

/// Compila una semilla. `formatOutput=false` se usa en tests unitarios para
/// evitar subprocessos; el CLI siempre formatea los cinco artefactos Dart.
CompileReport compileDesign({
  required Directory projectRoot,
  File? designFile,
  bool formatOutput = true,
}) {
  final File file =
      designFile ?? File(_join(projectRoot.path, defaultDesignPath.split('/')));
  if (!file.existsSync()) {
    return CompileReport(
      issues: <ValidationIssue>[
        ValidationIssue(defaultDesignPath, 'archivo de diseño no existe'),
      ],
      written: const <String>[],
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    return CompileReport(
      issues: <ValidationIssue>[
        ValidationIssue(defaultDesignPath, 'JSON no válido: ${error.message}'),
      ],
      written: const <String>[],
    );
  }
  if (decoded is! Map<String, Object?>) {
    return CompileReport(
      issues: <ValidationIssue>[
        const ValidationIssue(defaultDesignPath, 'debe ser un objeto JSON'),
      ],
      written: const <String>[],
    );
  }

  final List<ValidationIssue> issues = validateJson(
    decoded,
    projectRoot: projectRoot,
    assetsRoot: Directory(_join(file.parent.path, <String>['assets'])),
  );
  if (issues.isNotEmpty) {
    return CompileReport(issues: issues, written: const <String>[]);
  }

  final DesignSeed design = DesignSeed.fromJson(decoded);
  final List<GeneratedFile> files = <GeneratedFile>[
    ...buildArtifacts(design, root: projectRoot, designFile: file),
    GeneratedFile(
      manifestV2Path,
      '${jsonEncode(buildManifestV2(design, root: projectRoot, designFile: file))}\n',
    ),
  ];

  final List<String> written = <String>[];
  for (final GeneratedFile artifact in files) {
    final File output = File(_join(projectRoot.path, artifact.path.split('/')));
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(artifact.content);
    written.add(artifact.path);
  }

  if (formatOutput) {
    _formatDart(
      projectRoot,
      written.where((String path) => path.endsWith('.dart')).toList(),
    );
  }
  return CompileReport(issues: const <ValidationIssue>[], written: written);
}

void _formatDart(Directory root, List<String> paths) {
  if (paths.isEmpty) return;
  final List<String> absolute = paths
      .map((String path) => _join(root.path, path.split('/')))
      .toList();
  final ProcessResult result = Process.runSync(
    Platform.resolvedExecutable,
    <String>['format', ...absolute],
  );
  if (result.exitCode != 0) {
    throw StateError('dart format falló:\n${result.stdout}\n${result.stderr}');
  }
}

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Uso: dart run tool/design/compile.dart [archivo]');
    exitCode = 64;
    return;
  }
  final Directory root = Directory.current;
  final File designFile = args.isEmpty
      ? File(_join(root.path, defaultDesignPath.split('/')))
      : File(args.first);
  try {
    final CompileReport report = compileDesign(
      projectRoot: root,
      designFile: designFile,
    );
    if (!report.ok) {
      for (int i = 0; i < report.issues.length; i++) {
        stderr.writeln('${i + 1}. ${report.issues[i]}');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln('✓ compilado: ${report.written.join(', ')}');
  } on Object catch (error) {
    stderr.writeln('✗ compiler: $error');
    exitCode = 1;
  }
}

String _join(String root, List<String> parts) =>
    <String>[root, ...parts].join(Platform.pathSeparator);
