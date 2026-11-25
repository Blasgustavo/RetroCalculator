# ADR-0008: Sonidos locales para teclas con `audioplayers`

## Estado
Aceptado | 2026-11-24

## Contexto

El editor debe poder configurar sonidos para eventos de la calculadora. La calculadora es siempre gratuita y ningún elemento cosmético puede bloquear el cálculo. Los plugins nativos se aíslan en `lib/platform/`, y el catálogo descargado es dato, nunca código.

## Decisión

1. El bloque `sounds` de `design/app.design.json` asocia eventos (`keyTap`, `equals`, `error`, `skinChange`) a archivos locales en `assets/sounds/`.
2. Se añade `audioplayers` como dependencia y el reproductor se aísla en `lib/platform/audio/`. El resto de la app consume una interfaz `SoundPlayer`, sin importar el plugin.
3. Los archivos se generan de forma determinista con `tool/sounds/generate.dart` (WAV breves) y se versionan como assets. No se descargan sonidos del catálogo remoto.
4. Los sonidos son cosméticos y opcionales: si un archivo declarado no existe, el validador falla en build-time. En runtime, cualquier fallo de audio se ignora y nunca interrumpe un cálculo. Se respeta el modo silencio del dispositivo.
5. El editor puede activar o desactivar sonidos y asignar eventos, pero no puede cargar archivos arbitrarios ni ejecutar código asociado a un sonido.

## Consecuencias

- Positivas: la respuesta táctil se configura desde la misma herramienta que las skins; los assets son reproducibles y revisables; un fallo de audio degrada solo la experiencia, nunca el resultado.
- Negativas: se añade una dependencia y su configuración nativa; `flutter pub get` regenera artefactos de Windows que hay que restaurar durante la fase Android; hay que versionar unos pocos binarios WAV.

## Alternativas descartadas

- **Tonos generados en Dart sin dependencia**: evita el plugin, pero no permite diseñar el sonido desde el editor y suena menos natural.
- **Sonidos remotos en el manifiesto**: mezcla contenido descargado con ejecución de audio y complica la validación offline.
- **Reproductor dentro de `features/calculator/`**: acopla la capa de cálculo a un plugin nativo y rompe el aislamiento de `lib/platform/`.

## Referencias

- `docs/plans/2026-11-24-design-studio-compiler.md`
- `docs/adr/0004-arquitectura-modular-y-generador.md`
