// Shell del RetroDesign Studio (T21/T22, plan V4): paleta arrastrable,
// canvas con destino de drop, capas, inspector, selector de breakpoint y
// acciones de publicación.
//
// Solo widgets del SDK de Flutter: el canvas renderiza con el mismo
// `SpecRenderer` que la app y aquí no se importa `fluttercanvas`. El shell es
// autónomo: no necesita red, plugins nativos ni entitlements, y no toca ni el
// motor de cálculo ni `lib/features/`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:retro_calculator/core/widgets/spec_renderer.dart';

import '../artifacts.dart' show designNodeToJson;
import '../schema.dart';
import 'studio_apply.dart' show StudioApplyResult;
import 'studio_controller.dart';
import 'studio_geometry.dart';
import 'studio_inspector.dart';

const List<String> _studioActions = <String>[
  'Guardar',
  'Recargar',
  'Validar',
  'Aplicar',
  'Ver en preview',
  'Compilar',
  'Publicar',
];

/// Keys deterministas de las acciones, estables entre slices.
const Key _saveKey = Key('studio.save');
const Key _reloadKey = Key('studio.reload');
const Key _applyKey = Key('studio.apply');
const Key _previewKey = Key('studio.preview');

Key? _actionKey(String action) => switch (action) {
  'Guardar' => _saveKey,
  'Recargar' => _reloadKey,
  'Aplicar' => _applyKey,
  'Ver en preview' => _previewKey,
  _ => null,
};

/// Siete acciones caben en la barra estrecha del editor sin desplazar el
/// canvas: se conserva la altura táctil, solo se reduce el padding lateral.
final ButtonStyle _actionButtonStyle = ButtonStyle(
  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
    const EdgeInsets.symmetric(horizontal: 2),
  ),
  minimumSize: WidgetStateProperty.all<Size>(const Size(0, 48)),
  textStyle: WidgetStateProperty.all<TextStyle>(const TextStyle(fontSize: 12)),
);

/// Intents propios: `UndoIntent`/`RedoIntent` pertenecen a los `TextField` y
/// envolverlos aquí haría que Ctrl+Z del editor competiera con el deshacer
/// nativo del texto. Al ser tipos distintos, cada action responde solo a sus
/// atajos del Studio.
class StudioUndoIntent extends Intent {
  const StudioUndoIntent();
}

class StudioRedoIntent extends Intent {
  const StudioRedoIntent();
}

/// Ctrl/Cmd+Z deshace; Ctrl/Cmd+Shift+Z y Ctrl/Cmd+Y rehacen.
final Map<ShortcutActivator, Intent> studioShortcuts =
    <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
          const StudioUndoIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
          const StudioUndoIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ,
      ): const StudioRedoIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ,
      ): const StudioRedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
          const StudioRedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY):
          const StudioRedoIntent(),
    };

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
          designPath: widget.designPath,
        );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: studioShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          StudioUndoIntent: CallbackAction<StudioUndoIntent>(
            onInvoke: (StudioUndoIntent intent) {
              _controller.undo();
              return null;
            },
          ),
          StudioRedoIntent: CallbackAction<StudioRedoIntent>(
            onInvoke: (StudioRedoIntent intent) {
              _controller.redo();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
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
                            height: 320,
                            child: StudioInspectorPanel(
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
          ),
        ),
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
              IconButton(
                key: const Key('studio.undo'),
                icon: const Icon(Icons.undo),
                tooltip: 'Deshacer (Ctrl/Cmd+Z)',
                onPressed: controller.canUndo ? controller.undo : null,
              ),
              IconButton(
                key: const Key('studio.redo'),
                icon: const Icon(Icons.redo),
                tooltip: 'Rehacer (Ctrl/Cmd+Shift+Z o Ctrl/Cmd+Y)',
                onPressed: controller.canRedo ? controller.redo : null,
              ),
              for (final String action in _studioActions)
                ElevatedButton(
                  key: _actionKey(action),
                  style: _actionButtonStyle,
                  onPressed: () => _runAction(context, action, controller),
                  child: Text(action),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 120,
          child: _ApplyStatusPanel(
            key: const Key('studio.apply.status'),
            controller: controller,
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

  /// Guardar/Recargar/Validar/Aplicar pasan por el controller y «Ver en
  /// preview» abre el renderer compartido. Compilar y Publicar siguen siendo
  /// placeholder (V7) y conservan su snackbar heredado.
  void _runAction(
    BuildContext context,
    String action,
    StudioController controller,
  ) {
    if (action == 'Guardar') {
      controller.saveDocument();
    } else if (action == 'Recargar') {
      controller.reloadDocument();
    } else if (action == 'Validar') {
      controller.validateDocument();
    } else if (action == 'Aplicar') {
      controller.applyDocument();
    } else if (action == 'Ver en preview') {
      _openPreview(context, controller);
    } else {
      _showAction(context, action);
    }
  }

  /// El preview consume `currentSpec`, no el JSON filtrado del canvas: lo que
  /// ve el compilador es lo que se muestra (ADR-0015).
  void _openPreview(BuildContext context, StudioController controller) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => _StudioPreviewPage(
          nodes: controller.currentSpec,
          width: controller.frame.width,
        ),
      ),
    );
  }

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action: pendiente de implementación en un slice posterior',
        ),
      ),
    );
  }
}

/// Vista de lectura con el mismo `SpecRenderer` de la app. El ancho del frame
/// del breakpoint viaja con el spec; los dos ejes con scroll evitan overflow
/// tanto en pantallas estrechas como en breakpoints anchos.
class _StudioPreviewPage extends StatelessWidget {
  const _StudioPreviewPage({required this.nodes, required this.width});

  final List<Object?> nodes;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa')),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: SpecRenderer(
              key: const Key('studio.preview.renderer'),
              nodes: nodes,
              renderContext: const SpecRenderContext(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel de resultados de validar/aplicar (T27): siempre visible y con scroll.
class _ApplyStatusPanel extends StatelessWidget {
  const _ApplyStatusPanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Resultados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _rows(
                controller.lastApplyResult,
                controller.persistenceStatus,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _rows(StudioApplyResult? result, String? persistenceStatus) {
    final List<Widget> rows = <Widget>[];
    if (persistenceStatus != null) {
      rows.add(
        Text(persistenceStatus, key: const Key('studio.persistence.status')),
      );
    }
    if (result == null) {
      if (rows.isEmpty) rows.add(const Text('Sin resultados'));
      return rows;
    }
    if (result.issues.isNotEmpty) {
      rows.addAll(<Widget>[
        for (int i = 0; i < result.issues.length; i++)
          Text(
            '${result.issues[i].path}: ${result.issues[i].message}',
            key: Key('studio.apply.issue.$i'),
          ),
      ]);
      return rows;
    }
    rows.add(const Text('Válido'));
    if (result.written.isEmpty) {
      rows.add(const Text('Solo validación'));
      return rows;
    }
    rows.add(const Text('Archivos escritos:'));
    for (int i = 0; i < result.written.length; i++) {
      rows.add(Text(result.written[i], key: Key('studio.apply.file.$i')));
    }
    return rows;
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
                          if (!controller.isNodeHidden('$i'))
                            _NodeBox(
                              path: '$i',
                              node: controller.currentNodes[i],
                              controller: controller,
                            ),
                        // Las manillas son hermanas de las cajas, no hijas:
                        // así su gesto de resize no compite con el de mover.
                        // Un nodo oculto o bloqueado (por sí mismo o por un
                        // ancestro) no dibuja manillas aunque siga seleccionado
                        // para el inspector: no ofrecer gestos que no hacen
                        // nada (T24).
                        if (selected != null &&
                            controller.selectedNodePath.isNotEmpty &&
                            !controller.isNodeHidden(
                              controller.selectedNodePath,
                            ) &&
                            !controller.isNodeEffectivelyLocked(
                              controller.selectedNodePath,
                            ))
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
  bool _interacting = false;

  @override
  void dispose() {
    if (_interacting) widget.controller.endInteraction();
    super.dispose();
  }

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
          _interacting = true;
          widget.controller.beginInteraction('move:${widget.path}');
        },
        onPointerMove: (PointerMoveEvent event) {
          final Offset? last = _lastPosition;
          if (last == null) return;
          final Offset delta = event.position - last;
          _lastPosition = event.position;
          widget.controller.moveNode(widget.path, dx: delta.dx, dy: delta.dy);
        },
        onPointerUp: (PointerUpEvent event) {
          _lastPosition = null;
          _interacting = false;
          widget.controller.endInteraction();
        },
        onPointerCancel: (PointerCancelEvent event) {
          _lastPosition = null;
          _interacting = false;
          widget.controller.endInteraction();
        },
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
                  nodes: <Object?>[
                    _visibleNodeJson(
                      widget.controller,
                      widget.node,
                      widget.path,
                    ),
                  ],
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
  bool _interacting = false;

  @override
  void dispose() {
    if (_interacting) widget.controller.endInteraction();
    super.dispose();
  }

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
        onPointerDown: (PointerDownEvent event) {
          _lastPosition = event.position;
          _interacting = true;
          widget.controller.beginInteraction(
            'resize:${widget.path}:${widget.handle.name}',
          );
        },
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
        onPointerUp: (PointerUpEvent event) {
          _lastPosition = null;
          _interacting = false;
          widget.controller.endInteraction();
        },
        onPointerCancel: (PointerCancelEvent event) {
          _lastPosition = null;
          _interacting = false;
          widget.controller.endInteraction();
        },
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

  /// Botón compacto de una fila: cuatro por fila caben en el panel de 200 dp.
  /// `IconButton.constraints` no basta porque el estilo del botón fija un
  /// mínimo de 48 dp: hay que fijar también `minimumSize`/`maximumSize`.
  Widget _layerButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        key: key,
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 16,
        style: ButtonStyle(
          fixedSize: WidgetStateProperty.all<Size>(const Size(24, 24)),
          minimumSize: WidgetStateProperty.all<Size>(const Size(24, 24)),
          maximumSize: WidgetStateProperty.all<Size>(const Size(24, 24)),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  /// Fila de un nodo con su ruta ya resuelta y las de sus descendientes:
  /// `child` único → `'$path.c'`, `children[i]` → `'$path.$i'`.
  List<Widget> _nodeRows(
    StudioController controller,
    DesignNode node,
    String path,
    int depth,
  ) {
    final bool hidden = controller.isNodeHidden(path);
    final bool ownLocked = controller.isNodeLocked(path);
    final bool locked = controller.isNodeEffectivelyLocked(path);
    final List<Widget> rows = <Widget>[
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 8 + depth * 12, right: 8),
        selected: controller.selectedNodePath == path,
        onTap: () => controller.selectNode(path),
        title: Text(
          studioNodeLabel(node),
          overflow: TextOverflow.ellipsis,
          style: hidden
              ? const TextStyle(
                  color: Color(0xFF78909C),
                  fontStyle: FontStyle.italic,
                )
              : null,
        ),
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _layerButton(
                key: Key('studio.layer.eye.$path'),
                icon: hidden ? Icons.visibility_off : Icons.visibility,
                tooltip: hidden ? 'Mostrar' : 'Ocultar',
                onPressed: locked
                    ? null
                    : () => controller.setNodeHidden(path, !hidden),
              ),
              _layerButton(
                key: Key('studio.layer.lock.$path'),
                icon: ownLocked ? Icons.lock : Icons.lock_open,
                tooltip: ownLocked ? 'Desbloquear' : 'Bloquear',
                onPressed: () => controller.setNodeLocked(path, !ownLocked),
              ),
              _layerButton(
                key: Key('studio.layer.up.$path'),
                icon: Icons.arrow_upward,
                tooltip: 'Subir',
                onPressed: controller.canMoveLayer(path, up: true)
                    ? () => controller.moveLayer(path, up: true)
                    : null,
              ),
              _layerButton(
                key: Key('studio.layer.down.$path'),
                icon: Icons.arrow_downward,
                tooltip: 'Bajar',
                onPressed: controller.canMoveLayer(path, up: false)
                    ? () => controller.moveLayer(path, up: false)
                    : null,
              ),
            ],
          ),
        ),
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

/// JSON del spec con los descendientes ocultos eliminados solo para el
/// render del editor. No toca `currentSpec`: el documento publicable sigue
/// completo y `designNodeToJson` conserva su contrato (ADR-0015).
Map<String, Object?> _visibleNodeJson(
  StudioController controller,
  DesignNode node,
  String path,
) {
  final Map<String, Object?> json = designNodeToJson(node);
  final DesignNode? child = node.child;
  if (child != null) {
    final String childPath = '$path.c';
    if (controller.isNodeHidden(childPath)) {
      json.remove('child');
    } else {
      json['child'] = _visibleNodeJson(controller, child, childPath);
    }
  }
  final List<DesignNode>? children = node.children;
  if (children != null) {
    final List<Object?> visible = <Object?>[];
    for (int i = 0; i < children.length; i++) {
      final String childPath = '$path.$i';
      if (!controller.isNodeHidden(childPath)) {
        visible.add(_visibleNodeJson(controller, children[i], childPath));
      }
    }
    json['children'] = visible;
  }
  return json;
}

/// Etiqueta de un nodo en el árbol de capas: tipo + el primer detalle útil.
String studioNodeLabel(DesignNode node) {
  final String? detail = node.titleKey ?? node.key ?? node.value?.toString();
  return detail == null ? node.type : '${node.type} $detail';
}
