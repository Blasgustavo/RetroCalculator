# ADR-0009: Fórmulas declarativas con variables en el catálogo

## Estado
Aceptado; supera parcialmente ADR-0007 | 2026-11-24

## Contexto

El usuario pidió que las fórmulas de cálculo también se envíen desde la herramienta de diseño. ADR-0007 prohibía que el editor creara lógica: solo podía referenciar capacidades escritas en Dart. Esa restricción protegía la regla de ADR-0004 («el contenido descargado es dato, nunca código»), pero impedía configurar cálculos como IGV, propinas o conversores sin recompilar. El motor actual (`lexer` → `parser` → `evaluator`) ya implementa una gramática cerrada y es puro, sin Flutter.

## Decisión

1. El bloque `profiles[]` del diseño puede incluir `inputs` (nombres de variables) y `formulas` (mapa `resultado → expresión`).
2. Las fórmulas son **expresiones declarativas**, no Dart ni `eval`: números, operadores `+ - * / %`, paréntesis, variables declaradas en `inputs`, constantes `pi`/`e` y funciones ya permitidas por la `CalculatorCapability` del perfil.
3. El motor añade `VariableNode` y una firma `evaluate(expresion, variables)` sobre el parser existente. No se interpreta código arbitrario.
4. El compiler valida cada fórmula en build-time con el mismo parser: sintaxis, variables declaradas, funciones permitidas, profundidad máxima del AST y ausencia de bucles. Una fórmula inválida falla la compilación con un mensaje claro.
5. La app vuelve a validar las fórmulas al aplicar un catálogo descargado. Si alguna falla, se conserva el último perfil válido y la calculadora normal sigue funcionando.
6. Las operaciones que necesiten código nuevo (nueva función nativa, precisión especial) siguen implementándose como `CalculatorCapability` en Dart con tests, según ADR-0007. Las fórmulas cubren la **composición declarativa** sobre ese motor.
7. Límites explícitos: sin definición de funciones por el usuario, sin acceso a archivos/red/historial, sin recursión y con presupuesto de pasos acotado.

## Consecuencias

- Positivas: el catálogo puede añadir calculadoras con fórmulas revisables y testeables; la sintaxis es la misma del motor; no se ejecuta código remoto.
- Negativas: el parser y el evaluador crecen un poco; hay que duplicar validación en build-time y runtime; las fórmulas están limitadas a lo que el motor ya sabe evaluar.

## Alternativas descartadas

- **`eval`/Dart desde el JSON**: convierte un catálogo descargado en código ejecutable y rompe ADR-0004.
- **Solo capacidades en Dart (ADR-0007 sin cambios)**: exigía recompilar para cada calculadora nueva, justo lo que el usuario quiere evitar.
- **Fórmulas en un lenguaje propio interpretado desde cero**: duplica el parser existente y añade otro lenguaje que mantener.

## Referencias

- `docs/plans/2026-11-24-design-studio-v2.md`
- `docs/adr/0004-arquitectura-modular-y-generador.md`
- `docs/adr/0007-perfiles-calculadora-registro-capacidades.md`
