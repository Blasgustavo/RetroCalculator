// Entrypoint del RetroDesign Studio (T21, plan V4).
//
// Se lanza con `flutter run -t tool/design/studio/main.dart`.
//
// No puede vivir en `lib/tool_preview_main.dart`: un archivo dentro de `lib/`
// solo puede importar otros archivos de `lib/` (el analyzer resuelve sus
// imports como URIs de paquete y el CFE hace lo mismo al compilar el paquete,
// verificado con `flutter build bundle -t lib/tool_preview_main.dart`). El
// shell necesita `DesignSeed` de `tool/design/schema.dart`, así que el
// entrypoint tiene que estar en `tool/`.

import 'package:flutter/material.dart';

import 'studio_app.dart';

void main() => runApp(const StudioApp());
