# Spike: `fluttercanvas` como base del RetroDesign Studio

## Estado y timebox

Spike V0 (T1–T4) del plan `docs/plans/2026-11-24-design-studio-v2.md`, con
**timebox de 1 día**. Decisión gobernada por ADR-0011: si el paquete no cubre
capas, undo/redo, serialización estable o nodos whitelist, se sustituye por un
canvas propio (`GestureDetector` + `CustomPainter`) con el mismo contrato JSON.
No se forka Penpot ni Figma.

## Criterios del spike (T1)

| Criterio | Qué se verificó |
|---|---|
| Arrastrar desde paleta | Arrastrar un tipo del catálogo al canvas crea un nodo válido. |
| Mover/redimensionar | Gestos de move/resize sobre la selección, agrupados en undo. |
| Capas | Árbol de nodos por pantalla, selección y reordenación de hermanos. |
| Undo/redo | Pila de snapshots con redo y límite conocido. |
| Serialización JSON estable | Exportar, recargar y reexportar produce el mismo JSON. |
| Nodos whitelist | El adaptador solo emite los 12 tipos permitidos por el esquema v2 y rechaza el resto. |

La comparación visual con `SpecRenderer` **no** está incluida: `SpecRenderer`
se implementa en V3 (T16–T20). En V0 se valida la estructura del JSON contra un
fixture; la equivalencia visual se traslada explícitamente a V3.

## Entorno y versiones observadas (T2)

Comando: `flutter pub get` dentro de
`.worktrees/feature-design-studio-v0`. Versiones fijadas en `pubspec.lock`:

| Paquete | Versión | Rol |
|---|---|---|
| `fluttercanvas` | **0.3.0** | dev dependency directa; publicado el 2026-11-03; publicador **no verificado**. |
| `fluttercanvas_core` | **0.3.1** | dev dependency directa; modelo y JSON puro Dart; resuelto por la restricción `^0.3.0`. |
| `fluttercanvas_renderer` | **0.3.1** | transitiva; **no se usa** en la app ni en el preview. |
| Flutter / Dart | 3.44.0 / 3.12.0 (stable) | entorno del spike. |

`pub get` mostró avisos de `shared_preferences` sobre los default plugins de
Linux/Windows; no impidieron la resolución ni afectan a este spike. Tras cada
`flutter pub get` se ejecutó `git restore -- windows/flutter/` (fase Android-first,
ADR-0002).

## API real observada (T2)

Leída del código publicado y ejecutada en `tool/spike/spike_test.dart`:

- `BuilderController({project: ...})` es `ChangeNotifier`; expone `project`,
  `document`, `selectedId`, `selectedNode`, `canUndo`, `canRedo`, `revision`.
- Paleta → canvas: `WidgetPalette` usa `Draggable`/`LongPressDraggable` con
  `DragPayload`; `NodeFrame` es `DragTarget` y llama a
  `controller.canDrop(payload, id)` / `controller.drop(payload, id)`.
  Desde código: `NewWidgetPayload(WidgetTypes.box)` y
  `MoveNodePayload(nodeId)`. `CanvasTool.box` + `drawBox(parentId, Rect)` dibuja
  cajas por arrastre.
- Move/resize: `NodeFrame` usa `GestureDetector.onPanStart/Update/End`, calcula
  `x`/`y` o `width`/`height` y llama a `updateProps(id, values, mergeKey: ...)`
  + `endGesture()`. El mismo `mergeKey` agrupa el gesto en un solo paso de undo.
  El mínimo del resize del paquete es 16 px; nuestro mínimo táctil de 48 dp se
  valida en el esquema v2, no aquí.
- Capas: `LayersPanel` recorre `document.root` en profundidad; el controlador
  ofrece `select`, `renameNode`, `deleteNode`, `duplicateNode`, `wrapIn` y
  `moveSibling(id, delta)`. Ocultar/bloquear capas no existe en 0.3.0 y queda
  para V4 (T24).
- Undo/redo: `undo()`, `redo()`, `canUndo`, `canRedo`; límite interno de 100
  snapshots (`_historyLimit`).
- JSON: `exportJson()` → `CanvasProject.toJsonString(pretty: true)`;
  `loadJson(String)` / `CanvasProject.fromJsonString(String)`.
  `CanvasProject.schemaVersion == 2` y `CanvasDocument.schemaVersion == 1`
  son **formatos del paquete**, no nuestro esquema v2: no se reutilizan.
- El barrel `package:fluttercanvas/fluttercanvas.dart` exporta el modelo de
  `fluttercanvas_core`, el renderer, el builder y el controlador. Se usan solo
  el controlador y el modelo. **No** se usan `exportCode()`,
  `exportScreenCode()` ni el renderer.

## Resultado de cada criterio

| Criterio | Resultado | Evidencia |
|---|---|---|
| Arrastrar desde paleta | ✅ | `WidgetPalette` + `DragPayload` + `drop` insertan el nodo; test headless. |
| Mover/redimensionar | ✅ | `NodeFrame` con `GestureDetector` y `updateProps(..., mergeKey:)`; test de move/resize + undo agrupado. |
| Capas | ✅* | `LayersPanel` + `moveSibling` probados. *Sin hide/lock en el paquete; se implementa en V4. |
| Undo/redo | ✅ | `undo()`/`redo()` restauran el documento; test de ida y vuelta. |
| Serialización JSON estable | ✅ | `exportJson()` → `fromJsonString()` → `exportJson()` idénticos; test. |
| Nodos whitelist | ✅* | El adaptador emite solo los 12 tipos v2 y rechaza `customCode`, `textField`, `grid`, tipos desconocidos y `designType` fuera de whitelist. *El catálogo crudo del paquete no es nuestra whitelist. |

Ejecución del spike: `flutter test tool/spike/spike_test.dart` → **8/8 en verde**,
incluido un `testWidgets` que construye `FlutterCanvasBuilder` en modo headless
(1280×800) y comprueba paleta y panel de capas. `tool/spike/main.dart` es el
ejemplo ejecutable para Windows cuando se abra la fase de herramienta; en este
slice se ejecutó su equivalente headless para no depender de una sesión gráfica.

### Adaptador (T3)

`tool/design/adapters/fluttercanvas_to_design.dart` convierte `WidgetNode` a
mapas compatibles con `screens.<screen>.<breakpoint>` del esquema v2. Usa
propiedades puente (`designType`, `designKey`, `when`, `titleKey`, `alignment`,
`padding`, `height`) para los nodos de dominio que no existen en el catálogo del
paquete; mapeo implícito solo para `column`, `row`, `box`/`container`, `spacer`
e `image`. Los nodos con hijos se validan (`padding`/`sizedBox` exigen un hijo;
las hojas no admiten hijos). Salida comparada con
`tool/design/adapters/fixtures/screen_spec_v2_mobile.json`, extraído de la
semilla v2 del plan. `design/app.design.json` no se crea aquí: pertenece a V1
(T5) y sigue siendo la única fuente de verdad. No se usa el exportador Dart.

## Gate y decisión final (T4)

**ADOPCIÓN CONDICIONADA de `fluttercanvas` 0.3.0** como base del editor,
sujeta a estos límites:

1. `fluttercanvas_core` es formato de autoría **temporal**; todo lo que sale del
   Studio pasa por el adaptador a `design/app.design.json` (esquema v2).
2. Se prohíben en la paleta del Studio `customCode`, `textField` y cualquier
   tipo no mapeado; el adaptador los rechaza con error accionable. El
   generador de código Dart y el renderer del paquete no se usan nunca.
3. Ocultar/bloquear capas, inspector, `keyMinHeight >= 48` y la validación
   `validate.dart` se implementan en V1/V4.
4. La paridad visual frente a `SpecRenderer` es obligatoria en V3; si falla,
   se revisará esta decisión sin forkar herramientas externas.

No se aplicó el fallback a canvas propio porque ningún criterio de abort falló
dentro del timebox. Si V3 detecta divergencia de renderer, el fallback previsto
es `GestureDetector` + `CustomPainter` conservando el mismo contrato JSON.

## Comandos ejecutados

```text
flutter pub get                              → resolución correcta; 13 dependencias añadidas
git restore -- windows/flutter/              → artefactos Windows sin diff
flutter analyze                              → No issues found! (0 issues)
flutter test                                 → 44/44 All tests passed!
flutter test tool/spike/spike_test.dart      → 8/8 All tests passed!
dart format --output=none --set-exit-if-changed lib test tool
                                             → 74 archivos, 0 cambios
git diff --check                             → sin salida
```

Todos los comandos se ejecutaron dentro del worktree
`.worktrees/feature-design-studio-v0`; no se hicieron push, PR ni merge.
