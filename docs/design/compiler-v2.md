# Compiler v2 del RetroDesign Studio

`dart run tool/design/compile.dart` compila `design/app.design.json` (semilla V1,
única fuente de verdad) en artefactos Dart y en un manifiesto v2. La semilla
**no se modifica**.

## Gate de validación

Antes de escribir cualquier archivo se llama a `validateJson` de
`tool/design/validate.dart`, que reutiliza `token_validation.dart` y el parser
del motor. Si hay issues, se imprimen numerados en `stderr`, se fija
`exitCode = 1` y no se escribe nada. `tool/design/compile.dart [archivo]`
permite compilar otra semilla con el mismo gate.

## Artefactos

| Salida | Contenido |
|---|---|
| `lib/core/design_system/generated/design_tokens.dart` | Versión, canales, tokens de todas las skins y constantes de la skin default |
| `lib/features/skins/data/generated/screens.g.dart` | 3 pantallas × 3 breakpoints, nodos whitelist |
| `lib/features/skins/data/generated/profiles.g.dart` | Perfiles declarativos y sus fórmulas |
| `lib/features/skins/data/generated/images.g.dart` | Imágenes declaradas con checksum del asset versionado |
| `lib/features/skins/data/generated/sounds.g.dart` | Eventos de sonido y su habilitación |
| `assets/catalog/manifest.v2.json` | Manifiesto v2 (se emite aparte de los cinco artefactos Dart) |

Todos los Dart empiezan con `// GENERADO: dart run tool/design/compile.dart. No
editar a mano.` y se pasan por `dart format` al final de cada compilación. Los
checksum de imágenes y sonidos se calculan sobre los bytes de los placeholders
versionados en `design/assets/`; V6/V10 regeneran esos archivos y la
compilación siguiente actualizará los valores.

## Manifiesto v2

```json
{
  "version": 1,
  "channel": "prod",
  "entries": [
    {
      "id": "default",
      "nameKey": "skinDefaultName",
      "isDefault": true,
      "definition": "design/app.design.json",
      "checksum": "<sha256 del JSON con LF canónico>",
      "tokens": {}
    },
    {
      "id": "lcd_classica",
      "nameKey": "skinLcdClassicaName",
      "isDefault": false,
      "definition": "tool/skins/definitions/lcd_classica.yaml",
      "checksum": "26d270cf605e455cbbe2f970d915dfefcd18bae6e9dc7b089220e97669bc77aa",
      "tokens": {}
    }
  ],
  "assets": { "images": [], "sounds": [] },
  "signature": ""
}
```

`definition` es una **ruta**, no un YAML embebido. El checksum se calcula sobre
el contenido LF canónico de esa definición estable; el de `lcd_classica` sigue
siendo `26d270cf…bc77aa` y el compiler falla con mensaje legible si cambiara.

`signature` es la cadena vacía documentada como pendiente de V7. No se guarda
ninguna clave privada en el repositorio; `publishing.publicKey` sigue siendo el
placeholder `RELLENAR_CON_LA_CLAVE_PUBLICA_FIJADA`.

## Compatibilidad con V1

`assets/catalog/manifest.json` (schemaVersion 1, con `definitionYaml`) se
conserva intacto y `dart run tool/skins/generate.dart` lo regenera con el mismo
contenido LF canónico (en Windows el checkout puede materializar CRLF).
El cliente actual (`SkinManifest`) solo acepta v1; V7 migrará la lectura a
`manifest.v2.json`. Por eso el manifiesto v2 se emite como archivo nuevo y el
compiler no reescribe ningún artefacto v1. Tampoco se declara en `pubspec.yaml`
en este slice: V7 añadirá el entry de assets junto con la migración del cliente,
sin dependencias nuevas.

T15 se aplica de forma **aditiva**: `SkinTokens.generatedDefault` y
`Skin.generatedDefault` existen y pasan `validateTokens`, pero
`SkinTokens.classicAmber` sigue siendo el alias temporal de 44 dp y
`SkinRepository.compiledBase` mantiene el par `classicAmber`/`lcdClasica`. La
sustitución real del default y la actualización de goldens quedan para V9, como
ya describe `docs/design/skin-default-48dp.md`.

## Idempotencia

Dos ejecuciones consecutivas producen los mismos bytes: el orden de iteración
proviene del JSON, los saltos de línea son LF y `dart format` es determinista.
Verificación: `git diff --exit-code -- <artefactos>`.
