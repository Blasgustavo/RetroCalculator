// GENERADO: dart run tool/design/compile.dart. No editar a mano.
/// Pantallas y breakpoints de design/app.design.json. Datos puros.
const Map<String, Map<String, List<Object?>>> screenSpecs =
    <String, Map<String, List<Object?>>>{
      "normal": <String, List<Object?>>{
        "mobile": <Object?>[
          {
            "type": "padding",
            "value": 12,
            "child": {"type": "display", "key": "calc.display"},
          },
          {"type": "errorText", "when": "hasError"},
          {
            "type": "sizedBox",
            "height": 380,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
          {"type": "skinSelector"},
        ],
        "tablet": <Object?>[
          {
            "type": "padding",
            "value": 16,
            "child": {"type": "display", "key": "calc.display"},
          },
          {"type": "errorText", "when": "hasError"},
          {
            "type": "sizedBox",
            "height": 420,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
          {"type": "skinSelector"},
        ],
        "desktop": <Object?>[
          {
            "type": "padding",
            "value": 20,
            "child": {"type": "display", "key": "calc.display"},
          },
          {"type": "errorText", "when": "hasError"},
          {
            "type": "sizedBox",
            "height": 460,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
          {"type": "skinSelector"},
        ],
      },
      "scientific": <String, List<Object?>>{
        "mobile": <Object?>[
          {
            "type": "padding",
            "value": 12,
            "child": {"type": "display", "key": "calc.display"},
          },
          {
            "type": "row",
            "when": "isScientific",
            "alignment": "center",
            "children": <Object?>[
              {"type": "angleChip", "key": "calc.toggle.angle"},
            ],
          },
          {
            "type": "sizedBox",
            "height": 380,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
        ],
        "tablet": <Object?>[
          {
            "type": "padding",
            "value": 16,
            "child": {"type": "display", "key": "calc.display"},
          },
          {
            "type": "row",
            "when": "isScientific",
            "alignment": "center",
            "children": <Object?>[
              {"type": "angleChip", "key": "calc.toggle.angle"},
            ],
          },
          {
            "type": "sizedBox",
            "height": 420,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
        ],
        "desktop": <Object?>[
          {
            "type": "padding",
            "value": 20,
            "child": {"type": "display", "key": "calc.display"},
          },
          {
            "type": "row",
            "when": "isScientific",
            "alignment": "center",
            "children": <Object?>[
              {"type": "angleChip", "key": "calc.toggle.angle"},
            ],
          },
          {
            "type": "sizedBox",
            "height": 460,
            "child": {"type": "keyboard", "key": "calc.keyboard"},
          },
          {"type": "history", "titleKey": "historyTitle"},
        ],
      },
      "selector": <String, List<Object?>>{
        "mobile": <Object?>[
          {"type": "skinSelector"},
        ],
        "tablet": <Object?>[
          {"type": "skinSelector"},
        ],
        "desktop": <Object?>[
          {"type": "skinSelector"},
        ],
      },
    };
