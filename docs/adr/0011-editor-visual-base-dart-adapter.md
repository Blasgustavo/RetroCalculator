# ADR-0011: Editor visual del Studio sobre base Dart con adaptador, sin fork externo

## Estado
Aceptado | 2026-11-24

## Contexto

El usuario pidió un editor drag-and-drop intuitivo, similar a Figma, y planteó la alternativa de forkar otra herramienta de diseño. Flutter no incluye un editor visual completo en el SDK: solo gestos y `CustomPainter`. Se evaluaron cinco rutas: construir el canvas desde cero, `fluttercanvas` (MIT, pub.dev v0.3.0), `flutter_advanced_canvas_editor`, fork de Penpot (MPL-2.0) y SDK de tldraw (licencia comercial en producción).

## Decisión

1. El RetroDesign Studio se implementa en **Flutter/Dart**, con objetivo Windows como herramienta de desarrollo (no una quinta plataforma de producto; ADR-0002).
2. Se hace un **spike con timebox** de `fluttercanvas`: se usan sus capacidades de canvas, capas, drag/resize, undo/redo y serialización JSON como base del editor.
3. Su modelo (`fluttercanvas_core`) es un **formato de autoría temporal**. Un adaptador `tool/design/adapters/fluttercanvas_to_design.dart` lo convierte a `design/app.design.json`, que sigue siendo la única fuente de verdad.
4. **No se usa** el generador de código Dart de `fluttercanvas` ni su renderer en la app. El preview del Studio y la app comparten nuestro `SpecRenderer`; así lo que se ve en la herramienta es exactamente lo que se ve en el dispositivo.
5. Criterio de abort del spike: si el paquete (v0.3.0, publicador no verificado) no cubre capas, undo/redo, serialización estable o nodos whitelist en el tiempo previsto, se sustituye por un canvas propio mínimo con `GestureDetector`/`CustomPainter`, manteniendo el mismo contrato JSON. **No se forka Penpot ni Figma**.
6. Penpot/Figma quedan como importadores opcionales mediante plugin exportador a nuestro esquema, nunca como base del Studio.
7. El editor genera estructuras y datos; la lógica de cálculo sigue siendo Dart testado (ADR-0007, ADR-0009) y los assets se validan antes de publicar (ADR-0008, ADR-0010).

## Consecuencias

- Positivas: una sola tecnología en herramienta y app; preview fiel; sin mantener un fork de otro proyecto; el contrato de datos queda bajo nuestro control.
- Negativas: dependencia joven con risk de API inestable; hay que escribir y mantener el adaptador; una parte del trabajo del editor es infraestructura de canvas.

## Alternativas descartadas

- **Fork de Penpot**: editor maduro y MPL-2.0, pero stack ClojureScript, servidor propio, renderer duplicado y fork que sincronizar.
- **tldraw**: mejor SDK de canvas, pero su licencia exige clave de pago en producción.
- **Excalidraw**: MIT y open format, pero es una pizarra de dibujo, no un editor de UI con tokens e inspector.
- **Canvas propio desde el primer día**: control total, pero retrasa el entregable sin necesidad mientras exista una base Dart usable.

## Referencias

- `docs/plans/2026-11-24-design-studio-v2.md`
- `docs/adr/0002-orden-plataformas.md`
- `docs/adr/0004-arquitectura-modular-y-generador.md`
