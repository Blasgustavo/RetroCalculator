# ADR-0007: Perfiles de calculadora extensibles con registro de capacidades

## Estado
Aceptado; parcialmente superado por ADR-0009 | 2026-11-24

## Contexto

El editor de diseño debe permitir crear calculadoras nuevas **con lógica propia**, no solo cambiar teclas de las dos existentes. Hoy `CalculatorProfileId` es un enum cerrado (`normal`, `scientific`), `isScientific` se deriva de ese id y cada `CalculatorCapability` implementa su lógica directamente en Dart. El motor es puro y no depende de Flutter; el contenido del catálogo es dato y nunca código (ADR-0004). La tienda y los precios de calculadoras ya están definidos (ADR-0003, ADR-0006).

## Decisión

1. `CalculatorProfileId` deja de ser un enum cerrado: el identificador pasa a ser `String` y se valida contra un `CapabilityRegistry` en `lib/features/calculator/domain/capabilities/`.
2. Toda lógica nueva se implementa como una clase `CalculatorCapability` en Dart, con tests unitarios, y se registra con un id estable. El editor solo puede **referenciar** ids registrados: el archivo de diseño nunca contiene operaciones, fórmulas ni código ejecutable.
3. `isScientific` pasa a ser un flag declarativo del perfil, en vez de un derivado del id.
4. El compiler genera `profiles.g.dart` desde el bloque `profiles[]` de `design/app.design.json` y valida en build-time que el `capabilityId` existe en el registro y que `labelKey` está en el ARB.
5. El editor puede generar el esqueleto de un capability nuevo (archivo + test rojo), pero la implementación de la operación la escribe y revisa una persona. El compiler no ejecuta ni interpreta lógica que venga del diseño.
6. La monetización no cambia: se rige por ADR-0003 y ADR-0006. El editor crea perfiles, no precios ni entitlements. La calculadora sigue siendo gratuita.

## Consecuencias

- Positivas: se pueden añadir calculadoras sin reescribir el parser ni el evaluador; el motor sigue siendo puro y testeable; una entry del catálogo no puede introducir cálculo arbitrario; los perfiles quedan versionados y revisables en el PR.
- Negativas: añadir una operación nueva exige un cambio en `domain/` con tests y un humano; el registro debe mantenerse sincronizado con el diseño y el compiler falla si no lo está; el ViewModel deja de comparar enums y pasa a comparar strings.

## Alternativas descartadas

- **Ejecutar fórmulas definidas en el JSON**: viola la regla de que el contenido descargado es dato, nunca código, y permitiría que un manifiesto remoto altere el cálculo.
- **Mantener el enum y añadir un caso por calculadora**: cada calculadora exigiría tocar el enum, el ViewModel y los tests; no escala al catálogo.
- **Generar el capability desde el editor**: produciría lógica no revisada y sin tests de dominio; el esqueleto se genera, la implementación no.

## Referencias

- `docs/plans/2026-11-24-design-studio-compiler.md`
- `docs/adr/0003-tienda-skins-y-calculadoras.md`
- `docs/adr/0004-arquitectura-modular-y-generador.md`
