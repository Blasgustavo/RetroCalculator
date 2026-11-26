# ADR-0016: Presupuesto y normalización canónicos de fórmulas

## Estado
Aceptado; complementa ADR-0009 | 2026-11-26

## Contexto

ADR-0009 exige validar la misma fórmula en build-time y al aplicar un catálogo, pero no fija dos detalles que ya han provocado divergencias:

- `tool/design/schema.dart` define 64 pasos y 32 niveles, mientras `lib/features/calculator/domain/engine/engine_limits.dart` define 200 nodos y 64 niveles. Una fórmula podía pasar la compilación y fallar al ejecutarse.
- El motor rechaza con `duplicateVariable` las claves que colisionan al normalizar a minúsculas, pero los validadores usaban `inputs.toSet()` sensible a caso y no detectaban la colisión.
- `VariableNode extends ConstantNode` para no romper switches en `tool/`; si los validadores inyectan variables y siguen usando `case ConstantNode():`, tratarán las variables como constantes.

## Decisión

1. `EngineLimits.maxAstNodes = 200` y `EngineLimits.maxAstDepth = 64` son la cota canónica para declarar válida una fórmula, tanto en build-time como en runtime. `schema.dart` deja de definir sus propios `maxFormulaSteps`/`maxFormulaDepth`.
2. Los nombres de `inputs` se normalizan a minúsculas. Dos entradas que colisionan después de normalizar se rechazan antes de parsear con el código `duplicateVariable` y una ruta `profiles[i].inputs`; nunca gana la última por orden de iteración.
3. Los validadores que inyecten variables deben añadir `case VariableNode():` antes de `case ConstantNode():`. `ConstantNode()` queda reservado para dependencias entre fórmulas y constantes permitidas por la `CalculatorCapability` del perfil.
4. `pi` y `e` siguen sujetos a `CalculatorCapability.constants`. ADR-0009 §2 se interpreta en ese sentido: las constantes declaradas por el motor solo son válidas en los perfiles cuya capability las expone, para que build-time y runtime acepten exactamente lo mismo.

## Consecuencias

- Positivas: la compilación y la ejecución comparten límites y criterio de nombres; no hay fórmulas que pasen el gate y fallen después; la deuda de `VariableNode extends ConstantNode` deja de ser un footgun en los validadores.
- Negativas: `schema.dart` ya no es dueño de su presupuesto y los validadores dependen de `domain/engine/engine_limits.dart`; los perfiles `basic` siguen sin `pi`/`e`, igual que en la calculadora normal.

## Alternativas descartadas

- Mantener 64/32 en build-time: más estricto que el motor y origen de falsos rechazos o falsos aceptados.
- Normalizar en silencio las colisiones de `inputs`: depende del orden y contradice `duplicateVariable`.
- Tratar todas las constantes como globals: permitiría `pi` en un perfil `basic` que luego lo rechaza en runtime.
- Extraer un paquete común entre `tool/` y `lib/`: ADR-0009 ya acepta duplicar la validación; un paquete nuevo ampliaría el alcance sin beneficio para T33.

## Referencias

- `docs/adr/0009-formulas-declarativas-con-variables.md`
- `docs/plans/2026-11-24-design-studio-v2.md`
- `lib/features/calculator/domain/engine/engine_limits.dart`
- `lib/features/calculator/domain/engine/variable_lookup.dart`
