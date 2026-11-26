# ADR-0014: Entrypoint del RetroDesign Studio

## Estado
Aceptado | 2026-11-25

## Contexto
El plan V4 (T21) proponía `lib/tool_preview_main.dart` como entrypoint alternativo del Studio. El shell necesita reutilizar `DesignSeed`, `designNodeTypes` y la serialización de nodos que viven en `tool/design/`, porque la fuente de verdad es `design/app.design.json` y el preview debe usar el mismo `SpecRenderer` de la app.

Durante la implementación se reprodujo el bloqueo con `flutter build bundle -t lib/tool_preview_main.dart`: el analyzer y el compilador frontal resuelven los imports de un archivo bajo `lib/` como URIs de paquete (`package:retro_calculator/...`), por lo que `../tool/design/studio/studio_app.dart` se recorta en la raíz del paquete y se intenta leer como `lib/tool/design/...`. El build terminó con `Target kernel_snapshot_program failed`. Probar `../../tool/...` y `package:retro_calculator/../tool/...` produce el mismo error; `// ignore: uri_does_not_exist` no resuelve `StudioApp`. En cambio, `flutter build bundle -t tool/design/studio/main.dart` termina con éxito.

## Decisión
El entrypoint del Studio es `tool/design/studio/main.dart` y se lanza con `flutter run -t tool/design/studio/main.dart`. Todo el código del editor permanece bajo `tool/design/studio/`; `lib/` solo conserva la app de producción y no importa el Studio. Se actualiza el plan V4 para reflejar esta ruta.

## Consecuencias
- Positivas: el editor y sus dependencias de herramienta quedan fuera del artefacto de la app; se mantiene la regla de que las librerías de edición visual solo se importan desde `tool/`; el comando de arranque está verificado con `flutter build bundle`.
- Negativas: la ruta difiere del texto original del plan, así que cualquier documentación que cite `lib/tool_preview_main.dart` debe corregirse.

## Alternativas descartadas
- Mover el shell y el modelo `DesignSeed` a `lib/`: exigiría trasladar `schema.dart` y adaptar `validate.dart`, `compile.dart` y sus tests, duplicando o rompiendo la fuente de verdad del compilador para satisfacer solo la posición del entrypoint.
- Duplicar el modelo dentro de `lib/`: crea dos esquemas que pueden divergir y rompe la validación previa a la escritura.
- `// ignore: uri_does_not_exist`: oculta el error del analyzer pero el compilador frontal sigue sin encontrar el archivo.

## Referencias
- `docs/plans/2026-11-24-design-studio-v2.md` (V4, T21)
- `tool/design/studio/main.dart`
