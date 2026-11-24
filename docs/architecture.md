# Arquitectura

RetroCalculator sigue **Clean Architecture + MVVM**. El objetivo es mantener el motor de cálculo independiente de Flutter, que las skins sean puramente cosméticas y que la monetización se valide en un único lugar.

## Estructura de `lib/`

```
lib/
├── main.dart                      # punto de entrada y manejo global de errores
├── app.dart                       # MaterialApp, tema y rutas
├── config/
│   ├── routes.dart
│   └── theme/                     # tema retro (estilo por definir)
├── core/
│   ├── design_system/             # tokens: colores, tipografía, spacing, radius, sombras
│   ├── widgets/                   # botones, display y teclado reutilizables
│   ├── utils/
│   ├── errors/
│   └── constants/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   └── local/                     # persistencia de preferencias e historial
├── features/
│   ├── calculator/
│   │   ├── domain/                # parser, evaluador y operaciones científicas
│   │   ├── data/
│   │   └── presentation/          # modos normal/científico y widgets
│   ├── skins/
│   │   ├── domain/                # entidades Skin y Entitlement
│   │   ├── data/                  # catálogo y repositorio
│   │   └── presentation/          # tienda, vista previa y cuenta atrás
│   ├── monetization/
│   │   ├── ads/                   # anuncios recompensados
│   │   ├── iap/                   # compras reales
│   │   └── entitlements/          # duración, expiración y renovación
│   └── settings/
└── platform/                      # adaptadores Android / Windows / iOS
```

Cada feature se organiza en capas: `domain` (entidades y reglas de negocio), `data` (fuentes de datos y repositorios) y `presentation` (ViewModels y widgets). Las dependencias apuntan hacia el dominio: la capa externa depende de la interna, nunca al revés.

## Reglas de dependencias

1. **Motor sin Flutter:** la lógica de cálculo vive en `features/calculator/domain/` y no depende de Flutter ni de la UI. Debe poder probarse con tests unitarios puros, sin widgets.
2. **Skins cosméticas:** las skins no alteran el motor ni añaden funciones de pago; solo consumen `core/design_system`.
3. **Entitlements centralizados:** la validación de duración, expiración y renovación ocurre en `features/monetization/entitlements/`. La UI únicamente consume el estado resultante.
4. **Adaptadores nativos confinados:** los plugins y canales nativos solo se importan desde `lib/platform/`. El resto del código depende de abstracciones, nunca de implementaciones concretas de plataforma.
5. **Solo anuncios recompensados:** no se introducen banners ni intersticiales (ver ADR 0001).

## Verificación

Antes de dar por completado cualquier cambio:

```bash
flutter analyze
flutter test
```

Ambos comandos deben estar en verde. El motor de cálculo se cubre con tests unitarios; la calculadora y la tienda de skins, con tests de widget.
