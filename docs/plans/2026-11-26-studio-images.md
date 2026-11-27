# V6 — Imágenes en el Studio (T35–T39)

## Contexto

V1–V5 dejaron el Studio con validación de imágenes (existencia, tamaño, dimensiones, checksum) y el nodo `image` reservado en la whitelist, pero no hay forma de importarlas ni de generar `images.g.dart`. V6 cierra ese hueco.

## Alcance

- Incluye: importación T35, validación T36, artefactos T37, nodo `image` T38, idempotencia T39, tests y actualización del checkbox.
- Excluye: sonidos (V10), publicación (V7), goldens.

## Arquitectura

- `tool/design/studio/studio_controller.dart`: método `importImage(String filePath, ...)` que valida PNG, calcula SHA-256 y dimensiones, y añade un `ImageSpec` al documento. Devuelve `String?` (null = éxito).
- `tool/design/validate.dart`: ya valida imágenes (existencia, tamaño, dimensiones, checksum).
- `tool/design/compile.dart`: ya emite `images.g.dart`.
- `lib/core/widgets/spec_renderer.dart`: resolver nodo `image` por id (T38, depende de V3).

## Tareas

- [ ] T35 — Importación.
- [ ] T36 — Validación.
- [ ] T37 — Artefactos (ya emitidos por compile.dart).
- [ ] T38 — Nodo `image` en SpecRenderer.
- [ ] T39 — Idempotencia.

## Verificación final

`flutter analyze`, `flutter test`, `dart run tool/design/validate.dart`, `dart run tool/design/compile.dart && git diff --exit-code`.