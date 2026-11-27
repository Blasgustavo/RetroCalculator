// Inspector del RetroDesign Studio (T25, plan V4): editor real de propiedades
// del nodo, tokens de la skin seleccionada y fórmulas del perfil.
//
// Los campos se generan desde `studioEditableNodeProperties`, `colorKeys` y
// `minValues.keys`; las reglas de color/contraste y la validación de fórmulas
// se reutilizan, no se copian. Solo widgets del SDK y sin estado propio fuera
// de los controladores de texto: todo el documento vive en `StudioController`.

import 'package:flutter/material.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart'
    show colorKeys, contrastRatio, hexColorPattern, minContrastRatio, minValues;

import '../schema.dart' show DesignNode, ProfileSpec;
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';
import 'studio_controller.dart'
    show
        StudioController,
        studioEditableNodeProperties,
        studioNodePropertyError,
        studioNodePropertyText,
        studioNumNodeProperties;

/// Panel lateral derecho del editor. Sustituye al texto de solo lectura de T21.
class StudioInspectorPanel extends StatelessWidget {
  const StudioInspectorPanel({super.key, required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final DesignNode? node = controller.selectedNode;
    final String path = controller.selectedNodePath;
    final bool locked =
        path.isNotEmpty && controller.isNodeEffectivelyLocked(path);
    final ProfileSpec? profile = _profile(controller);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (node == null)
                  const Text('Selecciona un nodo')
                else ...<Widget>[
                  Text('Tipo: ${node.type}'),
                  if (node.key != null) Text('Key: ${node.key}'),
                  if (locked)
                    const Text(
                      'Nodo bloqueado',
                      style: TextStyle(color: Color(0xFFB71C1C)),
                    ),
                  for (final String property in studioEditableNodeProperties)
                    _NodePropertyField(
                      controller: controller,
                      path: path,
                      property: property,
                      enabled: !locked,
                    ),
                ],
                const Divider(height: 16),
                _SkinSection(controller: controller),
                const Divider(height: 16),
                _FormulaSection(controller: controller, profile: profile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ProfileSpec? _profile(StudioController controller) {
    final String? id = controller.selectedProfileId;
    if (id == null) return null;
    for (final ProfileSpec profile in controller.document.profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }
}

/// Etiqueta legible de una propiedad del nodo.
String _nodePropertyLabel(String property) => switch (property) {
  'key' => 'Key',
  'titleKey' => 'Title key',
  'when' => 'When',
  'value' => 'Value',
  'height' => 'Height',
  'alignment' => 'Alignment',
  _ => property,
};

/// Campo de texto de una propiedad del nodo con error en vivo. El valor se
/// mantiene mientras el campo tiene el foco, aunque el controller lo rechace
/// (por ejemplo una altura por debajo de 48 dp).
class _NodePropertyField extends StatefulWidget {
  const _NodePropertyField({
    required this.controller,
    required this.path,
    required this.property,
    required this.enabled,
  });

  final StudioController controller;
  final String path;
  final String property;
  final bool enabled;

  @override
  State<_NodePropertyField> createState() => _NodePropertyFieldState();
}

class _NodePropertyFieldState extends State<_NodePropertyField> {
  late final TextEditingController _text = TextEditingController(
    text: _externalText(),
  );
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);
  String? _error;

  /// T26: una sesión de escritura es una sola entrada del historial.
  void _onFocusChange() {
    if (_focus.hasFocus) {
      widget.controller.beginInteraction(
        'node:${widget.path}:${widget.property}',
      );
    } else {
      widget.controller.endInteraction();
    }
  }

  String _externalText() {
    final DesignNode? node = widget.controller.selectedNode;
    if (node == null) return '';
    return studioNodePropertyText(node, widget.property) ?? '';
  }

  @override
  void didUpdateWidget(covariant _NodePropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path ||
        widget.property != oldWidget.property) {
      _text.text = _externalText();
      _error = null;
      return;
    }
    final String external = _externalText();
    if (!_focus.hasFocus && external != _text.text) {
      _text.text = external;
      _error = null;
    }
  }

  @override
  void dispose() {
    if (_focus.hasFocus) widget.controller.endInteraction();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('studio.inspector.node.${widget.property}'),
      controller: _text,
      focusNode: _focus,
      enabled: widget.enabled,
      keyboardType: studioNumNodeProperties.contains(widget.property)
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: _nodePropertyLabel(widget.property),
        errorText: _error,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (String value) {
        if (studioNumNodeProperties.contains(widget.property) &&
            value.trim().isNotEmpty) {
          final String? error = studioNodePropertyError(widget.property, value);
          setState(() => _error = error);
          if (error == null) {
            widget.controller.setNodeProperty(
              widget.path,
              widget.property,
              num.tryParse(value.trim()),
            );
          }
          return;
        }
        setState(() => _error = null);
        widget.controller.setNodeProperty(
          widget.path,
          widget.property,
          value.trim().isEmpty &&
                  studioNumNodeProperties.contains(widget.property)
              ? null
              : value,
        );
      },
    );
  }
}

/// Selector de skin y campos generados desde `colorKeys` y `minValues.keys`.
class _SkinSection extends StatelessWidget {
  const _SkinSection({required this.controller});

  final StudioController controller;

  @override
  Widget build(BuildContext context) {
    final String? skinId = controller.selectedSkinId;
    final List<String> ids = controller.document.skins
        .map((skin) => skin.id)
        .toList();
    final Map<String, Object?> tokens = controller.skinTokens(skinId ?? '');
    final List<String> errors = skinId == null
        ? <String>[]
        : controller.validateSkinTokens(skinId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Skin', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          key: const Key('studio.inspector.skin'),
          value: skinId != null && ids.contains(skinId) ? skinId : null,
          isDense: true,
          items: <DropdownMenuItem<String>>[
            for (final String id in ids)
              DropdownMenuItem<String>(value: id, child: Text(id)),
          ],
          onChanged: ids.isEmpty
              ? null
              : (String? value) {
                  if (value != null) controller.selectSkin(value);
                },
        ),
        for (final String key in <String>[...colorKeys, ...minValues.keys])
          _TokenField(
            controller: controller,
            skinId: skinId,
            tokenKey: key,
            numeric: minValues.containsKey(key),
            error: _errorFor(errors, key),
            value: tokens[key],
          ),
        for (final String error in _globalErrors(errors))
          Text(error, style: const TextStyle(color: Color(0xFFB71C1C))),
        _contrastText(
          'Contraste segmento/display',
          tokens['segmentOn'],
          tokens['displayBackground'],
        ),
        _contrastText(
          'Contraste texto/botón',
          tokens['keyForeground'],
          tokens['keyBackground'],
        ),
      ],
    );
  }

  String _errorFor(List<String> errors, String key) =>
      errors.where((String error) => error.startsWith('$key ')).join('; ');

  List<String> _globalErrors(List<String> errors) => errors
      .where(
        (String error) => !<String>[
          ...colorKeys,
          ...minValues.keys,
        ].any((String key) => error.startsWith('$key ')),
      )
      .toList();

  Widget _contrastText(String label, Object? foreground, Object? background) {
    if (foreground is! String ||
        background is! String ||
        !hexColorPattern.hasMatch(foreground) ||
        !hexColorPattern.hasMatch(background)) {
      return const SizedBox.shrink();
    }
    final double ratio = contrastRatio(foreground, background);
    final String suffix = ratio < minContrastRatio
        ? ' (por debajo de 4.5:1)'
        : '';
    return Text('$label: ${ratio.toStringAsFixed(2)}:1$suffix');
  }
}

/// Campo de un token: escribe en la skin seleccionada y muestra el error
/// devuelto por `validateTokens` para esa clave concreta.
class _TokenField extends StatefulWidget {
  const _TokenField({
    required this.controller,
    required this.skinId,
    required this.tokenKey,
    required this.numeric,
    required this.error,
    required this.value,
  });

  final StudioController controller;
  final String? skinId;
  final String tokenKey;
  final bool numeric;
  final String error;
  final Object? value;

  @override
  State<_TokenField> createState() => _TokenFieldState();
}

class _TokenFieldState extends State<_TokenField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.value?.toString() ?? '',
  );
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);

  /// T26: agrupa todas las escrituras del campo en una sola entrada.
  void _onFocusChange() {
    if (_focus.hasFocus) {
      widget.controller.beginInteraction(
        'token:${widget.skinId}:${widget.tokenKey}',
      );
    } else {
      widget.controller.endInteraction();
    }
  }

  @override
  void didUpdateWidget(covariant _TokenField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.skinId != oldWidget.skinId ||
        widget.tokenKey != oldWidget.tokenKey) {
      _text.text = widget.value?.toString() ?? '';
      return;
    }
    if (!_focus.hasFocus && _text.text != (widget.value?.toString() ?? '')) {
      _text.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    if (_focus.hasFocus) widget.controller.endInteraction();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('studio.inspector.token.${widget.tokenKey}'),
      controller: _text,
      focusNode: _focus,
      enabled: widget.skinId != null,
      keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: widget.tokenKey,
        errorText: widget.error.isEmpty ? null : widget.error,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (String value) {
        if (widget.skinId != null) {
          widget.controller.setSkinToken(
            widget.skinId!,
            widget.tokenKey,
            value,
          );
        }
      },
    );
  }
}

/// Selector de perfil/fórmula y editor con validación en vivo. La fórmula se
/// guarda en el documento aunque sea inválida; T27 bloquea la compilación.
class _FormulaSection extends StatefulWidget {
  const _FormulaSection({required this.controller, required this.profile});

  final StudioController controller;
  final ProfileSpec? profile;

  @override
  State<_FormulaSection> createState() => _FormulaSectionState();
}

class _FormulaSectionState extends State<_FormulaSection> {
  String? _name;
  late final TextEditingController _text;
  late final FocusNode _focus;
  double? _testValue;
  String? _testError;

  @override
  void initState() {
    super.initState();
    final List<String> names =
        widget.profile?.formulas.keys.toList() ?? const <String>[];
    _name = names.isEmpty ? null : names.first;
    _text = TextEditingController(
      text: _name == null ? '' : widget.profile!.formulas[_name]!,
    );
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  /// T26: agrupa todas las escrituras de la fórmula en una sola entrada.
  void _onFocusChange() {
    if (_focus.hasFocus) {
      widget.controller.beginInteraction(
        'formula:${widget.profile?.id ?? ''}:${_name ?? ''}',
      );
    } else {
      widget.controller.endInteraction();
    }
  }

  @override
  void didUpdateWidget(covariant _FormulaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<String> names =
        widget.profile?.formulas.keys.toList() ?? const <String>[];
    if (_name == null || !names.contains(_name)) {
      _name = names.isEmpty ? null : names.first;
      _text.text = _name == null ? '' : widget.profile!.formulas[_name]!;
      return;
    }
    final String external = widget.profile!.formulas[_name]!;
    if (!_focus.hasFocus && external != _text.text) _text.text = external;
  }

  @override
  void dispose() {
    if (_focus.hasFocus) widget.controller.endInteraction();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> _suggestions(ProfileSpec profile) {
    final CalculatorCapability capability = profile.capabilityId == 'scientific'
        ? const ScientificCapability()
        : const BasicCapability();
    return <String>[
      ...profile.inputs,
      ...capability.functions,
      ...capability.constants,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSpec? profile = widget.profile;
    final List<String> names =
        profile?.formulas.keys.toList() ?? const <String>[];
    final String? effectiveName = _name != null && names.contains(_name)
        ? _name
        : null;
    final List<String> errors = profile == null || effectiveName == null
        ? const <String>[]
        : widget.controller.validateProfileFormula(
            profile.id,
            effectiveName,
            _text.text,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Fórmulas', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          key: const Key('studio.inspector.profile'),
          value: profile?.id,
          isDense: true,
          items: <DropdownMenuItem<String>>[
            for (final ProfileSpec item in widget.controller.document.profiles)
              DropdownMenuItem<String>(value: item.id, child: Text(item.id)),
          ],
          onChanged: widget.controller.document.profiles.isEmpty
              ? null
              : (String? value) {
                  if (value != null) widget.controller.selectProfile(value);
                },
        ),
        DropdownButton<String>(
          key: const Key('studio.inspector.formulaName'),
          value: effectiveName,
          isDense: true,
          items: <DropdownMenuItem<String>>[
            for (final String name in names)
              DropdownMenuItem<String>(value: name, child: Text(name)),
          ],
          onChanged: names.isEmpty
              ? null
              : (String? value) {
                  if (value == null) return;
                  setState(() {
                    _name = value;
                    _text.text = profile!.formulas[value]!;
                  });
                },
        ),
        TextField(
          key: const Key('studio.inspector.formula'),
          controller: _text,
          focusNode: _focus,
          enabled: profile != null && effectiveName != null,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Expresión',
            errorText: errors.isEmpty ? null : errors.first,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (String value) {
            if (profile != null && effectiveName != null) {
              widget.controller.setProfileFormula(
                profile.id,
                effectiveName,
                value,
              );
            }
            // La validación se recalcula en `build` con el texto actual.
            setState(() {
              _testValue = null;
              _testError = null;
            });
          },
        ),
        if (profile != null && effectiveName != null) ...<Widget>[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final String suggestion in _suggestions(profile))
                ActionChip(
                  key: Key('studio.inspector.formulaSuggestion.$suggestion'),
                  label: Text(suggestion),
                  onPressed: () {
                    final int offset = _text.selection.baseOffset < 0
                        ? _text.text.length
                        : _text.selection.baseOffset;
                    final String before = _text.text.substring(0, offset);
                    final String after = _text.text.substring(offset);
                    final String inserted =
                        before.isEmpty ||
                            before.endsWith(' ') ||
                            before.endsWith('(') ||
                            before.endsWith(',') ||
                            before.endsWith('+') ||
                            before.endsWith('-') ||
                            before.endsWith('*') ||
                            before.endsWith('/') ||
                            before.endsWith('^') ||
                            before.endsWith('%')
                        ? suggestion
                        : ' $suggestion';
                    _text.text = '$before$inserted$after';
                    _text.selection = TextSelection.collapsed(
                      offset: before.length + inserted.length,
                    );
                    widget.controller.setProfileFormula(
                      profile.id,
                      effectiveName,
                      _text.text,
                    );
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              ElevatedButton(
                key: const Key('studio.inspector.formulaTest'),
                onPressed: () {
                  final Map<String, num> values = <String, num>{
                    for (final String input in profile.inputs) input: 1,
                  };
                  final ({double? value, String? error}) result = widget
                      .controller
                      .testProfileFormula(
                        profile.id,
                        effectiveName,
                        _text.text,
                        values,
                      );
                  setState(() {
                    _testValue = result.value;
                    _testError = result.error;
                  });
                },
                child: const Text('Probar'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key: const Key('studio.inspector.formulaResult'),
                  _testError != null
                      ? _testError!
                      : (_testValue == null ? '' : _testValue.toString()),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
