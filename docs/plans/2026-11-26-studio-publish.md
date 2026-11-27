# V7 — Publicación y app instalada (T40–T48)

## Contexto

V1–V6 dejaron el Studio validando y compilando el diseño. Falta publicar versiones firmadas para que una app ya instalada las reciba y aplique. V7 implementa el paquete firmado, el CLI y el cliente.

## Alcance

- Incluye: T40 paquete, T41 firma Ed25519, T42 CLI, T43 hosting estático (docs), T44 cliente, T45 aplicación, T46 sondeo, T47 fallos, T48 feedback.
- Excluye: sonidos (V10), goldens.

## Arquitectura

- `tool/design/publish.dart`: construye el directorio del canal con manifiesto, assets y versión incrementada; firma con Ed25519 (cryptography).
- `lib/platform/catalog/`: cliente, controller, sondeo, aplicación.
- Clave pública fijada en `lib/platform/catalog/public_key.dart`.

## Tareas

- [ ] T40 — Paquete.
- [ ] T41 — Firma.
- [ ] T42 — CLI.
- [ ] T43 — Hosting estático (docs).
- [ ] T44 — Cliente.
- [ ] T45 — Aplicación.
- [ ] T46 — Sondeo.
- [ ] T47 — Fallos.
- [ ] T48 — Feedback.

## Verificación final

`flutter analyze`, `flutter test`, `dart run tool/design/publish.dart --channel prod`.