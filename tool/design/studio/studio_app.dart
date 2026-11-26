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

import '../schema.dart';
import 'studio_controller.dart';

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
  const StudioApp({super.key, this.document});

  /// Documento inyectado por los tests; en la app real se lee de disco.
  final DesignSeed? document;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RetroDesign Studio',
      home: StudioShell(document: document),
    );
  }
}

/// Una sola pantalla con todos los paneles del editor.
class StudioShell extends StatefulWidget {
  const StudioShell({
    super.key,
    this.document,
    this.designPath = studioDefaultDesignPath,
  });

  final DesignSeed? document;
  final String designPath;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  late final StudioController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudioController(
      document: widget.document ?? loadStudioDocument(widget.designPath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
                child: SpecRenderer(
                  nodes: controller.currentSpec,
                  renderContext: const SpecRenderContext(),
                ),
              ),
            );
          },
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
