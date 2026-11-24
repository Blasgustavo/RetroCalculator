# ADR-0003: Tienda de skins y calculadoras

## Estado

Aceptado | 2026-11-24

## Contexto

ADR-0001 fijó las skins cosméticas temporales como única vía de monetización. Al pulir la idea se detectó que ese alcance era demasiado estrecho: la personalización y la variedad de calculadoras son parte del producto, no un accesorio. El usuario confirmó que la propuesta es una **tienda** que agrupa varias categorías, manteniendo la calculadora normal y la científica como base gratuita.

También surgió la necesidad de producir skins con menos coste manual. El usuario lo concibe como una herramienta adicional que simplifica el trabajo, no como una funcionalidad de la app ni como un requisito del MVP.

## Decisión

- La tienda contiene **tres categorías**:
  1. **Skins cosméticas**: paleta, tipografía, radios, sombras, textura de botones y display.
  2. **Variantes cosméticas de dispositivos retro**: otra carcasa o pantalla con la **misma lógica** normal/científica.
  3. **Calculadoras funcionales**: programador, financiero, estadístico y gráfico, con dominio propio nuevo.
- La **calculadora normal y la científica son la base**: gratuitas, siempre disponibles, sin anuncios obligatorios y sin bloqueo por expiración.
- **Toda la tienda comparte un modelo de desbloqueo temporal común**: anuncio recompensado o pago real (IAP), ambos voluntarios, con expiración y renovación equivalentes. No se aplica nunca a la calculadora base.
- La publicidad sigue siendo **exclusivamente recompensada**: sin banners ni intersticiales (ADR-0001).
- Se adopta un **generador interno de skins**: herramienta de authoring usada **solo por el equipo**, que produce **Dart en build-time** para `core/design_system/`. Es una herramienta adicional que simplifica crear skins; **no bloquea el MVP** y no es un editor para el usuario final.

## Consecuencias

- Positivas: el catálogo puede crecer sin repetir trabajo manual; las skins generadas cumplen el esquema de tokens por construcción; la base gratuita queda intacta.
- Positivas: las variantes cosméticas y las calculadoras funcionales se pueden separar en módulos distintos, evitando que un tema toque el motor.
- Negativas: los entitlements dejan de ser solo "de skin" y pasan a ser **por artículo de tienda**, con categoría y duración.
- Negativas: los tipos funcionales nuevos amplían el motor; requieren dominio propio y tests, y no deben reutilizar el parser base sin coordinación.
- Riesgo mitigado: el generador solo emite tokens visuales. Nunca genera código de `features/calculator/domain/`.
- Pendiente: duraciones, precios, renovación, estilo retro concreto y persistencia del historial siguen abiertos en el documento de idea.

## Alternativas descartadas

- **Vender skins sueltas sin tienda**: no agrupa variantes ni calculadoras y limita el catálogo.
- **Cobrar por la calculadora base o por el modo científico**: rompe la regla de oro de ADR-0001.
- **Editor de skins en runtime para el usuario**: añade parser, validación y superficie de carga de definiciones externas antes del MVP.
- **Skins que modifiquen operaciones o botones**: viola el límite entre cosmética y cálculo.
- **Suscripción a la calculadora completa**: fricción y dependencia de backend prematura.

## Referencias

- [ADR-0001: skins temporales y anuncios](0001-skins-temporales-y-anuncios.md) — ampliado por esta decisión.
- [ADR-0002: orden de plataformas](0002-orden-plataformas.md) — Android → Windows → iOS.
- Documento de idea: `C:/Users/qty94/.opencode/plan/retrocalculator-idea.md` (v0.5).
