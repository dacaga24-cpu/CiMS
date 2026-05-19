# Audit Frontend CiMS — 2026-05-19

**Entorno auditado:** https://cims-web-84caf.web.app/ (Firebase Hosting prod)
**Usuario de pruebas:** mabi24@bemen3.cat
**Viewports probados:** Desktop 1440×900 + Móvil 390×844
**Método:** revisión de código (`/home/vant/_Projects/CiMS/frontend/lib`) + Playwright

---

## TL;DR — Prioridades antes del lanzamiento

| # | Severidad | Bug |
|---|-----------|-----|
| 1 | 🔴 Bloqueante | "Termes de Servei" en el registro abre stub: *"Aquesta secció encara no està disponible"*. Problema legal: estás obligando al usuario a aceptar términos inexistentes. |
| 2 | 🔴 Bloqueante | Date picker de "Registrar ascensió" 100% en **inglés** (Tue, May 19, Cancel, OK, días S/M/T/W/T/F/S). Resto de la app está en catalán. Falta `supportedLocales` + `localizationsDelegates` en `MaterialApp.router`. |
| 3 | 🟠 Alta | URL del detall de cim queda como literal `/peaks/:peakId` (no se sustituye el id). Rompe deep linking, bookmarks y compartir enlaces. |
| 4 | 🟠 Alta | Layout responsive **inconsistente** post-login: a 1440×900 a veces se ve la bottom-nav móvil, otras el sidebar desktop según cómo llegues a `/main`. |
| 5 | 🟠 Alta | Botón **"Has oblidat la contrasenya?"** dispara la validación del form de login → aparece a la vez *"La contrasenya és obligatòria"* (rojo) y *"Si el correu existeix, t'hem enviat un enllaç…"* (azul). El email **sí llega** (confirmado por usuario), pero la UX confunde porque hay un error visible. |
| 6 | 🟡 Media | Inconsistencia en formato altitud: dashboard ascensiones usa `3.029 m`, catalog/objectius/preferits/peak-detail usan `3029 m`. Misma cima distinta presentación. |
| 7 | 🟡 Media | Inconsistencia unidad: "m", "metres", "M" (mayúscula) según pantalla. |
| 8 | 🟡 Media | Botones secundarios (Cancel·lar, Ja tinc un compte, Tancar sessió, Historial ascensions, Netejar) en gris claro — parecen deshabilitados aunque estén activos. |
| 9 | 🟡 Media | Singular/plural mal: "1 cims" en mapa al filtrar (debe ser "1 cim"). |
| 10 | 🟡 Media | "Desactivar compte" abre diálogo sin advertencia de consecuencias y con botón confirmar en **azul** en vez de rojo destructivo. |

---

## 1. Localización (Date picker en inglés)

**Ruta:** `frontend/lib/main.dart` — `MaterialApp.router(...)`
**Estado actual:** `grep "supportedLocales\|locale\|Locale(" --include="*.dart"` → 0 resultados.

**Fix:**
```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp.router(
  supportedLocales: const [Locale('ca'), Locale('es'), Locale('en')],
  locale: const Locale('ca'),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  ...
)
```

Y añadir `flutter_localizations: { sdk: flutter }` al `pubspec.yaml`.

Esto arregla automáticamente:
- Date picker (días, meses, "Cancel"/"OK")
- Primera columna del calendario = lunes en lugar de domingo
- TimePicker si lo añades en el futuro
- Tooltips de scrollbar, etc.

---

## 2. Formato altitud — 5 implementaciones distintas de `_formatNumber`

Localizados con `grep "_formatNumber\|altitude.*m'"`:

| Archivo | Línea | Output | Separador |
|---------|------:|--------|:---------:|
| `dashboard_recent_ascents_section.dart` | 192 | `3.029 m` | ✓ |
| `stats_recent_ascents_list.dart` | 169 | `3.029m` (sin espacio) | ✓ |
| `stats_total_meters_card.dart` | 73 | `5.532 m` | ✓ |
| `stats_most_ascended_card.dart` | 80 | `3.029 m` | ✓ |
| `ascent_history_header.dart` | 84 | `3.029 M` (mayúscula) | ✓ |
| `dashboard_peak_tile.dart` | 26 | `3029 m` | ✗ |
| `peak_detail_card.dart` (catalog) | 72 | `3029 m` | ✗ |
| `ascent_register_peak_summary.dart` | 45 | `3029 m` | ✗ |
| `ascent_edit_screen.dart` | 371 | `3029 m` | ✗ |
| `peak_detail` (en pantalla) | — | `3143 metres` | ✗, unidad larga |

**Fix recomendado:** Crear `core/util/format.dart` con:
```dart
String formatAltitude(int? meters) {
  if (meters == null) return '';
  final formatter = NumberFormat.decimalPattern('ca');
  return '${formatter.format(meters)} m';
}
```
Y usarlo en todos los lugares. Decidir si la unidad es "m" o "metres" y unificar (recomendado: "m" en listas, "metres" solo en hero del peak detail si quieres legibilidad larga).

5 funciones `_formatNumber` duplicadas en distintos widgets — también merece extracción.

---

## 3. Routing — `/peaks/:peakId` no se sustituye

**Ruta:** `app/router/app_router.dart:52`
```dart
AutoRoute(
  page: PeakDetailRoute.page,
  path: '/peaks/:peakId',
  guards: [authGuard],
),
```

Pero al navegar (`app_router.gr.dart`) se pasa como args, no como path-param:
```dart
args: PeakDetailRouteArgs(key: key, peakId: peakId)
```

Resultado: la URL queda literal `/peaks/:peakId` y los datos viajan en memoria. Pruebas hechas:
- ✓ La pantalla carga correctamente con los datos del peak
- ✗ Recargar F5 en `/peaks/:peakId` muestra error / pierde el peak
- ✗ Compartir el link no funciona
- ✗ Bookmark no funciona

**Fix:** Cambiar las llamadas de navegación a `context.router.pushPath('/peaks/$peakId')` o ajustar el route generator para serializar el `peakId` en la URL.

Mismo patrón se ve en otras rutas con args (`/ascents/edit`, `/ascents/history`) — convendría auditarlas todas.

---

## 4. Layout responsive inconsistente

Código en `main_navigation_screen.dart:65`:
```dart
final isCompact = AppResponsive.isCompact(context); // < 600px

body: isCompact
  ? Column(...) // bottom nav
  : Row(...)    // sidebar
```

Breakpoints en `app_responsive.dart`:
- compact: < 600
- medium: 600-1200
- expanded: >= 1200

A 1440×900 debería ser expanded → sidebar siempre. Pero observé:

| Cómo llego a /main | Layout |
|--------------------|--------|
| Después de hacer login | bottom nav (mobile) ❌ |
| Reload directo a /main | sidebar (desktop) ✓ |
| Click MAPA, INICI, LLISTAT, DADES tras login | bottom nav (mobile) ❌ |

Hipótesis: el `MediaQuery.sizeOf(context).width` se evalúa con un contexto que aún no tiene tamaño correcto en el primer build después del login, o el AutoTabsRouter se construye antes de la ventana definitiva.

**Repro:**
1. Abrir DevTools en 1440×900
2. Login con mabi24@bemen3.cat / bemen301
3. Observas bottom-nav móvil con avatar en esquina superior derecha
4. Recargar la página (F5)
5. Aparece el sidebar correcto con perfil abajo izquierda

**Fix sugerido:** envolver el `build` en `LayoutBuilder` y usar `constraints.maxWidth` en vez de `MediaQuery`, o forzar un `setState` cuando el primer frame se renderice tras login.

---

## 5. Login "Has oblidat la contrasenya?" — UX confusa

Al clicar el botón:
1. Si el email está vacío → muestra los errores del form (`La contrasenya és obligatòria`, `Has d'introduir un correu vàlid`) **sin disparar la recuperación**.
2. Si el email está rellenado → muestra **a la vez** el error rojo `La contrasenya és obligatòria` **y** el mensaje azul `Si el correu existeix, t'hem enviat un enllaç…`.

El email de recuperación **sí llega** (confirmado por usuario), o sea el endpoint funciona. El problema es solo el handler del botón que pasa por la misma validación del form de login.

**Fix:** Separar `_onLoginPressed` de `_onForgotPasswordPressed` para que el segundo solo valide el campo email, no la contraseña.

---

## 6. Pantalla "Desactivar compte" — peligrosa

Al clicar "Desactivar compte" en perfil:
- Diálogo titulado "Desactivar compte"
- Texto: *"Introdueix la teva contrasenya actual per confirmar aquesta acció"*
- Botón confirmar **AZUL** (color de acción positiva)
- Sin warning de consecuencias (¿se borran ascensiones? ¿es reversible?)

**Fixes:**
- Cambiar el botón a rojo destructivo (`Theme.of(context).colorScheme.error`).
- Añadir mensaje claro: *"Aquesta acció és irreversible. Es perdran totes les teves ascensions registrades."* (o lo que sea verdadero).
- Si efectivamente solo desactiva (no borra), renombrar a "Desactivar (es pot reactivar)" o "Eliminar compte" según sea el caso real.

---

## 7. Pantalla "Canviar contrasenya" — sin botón mostrar/ocultar

Los 3 campos (actual, nova, confirmar) son `obscureText` pero no tienen toggle de ojo como sí lo tiene el login. Inconsistente y propenso a errores de tipeo.

**Fix:** reutilizar el widget de password input con toggle del login.

---

## 8. Pantalla "Dades personals" — falta email

El diálogo solo tiene Nom y Cognoms. No hay forma de cambiar email desde la app. Si el usuario se equivocó, tiene que crear cuenta nueva (o llamar a soporte).

Decidir: ¿permitir cambiar email (necesita re-verificación) o ya está fuera de scope para v1.0?

---

## 9. Singular/plural y normalización catalán

| Lugar | Texto actual | Correcto |
|-------|--------------|----------|
| Mapa, badge al filtrar 1 cim | "1 cims" | "1 cim" |
| Register, label | "Cognom" | "Cognoms" (consistente con Profile que sí usa plural) |
| Peak detail | "3143 metres" | unificar con "m" o "metres" |
| Ascent history | "3.029 M" (mayúscula) | "3.029 m" |
| Modal Desactivar | botón "Desactivar compte" igual al item de lista | el botón debería ser "Confirmar" o "Eliminar" según el caso |

---

## 10. Botones gris-claro que parecen deshabilitados

| Botón | Pantalla | Tipo |
|-------|----------|------|
| Cancel·lar (diálogos) | Dades personals, Canviar contrasenya, Desactivar | Secundario |
| Cancel·lar | Ascent register / edit | Secundario |
| Ja tinc un compte | Register | Secundario |
| Tancar sessió | Profile settings | Importante |
| Historial ascensions | Peak detail | Secundario |
| Neteja | Filtres bottom sheet | Secundario |

**Fix:** Usar `OutlinedButton` (con borde) o `TextButton` con texto azul, en vez de `ElevatedButton` con fondo gris claro. Llama mucho menos la atención y se ve claramente activo.

---

## 11. Verificació d'ascensió — error en desktop sin permisos

URL `/ascents/verify` (el FAB central) muestra:
*"No s'ha pogut preparar la verificació. Revisa els permisos de càmera i ubicació."*

Sin permisos, no hay alternativa visible. El usuario desktop sin webcam o que niega permisos queda atascado.

**Fixes:**
- Especificar qué permiso falta concretamente (cámara, ubicación, o ambos).
- Ofrecer fallback "Registrar manualment sense verificar" desde aquí.
- En desktop, considerar deshabilitar el FAB de verificación o renombrarlo "Registrar ascensió" sin paso de cámara.

---

## 12. Pantalla DADES en mobile — orden de elementos

El selector de rango (Mes/Trimestre/6 mesos/Any/Total) aparece **después** del bar chart en lugar de antes. Esperado: filtro arriba, datos abajo.

Verificar en `user_stats_screen.dart` orden de hijos.

---

## 13. Mapa — controles de Google ocupan espacio en móvil

En móvil, en la parte inferior del iframe del mapa se ven:
"Keyboard shortcuts | Map Data | Terms (opens in new tab) | Report a map error"

Estos enlaces son inútiles en móvil y compiten por espacio con el badge "999 cims" y el botón fullscreen.

**Fix:** En la opción de creación del GoogleMap añadir `mapToolbarEnabled: false`, `zoomControlsEnabled: false` si no son necesarios. Para los "©Google" se puede sobreponer con CSS overlay propio o reducir su altura.

---

## 14. Dashboard "Fotos recents" limitada a 3

Solo aparecen 3 thumbnails. No hay forma rápida de añadir más fotos desde aquí. "Veure galeria" lleva a la galería completa pero sin afordance de "subir nueva foto" — solo se sube desde Registrar Ascensió.

Decisión de producto: ¿debería haber un botón "+" para añadir foto a la última ascensión? Opcional.

---

## 15. Photo gallery modal — sin navegación entre fotos

Al abrir una foto en grande no hay flechas izquierda/derecha. Para ver la siguiente foto hay que cerrar y abrir. UX rota para galerías.

**Fix:** Añadir PageView con gestos de swipe y/o flechas.

---

## 16. Padding inferior insuficiente en listas

En **móvil**, los últimos items de:
- Dashboard "Últimes ascensions"
- Catalog
quedan parcialmente ocultos detrás del bottom nav (con FAB sobresaliendo). Falta `SliverPadding` o `padding.bottom: kBottomNavigationBarHeight + 16` en los `ListView`s.

---

## 17. Errores en consola (no bloqueantes pero ruido)

```
GET /api/users/profile → 401  (antes del login, normal)
GET /api/dashboard → 401      (antes del login, normal)
GET /api/peak-status/1 → 404  (al abrir un peak nuevo — endpoint inexistente o peak sin status)
Error en main.dart.js:3957    (Dart error al hacer goBack desde varias pantallas)
```

Los 404 y el Dart-error al volver atrás son potenciales memory-leaks o un controller cerrado al que se llama después de dispose. Worth investigar con un Flutter Web debug build.

---

## 18. Términos de Servicio (stub) — 🔴 BLOQUEANTE LEGAL

`register_screen.dart:48-49` muestra alert con texto:
> "Aquesta secció encara no està disponible."

Y el form de registro dice *"En registrar-te, acceptes els nostres Termes de Servei"*.

**No puedes lanzar producto pidiendo aceptar términos inexistentes.** Imprescindible:
- Redactar Términos de Servicio + Política de Privacidad (con menciones a tratamiento de geoloc, fotos, email).
- Sustituir el alert por una pantalla (o navegación externa) con el texto real.
- Lo mismo aplica al checkbox/texto de "He llegit i accepto..." si lo añadís.

---

## 19. Pequeños detalles visuales

- Avatar del header tiene 40×40 (recomendado 48×48 mínimo para tap target).
- El avatar no tiene `aria-label` — el screen reader no sabe que es "Perfil".
- En la pantalla de profile settings hay un enorme bloque vacío entre el email del usuario y la sección "CONFIGURACIÓ", tanto en desktop como en móvil. Layout poco aprovechado.
- En login desktop también hay un gran espacio entre el logo y el formulario.
- "marc biLanto" tiene una L mayúscula intermedia — probablemente dato del usuario, no bug, pero conviene confirmar que el form de registro no fuerza/permite mayúsculas raras.

---

## Lo que SÍ funciona bien

- Login con credenciales válidas: fluido y rápido.
- Validación de campos en login (cuando es correcta).
- Bottom nav móvil con FAB central: bien diseñado.
- Búsqueda y filtros del catálogo y mapa (incluyendo paginación lazy).
- Toggle "Objectiu/Preferit" en peak detail: persiste correctamente entre pantallas.
- Diálogo de confirmación "Registrar ascensió sense data?" — buena UX.
- Página de stats con bar chart, top 3 y métricas: bien estructurada.
- Email de recuperación de contraseña: el backend lo envía correctamente.
- Validación de contraseña con mínimo 8 caracteres.
- Imagen de perfil con presigned URLs de GCS funciona.
- No hay TODOs/FIXMEs ni dead code escondido en `lib/` (verificado).
- Sin `print()` en producción, solo `debugPrint()` para errores.

---

## Checklist sugerido para "go-live"

- [ ] Añadir `flutter_localizations` y configurar `supportedLocales: ca` → arregla date picker
- [ ] Sustituir stub Termes de Servei por contenido real (legal)
- [ ] Redactar Política de Privacitat
- [ ] Crear `formatAltitude()` util y reemplazar las 9 ocurrencias inconsistentes
- [ ] Fix routing peak detail → URL real con id (`pushPath` o `path-replace`)
- [ ] Fix responsive post-login (LayoutBuilder o re-build forzado)
- [ ] Separar handler "Has oblidat la contrasenya?" del validador del form
- [ ] "Desactivar compte" botón en rojo + warning explícito
- [ ] Toggle ojo en password fields de "Canviar contrasenya"
- [ ] Padding inferior en listas móviles para no quedar detrás del FAB
- [ ] Plurals: "1 cim" / "X cims"
- [ ] Aria-label para avatar/menú perfil
- [ ] Investigar Dart error al `goBack` (potencial use-after-dispose)
- [ ] Definir Terms de Servicio y Política de Privacitat antes de pedir aceptación
- [ ] Probar deep linking en producción una vez arreglada la URL

---

**Screenshots guardados en** `/home/vant/_Projects/` con prefix `audit-19may-*`.
