# RetroCalculator

Calculadora gratuita con modos **normal** y **científico**, construida en Flutter para **Android**, **Windows** y **iOS**.

El motor de cálculo es siempre gratuito. La monetización proviene únicamente de **skins cosméticos** que se desbloquean **por tiempo limitado**, ya sea viendo un **anuncio recompensado** o mediante **pago real**.

> Estado actual: infraestructura del proyecto y sistema de trabajo configurados. La calculadora se implementará en el primer plan de desarrollo.

---

## Estructura

```
RetroCalculator/
├── AGENTS.md                  # Orquestador: reglas + tabla de skills auto-invocables
├── .opencode/
│   ├── opencode.json          # Agente primary + subagentes
│   ├── agents/                # Prompts de los agentes
│   ├── skills/                # Skills auto-invocables
│   └── hooks/pre-commit       # flutter analyze + flutter test
├── .github/workflows/         # android.yml → windows.yml → ios.yml
├── docs/
│   ├── README.md              # Índice de documentación
│   ├── architecture.md        # Clean Architecture + MVVM
│   ├── adr/                   # Decisiones arquitectónicas
│   └── plans/                 # Planes de implementación
├── lib/
│   ├── main.dart              # Entry point + manejo global de errores
│   ├── app.dart               # MaterialApp + tema + rutas
│   ├── config/                # Rutas
│   ├── core/                  # Design system, widgets, utils, errores, constantes
│   ├── data/                  # Modelos, repositorios, servicios, persistencia local
│   ├── features/              # calculator, skins, monetization, settings
│   └── platform/              # Adaptadores nativos por plataforma
├── test/{unit,widget,integration}/
├── android/  ios/  windows/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Inicio rápido

```bash
flutter pub get
flutter analyze          # debe dar 0 issues
flutter test             # debe pasar
flutter run              # requiere dispositivo/emulador
```

Instalar el hook de pre-commit:

```bash
git config core.hooksPath .opencode/hooks
```

---

## Flujo de trabajo

Ver el flujo acordado en `C:/Users/qty94/.opencode/plan/flujo-trabajo-retrocalculator.md` y [`AGENTS.md`](./AGENTS.md).

Resumen:

1. `writing-plans` → plan en `docs/plans/YYYY-MM-DD-<feature>.md`.
2. `to-issues` → vertical slices.
3. `using-git-worktrees` → `.worktrees/feature-<slug>`.
4. `subagent-driven-development` → implementer + review de spec + review de calidad.
5. `verification-before-completion` → `flutter analyze` + `flutter test`.
6. Commit convencional → PR a `main` → CI → merge → tag `v*`.

Convención de commits: `type(scope): summary` en inglés, cuerpo en español.

---

## Documentación

- [Índice de documentación](./docs/README.md)
- [Arquitectura](./docs/architecture.md)
- [ADR-0001: skins temporales y anuncios](./docs/adr/0001-skins-temporales-y-anuncios.md)
- [ADR-0002: orden de plataformas](./docs/adr/0002-orden-plataformas.md)
- [ADR-0003: tienda de skins y calculadoras](./docs/adr/0003-tienda-skins-y-calculadoras.md)
- [Planes](./docs/plans/)
