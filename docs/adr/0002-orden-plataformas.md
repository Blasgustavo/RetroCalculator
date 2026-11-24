# 0002 — Orden de plataformas

- **Fecha:** 2026-11-24
- **Estado:** Accepted

## Contexto

RetroCalculator se dirige a Android, Windows e iOS, pero los recursos de la fase inicial son limitados y conviene validar primero el núcleo de cálculo y el modelo de skins. Las tres plataformas no ofrecen las mismas condiciones: Android tiene APIs maduras de anuncios recompensados y facturación; Windows carece de AdMob y de IAP móviles; iOS exige ATT, privacy manifest y el uso obligatorio de IAP de Apple para bienes digitales. El orden de entrega afecta al CI y a la monetización desde el primer commit.

## Decisión

El orden de trabajo es **Android → Windows → iOS**.

1. **Android** es la plataforma inicial: base del proyecto Flutter, AdMob (solo anuncios recompensados) y Google Play Billing.
2. **Windows** se desarrolla después: se adaptan la calculadora y las skins a escritorio.
3. **iOS** se deja para el final: se atienden ATT, privacy manifest y compras vía App Store.

## Alternativas descartadas

- **iOS primero:** obliga a resolver certificados, ATT y revisión de App Store antes de validar el motor y la monetización.
- **Windows primero:** sin AdMob ni IAP móvil, la monetización acordada en el ADR 0001 quedaría sin resolver en la primera entrega.
- **Desarrollo simultáneo de las tres plataformas:** multiplica el coste de CI y de revisiones antes de tener un núcleo estable.

## Consecuencias

### CI

Los workflows de `.github/workflows/` se crean en el orden acordado:

1. `android.yml` — `flutter pub get`, `flutter analyze`, `flutter test` y build APK/AAB con flavors `dev`/`staging`/`prod` y secrets de keystore.
2. `windows.yml` — analyze, test y build MSIX, después de Android.
3. `ios.yml` — analyze, test, build IPA y gestión de certificados/ATT, al final.

Cada plataforma se considera lista solo cuando `flutter analyze` y `flutter test` pasan en su workflow.

### Monetización

- En **Android** se integran AdMob (recompensados) y Google Play Billing; es la plataforma de referencia para entitlement y duraciones.
- En **Windows**, AdMob y las IAP móviles no aplican. Quedan abiertas las opciones de skins gratis en escritorio, códigos de canje generados en móvil o Microsoft Store IAP. La capa `features/monetization/entitlements/` debe poder operar sin depender de esas APIs nativas.
- En **iOS** rigen ATT y el privacy manifest, y los bienes digitales deben comprarse obligatoriamente mediante IAP de Apple; no se reutilizan credenciales de Google Play.
