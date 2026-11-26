// Shell del RetroDesign Studio (T21/T22, plan V4): paleta arrastrable,
// canvas con destino de drop, capas, inspector, selector de breakpoint y
// acciones de publicación.
//
// Solo widgets del SDK de Flutter: el canvas renderiza con el mismo
// `SpecRenderer` que la app y aquí no se importa `fluttercanvas`. El shell es
// autónomo: no necesita red, plugins nativos ni entitlements, y no toca ni el
// motor de cálculo ni `lib/features/`.

import 'package:flutter/material.dart';
import 'package:retro_calculator/core/widgets/spec_renderer.dart';

import '../artifacts.dart' show designNodeToJson;
import '../schema.dart';
import 'studio_controller.dart';
import 'studio_geometry.dart';

const List<String> _studioActions = <String>[
  'Guardar',
  'Validar',
  'Compilar',
  'Publicar',
];

/// Aplicación aislada del Studio: se lanza con
/// `flutter run -t tool/design/studio/main.dart`.
///
/// No puede exponerse como `lib/tool_preview_main.dart`: un archivo en `lib/`
/// no puede importar nada fuera de `lib/` y el shell necesita `DesignSeed` de
/// `tool/design/schema.dart`.
class StudioApp extends StatelessWidget {
  const StudioApp({super.key, this.document, this.controller});

  /// Documento inyectado por los tests; en la app real se lee de disco.
  final DesignSeed? document;

  /// Controlador inyectado por los tests de interacción (opcional).
  final StudioController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RetroDesign Studio',
      home: StudioShell(document: document, controller: controller),
    );
  }
}

/// Una sola pantalla con todos los paneles del editor.
class StudioShell extends StatefulWidget {
  const StudioShell({
    super.key,
    this.document,
    this.designPath = studioDefaultDesignPath,
    this.controller,
  });

  final DesignSeed? document;
  final String designPath;
  final StudioController? controller;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  late final StudioController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        StudioController(
          document: widget.document ?? loadStudioDocument(widget.designPath),
        );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RetroDesign Studio')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 160,
                child: _PalettePanel(
                  key: const Key('studio.palette'),
                  controller: _controller,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _editorArea(context, _controller)),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _LayersPanel(
                        key: const Key('studio.layers'),
                        controller: _controller,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 160,
                      child: _InspectorPanel(
                        key: const Key('studio.inspector'),
                        controller: _controller,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Centro del editor: pantalla + breakpoint, acciones y canvas.
  Widget _editorArea(BuildContext context, StudioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              if (controller.screens.isNotEmpty)
                DropdownButton<String>(
                  value: controller.screen,
                  isDense: true,
                  items: <DropdownMenuItem<String>>[
                    for (final String screen in controller.screens)
                      DropdownMenuItem<String>(
                        value: screen,
                        child: Text(screen),
                      ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) controller.selectScreen(value);
                  },
                ),
              for (final String breakpoint in controller.breakpoints)
                ChoiceChip(
                  label: Text(breakpoint),
                  selected: controller.breakpoint == breakpoint,
                  onSelected: (_) => controller.selectBreakpoint(breakpoint),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final String action in _studioActions)
                ElevatedButton(
                  onPressed: () => _showAction(context, action),
                  child: Text(action),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _CanvasPanel(
            key: const Key('studio.canvas'),
            controller: controller,
          ),
        ),
      ],
    );
  }

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action: pendiente de implementación (T27)')),
    );
  }
}

class _PalettePanel extends StatelessWidget {
  const _PalettePanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Paleta', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final String type in controller.paletteTypes)
                  Draggable<String>(
                    data: type,
                    feedback: Material(
                      color: const Color(0xFFFFF3E0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: ListTile(dense: true, title: Text(type)),
                    ),
                    child: ListTile(dense: true, title: Text(type)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CanvasPanel extends StatelessWidget {
  const _CanvasPanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      // Deny-by-default: solo los tipos de la whitelist llegan a `addNode`.
      onWillAcceptWithDetails: (DragTargetDetails<String> details) =>
          designNodeTypes.contains(details.data),
      onAcceptWithDetails: (DragTargetDetails<String> details) =>
          controller.addNode(details.data),
      builder:
          (
            BuildContext context,
            List<String?> candidateData,
            List<dynamic> rejectedData,
          ) {
            final bool hovering = candidateData.isNotEmpty;
            final Size frame = controller.frame;
            final StudioGeometry? selected = controller.selectedGeometry;
            return DecoratedBox(
              key: const Key('studio.canvas.dropZone'),
              decoration: BoxDecoration(
                color: hovering
                    ? const Color(0xFFCFD8DC)
                    : const Color(0xFFECEFF1),
                border: Border.all(
                  color: hovering
                      ? const Color(0xFF00695C)
                      : const Color(0xFF90A4AE),
                  width: hovering ? 2 : 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    key: const Key('studio.canvas.frame'),
                    width: frame.width,
                    height: frame.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFB0BEC5)),
                                bottom: BorderSide(color: Color(0xFFB0BEC5)),
                              ),
                            ),
                          ),
                        ),
                        for (int i = 0; i < controller.currentNodes.length; i++)
                          _NodeBox(
                            path: '$i',
                            node: controller.currentNodes[i],
                            controller: controller,
                          ),
                        // Las manillas son hermanas de las cajas, no hijas:
                        // así su gesto de resize no compite con el de mover.
                        if (selected != null &&
                            controller.selectedNodePath.isNotEmpty)
                          for (final StudioResizeHandle handle
                              in StudioResizeHandle.values)
                            _ResizeHandle(
                              path: controller.selectedNodePath,
                              handle: handle,
                              geometry: selected,
                              controller: controller,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}

/// Caja interactiva de un nodo: selecciona al pulsar y mueve con el puntero.
///
/// Se usa `Listener` en lugar de `GestureDetector` porque el canvas tiene un
/// `SingleChildScrollView`: su recognizer de arrastre ganaría la arena y
/// cancelaría el `onPanUpdate` de la caja. Los eventos crudos llegan a todos los
/// listeners y el delta se calcula en coordenadas globales (inmune al
/// desplazamiento del propio nodo mientras se arrastra).
class _NodeBox extends StatefulWidget {
  const _NodeBox({
    required this.path,
    required this.node,
    required this.controller,
  });

  final String path;
  final DesignNode node;
  final StudioController controller;

  @override
  State<_NodeBox> createState() => _NodeBoxState();
}

class _NodeBoxState extends State<_NodeBox> {
  Offset? _lastPosition;

  @override
  Widget build(BuildContext context) {
    final StudioGeometry geometry = widget.controller.geometryOf(widget.path)!;
    final bool selected = widget.controller.selectedNodePath == widget.path;
    return Positioned(
      left: geometry.x,
      top: geometry.y,
      width: geometry.width,
      height: geometry.height,
      child: Listener(
        key: Key('studio.node.${widget.path}'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent event) {
          _lastPosition = event.position;
          widget.controller.selectNode(widget.path);
        },
        onPointerMove: (PointerMoveEvent event) {
          final Offset? last = _lastPosition;
          if (last == null) return;
          final Offset delta = event.position - last;
          _lastPosition = event.position;
          widget.controller.moveNode(widget.path, dx: delta.dx, dy: delta.dy);
        },
        onPointerUp: (PointerUpEvent event) => _lastPosition = null,
        onPointerCancel: (PointerCancelEvent event) => _lastPosition = null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF00695C)
                  : const Color(0xFF90A4AE),
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: geometry.width,
                child: SpecRenderer(
                  nodes: <Object?>[designNodeToJson(widget.node)],
                  renderContext: const SpecRenderContext(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Manilla de resize de una de las ocho posiciones del rectángulo.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.path,
    required this.handle,
    required this.geometry,
    required this.controller,
  });

  static const double size = 12;

  final String path;
  final StudioResizeHandle handle;
  final StudioGeometry geometry;
  final StudioController controller;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  Offset? _lastPosition;

  Offset get _anchor => switch (widget.handle) {
    StudioResizeHandle.topLeft => Offset(widget.geometry.x, widget.geometry.y),
    StudioResizeHandle.top => Offset(
      widget.geometry.x + widget.geometry.width / 2,
      widget.geometry.y,
    ),
    StudioResizeHandle.topRight => Offset(
      widget.geometry.x + widget.geometry.width,
      widget.geometry.y,
    ),
    StudioResizeHandle.right => Offset(
      widget.geometry.x + widget.geometry.width,
      widget.geometry.y + widget.geometry.height / 2,
    ),
    StudioResizeHandle.bottomRight => Offset(
      widget.geometry.x + widget.geometry.width,
      widget.geometry.y + widget.geometry.height,
    ),
    StudioResizeHandle.bottom => Offset(
      widget.geometry.x + widget.geometry.width / 2,
      widget.geometry.y + widget.geometry.height,
    ),
    StudioResizeHandle.bottomLeft => Offset(
      widget.geometry.x,
      widget.geometry.y + widget.geometry.height,
    ),
    StudioResizeHandle.left => Offset(
      widget.geometry.x,
      widget.geometry.y + widget.geometry.height / 2,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _anchor.dx - _ResizeHandle.size / 2,
      top: _anchor.dy - _ResizeHandle.size / 2,
      width: _ResizeHandle.size,
      height: _ResizeHandle.size,
      child: Listener(
        key: Key('studio.handle.${widget.path}.${widget.handle.name}'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent event) =>
            _lastPosition = event.position,
        onPointerMove: (PointerMoveEvent event) {
          final Offset? last = _lastPosition;
          if (last == null) return;
          final Offset delta = event.position - last;
          _lastPosition = event.position;
          widget.controller.resizeNode(
            widget.path,
            widget.handle,
            dx: delta.dx,
            dy: delta.dy,
          );
        },
        onPointerUp: (PointerUpEvent event) => _lastPosition = null,
        onPointerCancel: (PointerCancelEvent event) => _lastPosition = null,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF00695C),
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayersPanel extends StatelessWidget {
  const _LayersPanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Capas', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _rows(controller, controller.currentNodes, '', 0),
            ),
          ),
        ),
      ],
    );
  }

  /// Filas de un nivel del árbol: la ruta de cada nodo se resuelve con su
  /// índice dentro del nivel (`'$basePath.$i'` o `'$i'` en la raíz).
  List<Widget> _rows(
    StudioController controller,
    List<DesignNode> nodes,
    String basePath,
    int depth,
  ) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < nodes.length; i++) {
      final String path = basePath.isEmpty ? '$i' : '$basePath.$i';
      rows.addAll(_nodeRows(controller, nodes[i], path, depth));
    }
    return rows;
  }

  /// Fila de un nodo con su ruta ya resuelta y las de sus descendientes:
  /// `child` único → `'$path.c'`, `children[i]` → `'$path.$i'`.
  List<Widget> _nodeRows(
    StudioController controller,
    DesignNode node,
    String path,
    int depth,
  ) {
    final List<Widget> rows = <Widget>[
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 8 + depth * 12, right: 8),
        selected: controller.selectedNodePath == path,
        onTap: () => controller.selectNode(path),
        title: Text(studioNodeLabel(node)),
      ),
    ];
    final DesignNode? child = node.child;
    if (child != null) {
      rows.addAll(_nodeRows(controller, child, '$path.c', depth + 1));
    }
    final List<DesignNode>? children = node.children;
    if (children != null) {
      rows.addAll(_rows(controller, children, path, depth + 1));
    }
    return rows;
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final DesignNode? node = controller.selectedNode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Inspector',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: node == null
                ? const Text('Selecciona un nodo')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Tipo: ${node.type}'),
                      if (node.key != null) Text('Key: ${node.key}'),
                      if (node.titleKey != null)
                        Text('Title: ${node.titleKey}'),
                      if (node.value != null) Text('Value: ${node.value}'),
                      if (node.height != null) Text('Height: ${node.height}'),
                      if (node.alignment != null)
                        Text('Alignment: ${node.alignment}'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta de un nodo en el árbol de capas: tipo + el primer detalle útil.
String studioNodeLabel(DesignNode node) {
  final String? detail = node.titleKey ?? node.key ?? node.value?.toString();
  return detail == null ? node.type : '${node.type} $detail';
}
