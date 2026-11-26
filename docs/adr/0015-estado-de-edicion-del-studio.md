# ADR-0015: Estado de edición del Studio separado del spec

## Estado
Aceptado | 2026-11-25

## Contexto
El RetroDesign Studio necesita geometría (T23), visibilidad, bloqueo y orden de capas (T24). `DesignNode` es inmutable y su serialización (`designNodeToJson`) es la que consumen `validate.dart`, `compile.dart` y `SpecRenderer`. Añadir campos de editor al esquema obligaría a tocar el compilador, el validador y los artefactos, y mezclaría intenciones de edición con el contrato de la app.

## Decisión
La geometría, la visibilidad y el bloqueo viven en `StudioController`, indexados por la ruta del nodo del spec (`'0'`, `'0.c'`, `'0.2'`). No se serializan dentro del `DesignSeed`: `currentSpec` sigue siendo exactamente `currentNodes.map(designNodeToJson)`. El reordenamiento de capas sí muta el orden de los nodos del documento porque ese orden es parte del spec.

## Consecuencias
- Positivas: los artefactos y el renderer no cambian; la app sigue consumiendo solo datos del spec; el Studio puede experimentar con ayudas de edición sin riesgo.
- Positivas: T26 puede snapshotear documento más estado de edición en un solo objeto; T27 valida solo el spec; T28 persiste el estado de edición por separado.
- Negativas: al reordenar nodos hay que remapear las claves de geometría/visibilidad/bloqueo para que sigan apuntando al mismo nodo.
- Negativas: ocultar un nodo no lo elimina del spec; es una ayuda visual del editor, no una condición de publicación.

## Alternativas descartadas
- Añadir `visible`/`locked`/`x`/`y` a `DesignNode`: rompería la separación entre diseño publicable y herramienta, y obligaría a cambiar validador y compilador.
- Ocultar borrando el nodo del documento: perdería información y haría que deshacer y reordenar fueran destructivos.
- Guardar el estado de edición dentro de `key` u otras propiedades existentes: colisiona con las claves estables que usan los tests widget heredados.

## Referencias
- `docs/plans/2026-11-24-design-studio-v2.md` (V4, T23–T28)
- `docs/adr/0014-entrypoint-del-studio.md`
- `tool/design/studio/studio_controller.dart`
