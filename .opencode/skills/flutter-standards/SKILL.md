---
name: flutter-standards
description: >
  Define las convenciones Flutter de RetroCalculator: Clean Architecture + MVVM, estructura
  lib/core, lib/data, lib/features, lib/platform, design system retro, tests con flutter
  analyze/flutter test y la regla de que el motor de cálculo no depende de Flutter.
  Trigger: escribir o revisar código Dart, crear archivos en lib/, decidir dónde va una clase.
auto_invoke: Flutter, Dart, Clean Architecture, MVVM, design system, flutter analyze, flutter test, widget, motor de cálculo, nueva clase
version: "1.0.0"
license: Apache-2.0
metadata:
  author: RetroCalculator
  usage: { count: 0, last_used: null, success_rate: 1.0 }
  dependencies: []
  status: active
  category: flutter
---

## TL;DR

Antes de escribir Dart, cargar este skill. El motor vive en `lib/features/calculator/domain/` y es Dart puro (sin `package:flutter/*`, sin `BuildContext`, sin `eval`). Las skins solo cambian `lib/core/design_system/`. Los plugins nativos solo se importan desde `lib/platform/`. Verificar siempre con `flutter analyze` y `flutter test`.

## Purpose

Fijar una única estructura para que calculadora, skins, monetización y plataformas no se mezclen. Permite que el mismo equipo (o subagentes distintos) trabaje en paralelo sin pisarse y que la calculadora siga siendo gratuita y funcional incluso sin backend ni anuncios.

## When to Use

- Crear cualquier archivo bajo `lib/` o `test/`.
- Añadir una operación científica, un widget, un repositorio o un adaptador nativo.
- Revisar un diff antes de pedir `spec reviewer`/`quality reviewer`.
- Definir tokens de color/tipografía del tema retro.

## Critical Patterns

1. **Estructura y responsabilidades**

   ```text
   lib/
   ├── main.dart                 # entry point + errores globales
   ├── app.dart                  # MaterialApp + tema + rutas
   ├── config/                   # routes.dart, theme/
   ├── core/
   │   ├── design_system/        # colores, tipografía, spacing, radius, sombras
   │   ├── widgets/              # display, teclado, botones reutilizables
   │   ├── utils/ errors/ constants/
   ├── data/
   │   ├── models/ repositories/ services/ local/
   ├── features/
   │   ├── calculator/
   │   │   ├── domain/           # parser, evaluador, científicas  ← SIN Flutter
   │   │   ├── data/
   │   │   └── presentation/     # normal/científico, ViewModels, widgets
   │   ├── skins/
   │   │   ├── domain/           # Skin, Entitlement (contrato)
   │   │   ├── data/             # catálogo, repositorio
   │   │   └── presentation/     # tienda, preview, cuenta atrás
   │   ├── monetization/
   │   │   ├── ads/ iap/ entitlements/
   │   └── settings/
   └── platform/                 # adaptadores Android / Windows / iOS
   ```

   Tests espejo: `test/unit/calculator/`, `test/unit/monetization/`, `test/widget/`, `test/integration/`.

2. **Regla de oro del motor (Dart puro)**

   ```dart
   // lib/features/calculator/domain/evaluator.dart
   // ✅ correcto: solo dart:core, sin Flutter, sin UI
   class Evaluator {
     double evaluate(String expression) { /* parser propio, sin eval */ }
   }
   ```

   ```dart
   // ❌ incorrecto en domain/
   import 'package:flutter/material.dart';
   import 'package:shared_preferences/shared_preferences.dart';
   ```

   La UI de `presentation/` llama al `ViewModel`, el `ViewModel` llama al `domain/`; nunca al revés.

3. **Clean + MVVM en la feature calculator**

   - `domain/`: entidades y casos de uso (`EvaluateExpression`, `ToggleAngleMode`).
   - `data/`: implementaciones de repositorio (historial, preferencias).
   - `presentation/`: `CalculatorViewModel` con `ChangeNotifier` o el patrón elegido, expone `display`, `mode`, `memory`; el widget solo escucha y envía eventos (`onKeyPressed`).
   - Comando: `flutter test test/unit/calculator/` y `flutter test test/widget/`.

4. **Skins y monetización sin contaminar el cálculo**

   - Una skin es cosmética: paleta, tipografía, textura y sonido eventual; **no añade operaciones de pago**.
   - La skin se aplica desde `lib/core/design_system/`; el resultado de `Evaluator` no cambia con el tema.
   - `Entitlement` se valida en `lib/features/monetization/entitlements/` con `expiresAt`; la UI consume `isActive` y muestra la cuenta atrás.
   - Solo anuncios recompensados, voluntarios y con recompensa explícita: prohibidos banners e intersticiales.
   - El motor nunca consulta si hay entitlement: calcular siempre funciona.

5. **Plataforma**

   - `lib/platform/` expone una interfaz (`RewardedAdService`, `BillingService`) y adaptadores por plataforma; el resto del código importa la interfaz, nunca el plugin directo.
   - Orden: Android (AdMob + Play Billing) → Windows (sin AdMob/IAP móvil) → iOS (ATT, privacy manifest, IAP de App Store).
   - Builds: `flutter build apk --release`, `flutter build windows`, `flutter build ios`.

6. **Verificación obligatoria**

   ```bash
   flutter pub get
   flutter analyze          # cero issues nuevos
   flutter test             # unit + widget + integration
   flutter test --coverage  # cobertura del motor y entitlements
   dart format lib test     # formato consistente
   ```

## Commands

```bash
# Estructura y análisis
find lib -type d | sort
flutter analyze
dart format --output=none --set-exit-if-changed lib test

# Tests por capa
flutter test test/unit/calculator/
flutter test test/unit/monetization/
flutter test test/widget/
flutter test --coverage

# Builds por plataforma (en su fase)
flutter build apk --release
flutter build windows
flutter build ios --no-codesign
```

## Anti-Patterns

- Importar `package:flutter/*` en `lib/features/calculator/domain/`.
- Usar `eval`, `dart:mirrors` o un paquete externo para evaluar la expresión.
- Meter la lógica de cálculo en un `StatefulWidget` o en el `ViewModel`.
- Hacer que una skin desbloquee el modo científico o cambie el resultado.
- Llamar a AdMob, Google Play Billing o complementos nativos desde `presentation/` sin pasar por `lib/platform/`.
- Añadir banners o intersticiales, o exigir un anuncio para calcular.
- Commitear sin `flutter analyze` y `flutter test` en verde.
- Copiar convenciones de NestJS, Angular, Leaflet o del dominio FieldOps de ElectroSys.

## Related Skills

- [test-driven-development](../../../.opencode/skills/test-driven-development/SKILL.md) — tests primero para motor y entitlements.
- [verification-before-completion](../../../.opencode/skills/verification-before-completion/SKILL.md) — analyze + test antes de reportar.
- [writing-plans](../../../.opencode/skills/writing-plans/SKILL.md) — planes que respetan esta estructura.
- [adr-recorder](../../../.opencode/skills/adr-recorder/SKILL.md) — decisiones que fijan el diseño retro y las plataformas.
- [systematic-debugging](../../../.opencode/skills/systematic-debugging/SKILL.md) — aislamiento por capa cuando falla algo.
