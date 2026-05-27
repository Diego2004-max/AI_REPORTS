# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Proyecto

**reportes_ai** — Aplicación móvil Flutter de reportes ciudadanos potenciada por IA.  
Los usuarios capturan incidentes urbanos (accidentes, daños viales, fallas de infraestructura) con GPS, imágenes y audio. Los reportes se visualizan en un mapa interactivo y son clasificados/priorizados automáticamente por IA mediante Supabase Edge Functions.

**Stack completo:**
- **Frontend:** Flutter 3.x (Dart 3.11+)
- **Backend:** Supabase (Auth, PostgreSQL, Edge Functions, Storage)
- **Estado:** Riverpod 3.x (FutureProvider, NotifierProvider)
- **Navegación:** Go Router 17.x
- **Persistencia local:** Hive
- **Mapas:** Google Maps Flutter
- **IA:** Groq API (`llama-3.1-8b-instant`) vía Supabase Edge Function en Deno/TypeScript
- **Audio:** `record` + `speech_to_text` + `just_audio`
- **Imágenes:** `image_picker`

---

## Comandos de desarrollo

```bash
# Web (Chrome) — objetivo principal de desarrollo
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=<key> -d chrome

# Android
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=<key> -d <device-id>

# Build de producción (APK)
flutter build apk --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

# Análisis estático
flutter analyze

# Tests
flutter test
flutter test test/path/to/test_file.dart
```

---

## Configuración requerida

Ningún archivo de claves está commiteado. Cada desarrollador configura lo siguiente localmente:

| Servicio | Configuración |
|---|---|
| **Google Maps — Web** | Copiar `web/maps_api.example.js` → `web/maps_api.js` y definir `window.GOOGLE_MAPS_API_KEY` |
| **Google Maps — Android** | Agregar `MAPS_API_KEY=<key>` en `android/local.properties` |
| **Google Maps — iOS** | Definir clave en `ios/Runner/AppDelegate.swift` via `GMSServices.provideAPIKey(...)` |
| **Supabase** | Pasar como `--dart-define=SUPABASE_PUBLISHABLE_KEY=<key>`. La URL del proyecto está en `lib/main.dart` |
| **Edge Function** | Variables en secretos de Supabase: `GROQ_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |

APIs de Google Cloud requeridas: Maps JavaScript API, Maps SDK for Android/iOS, Geocoding API.

---

## Arquitectura

Clean Architecture en tres capas:

```
lib/
├── app/
│   ├── router/           # Go Router — solo maneja auth (login ↔ /app)
│   └── theme/            # AppColors, AppSpacing, AppShadows, AppTextStyles, AppTheme
├── core/
│   ├── constants/        # AppCategories (iconos por categoría), HiveBoxes, SupabaseConstants
│   ├── services/         # AiService, LocationService, VoiceService, SpeechService, MediaService
│   └── utils/            # AppValidators, formatters, helpers
├── data/
│   ├── local/hive/       # HiveService — lectura/escritura de boxes locales
│   ├── models/           # ReportModel, UserModel, AiClassification, AnalyticsModel
│   ├── remote/supabase/  # Datasources remotos (auth, profile, report)
│   └── repositories/     # Implementaciones: AuthRepositoryImpl, ReportRepositoryImpl,
│                         #   AnalyticsRepositoryImpl, ProfileRepositoryImpl
├── domain/
│   └── repositories/     # Interfaces abstractas de repositorios
├── features/
│   ├── analytics/        # StatisticsScreen, HotspotsScreen
│   ├── auth/             # LoginScreen, RegisterScreen
│   ├── home/             # HomeScreen
│   ├── map/              # MapScreen
│   ├── notifications/    # NotificationsScreen (con predicciones de IA)
│   ├── profile/          # ProfileScreen, EditProfileScreen
│   ├── reports/          # CreateReportScreen, CreateWrittenReportScreen,
│   │                     #   CreateAudioReportScreen, ReportListScreen,
│   │                     #   ReportDetailScreen, LocationPickerScreen
│   ├── settings/         # SettingsScreen, ThemeScreen
│   └── shell/            # MainScreen (tab host)
├── shared/
│   └── widgets/          # Sistema de diseño Vial: AppCard, VialButton, VialCard,
│                         #   VialTextField, AiClassificationCard, StatusBadge,
│                         #   AppBottomNav, CustomAppBar, ReportCard, SharedWidgets, …
└── state/                # Todos los Riverpod providers
```

**Flujo de datos:** `features/` → `state/` providers → `data/repositories/` → `data/remote/supabase/` o `data/local/hive/`.

---

## Navegación

La app usa **dos capas de navegación**:

1. **Go Router** (`app/router/app_router.dart`) — solo maneja auth.  
   Observa `sessionProvider`: redirige a `/login` si no autenticado, a `/app` si autenticado.  
   Rutas nombradas: `AppRoutes.login`, `AppRoutes.register`, `AppRoutes.app`, `AppRoutes.notifications`.

2. **Navigator.push / MaterialPageRoute** — toda la navegación interna (detalle de reporte, analytics, ajustes, perfil). Se empuja sobre `MainScreen` y se regresa con pop.

**`MainScreen`** (`features/shell/main_screen.dart`) — `StatefulWidget` que gestiona el índice de tab (`_currentIndex`) y renderiza las 4 pantallas principales:

| Tab | Pantalla |
|---|---|
| 0 | `HomeScreen` |
| 1 | `MapScreen` |
| 2 | `ReportListScreen` |
| 3 | `ProfileScreen` |

El FAB en `AppBottomNav` llama `_onCreateReportTap()` → push `CreateReportScreen`.  
`MainScreen` usa `PopScope` para interceptar el botón Back de Android y mostrar diálogo de confirmación de salida.

---

## Sistema de diseño (Vial)

El app usa el sistema de diseño **Vial** (`shared/widgets/`, `app/theme/`).

### Paleta de colores

| Token | Light | Dark |
|---|---|---|
| `bg` / `darkBg` | `#E8ECF3` | `#1C2033` |
| `surface` / `darkSurface` | `#FFFFFF` | `#252B40` |
| `surfaceVariant` / `darkSurfaceVariant` | — | `#2D3452` |
| `textPrimary` / `darkTextPrimary` | `#1C2033` | `#F0F2FA` |
| `textSecondary` / `darkTextSecondary` | — | — |
| `accent` / `primary` | `#2B4BFF` (electric blue) | igual |
| `success` | `#34C989` | igual |
| `warning` | `#DC963C` | igual |
| `error` | `#E05555` | igual |

**Regla:** Nunca usar hex literal en widgets. Siempre usar `AppColors.*` o `Theme.of(context).*`.

### Tipografía
- **DM Sans** — cuerpo, labels, botones
- **Playfair Display italic** — títulos de app bar, encabezados de pantalla

### Sombras
`AppShadows.card`, `.soft`, `.float`, `.accentGlow`, `.darkCard`, `.darkFloat`, `.darkPressed`  
(modo oscuro usa drop shadows simples, no neumórficas)

### Espaciado
`AppSpacing.xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `screenH` (padding horizontal estándar)

### Modo oscuro/claro
Gestionado por `themeProvider` (persiste en Hive). **Toda** pantalla debe ser completamente adaptativa — usar `isDark = Theme.of(context).brightness == Brightness.dark` y tokens `AppColors.dark*` en modo oscuro. Nunca codificar colores hardcoded en widgets.

---

## Providers (Riverpod)

| Provider | Tipo | Propósito |
|---|---|---|
| `sessionProvider` | `NotifierProvider` | Sesión activa (userId, email, name) persistida en Hive |
| `authProvider` | `Provider` | Singleton `AuthRepositoryImpl` |
| `reportRepositoryProvider` | `Provider` | Singleton `ReportRepositoryImpl` |
| `allReportsProvider` | `FutureProvider` | Todos los reportes (para mapa) |
| `userReportsProvider` | `FutureProvider` | Reportes del usuario autenticado |
| `recentUserReportsProvider` | `FutureProvider.family(int)` | Top N reportes recientes del usuario |
| `userReportStatsProvider` | `FutureProvider` | Conteo por estado: `total`, `submitted`, `reviewing`, `attended` |
| `reportRefreshProvider` | `NotifierProvider<int>` | Incrementar para forzar re-fetch de todos los providers de reportes |
| `themeProvider` | `NotifierProvider` | Modo de tema (light/dark/system), persistido en Hive |
| `globalAnalyticsProvider` | `FutureProvider` | Resumen estadístico de todos los reportes |
| `userAnalyticsProvider` | `FutureProvider` | Resumen estadístico del usuario autenticado |
| `hotspotsProvider` | `FutureProvider` | Zonas de calor agrupadas por densidad de reportes |

**Refrescar reportes:** llamar `refreshReports(ref)` (exportado desde `state/report_provider.dart`) después de crear/actualizar/eliminar un reporte. Invalida todos los providers de reportes y analytics.

---

## Auth y Sesión

- `SessionNotifier` (`state/session_provider.dart`) persiste `isLoggedIn`, `userId`, `userEmail`, `userName` en Hive. Se restaura al reiniciar la app.
- El registro crea una fila en la tabla `profiles`; el login la lee.
- **Google OAuth:** Implementado con flujo PKCE vía `supabase.auth.signInWithOAuth(OAuthProvider.google)`.
- **Recuperación de contraseña:** `LoginScreen` incluye diálogo con `supabase.auth.resetPasswordForEmail(email)`.
- `AuthRepositoryImpl` (`data/repositories/auth_repository_impl.dart`) encapsula toda la lógica de Supabase Auth.

---

## Reportes

### Flujo de creación
`CreateReportScreen` → selector escrito/audio → `CreateWrittenReportScreen` o `CreateAudioReportScreen`

1. **Escrito** (`CreateWrittenReportScreen`):
   - GPS auto-capturado al abrir (via `LocationService`)
   - Selector de categoría (usa `AppCategories.all` de `core/constants/app_constants.dart`)
   - Toggle de severidad
   - Descripción con validación (`AppValidators`)
   - Imagen opcional (JPEG, calidad 75, ancho máx 1600 px)
   - Botón de análisis IA → muestra `AiClassificationCard` inline antes de enviar
   - **LocationPickerScreen:** botón para abrir mapa interactivo y ajustar coordenadas manualmente

2. **Audio** (`CreateAudioReportScreen`):
   - Grabación via `VoiceService` (wrapper del paquete `record`)
   - Transcripción opcional via `SpeechService` (`speech_to_text`)
   - Análisis IA automático al detener grabación
   - También soporta `LocationPickerScreen`

### LocationPickerScreen
`features/reports/presentation/screens/location_picker_screen.dart`  
Pantalla de mapa a pantalla completa donde el usuario puede:
- Tocar el mapa para colocar/mover el marcador
- Arrastrar el marcador para afinar posición
- Buscar por dirección en la barra superior
- Pulsar "Mi ubicación" para centrar en GPS actual

Devuelve `LocationPickerResult(latitude, longitude, label)` via `Navigator.pop`.

### Estados de reporte
Almacenados como strings en Supabase. `UserReportStatus` enum en `report_repository_impl.dart`:
- `submitted` → `'Enviado'`
- `reviewing` → `'En revisión'`
- `attended` → `'Atendido'`

Para mostrar en UI usar `ReportStatusExt.fromString(report.status)` (fuzzy matching en `shared/widgets/shared_widgets.dart`).

### ReportModel — invariantes
- `latitude`/`longitude` son nullable; los marcadores del mapa solo se crean cuando ambos no son null.
- `imagePaths` es `List<String>` pero solo el primer elemento se persiste como `image_url` en Supabase.
- Los reportes expiran 10 días después de creación (`expiresAt`).
- Campos de IA: `aiCategory`, `aiSeverity`, `aiConfidence`, `aiSummary` (todos nullable).

---

## Pipeline de IA

> El pipeline de IA es **opcional y no bloqueante**. Si falla cualquier paso, el reporte se guarda sin campos de IA. Nunca hacer la IA un requisito duro para enviar un reporte.

### Edge Function (`supabase/functions/ai-report-processor/index.ts`)
Corre en Deno/TypeScript. Llama a **Groq API** (modelo: `llama-3.1-8b-instant`). Tres acciones:

| Acción | Descripción | Salida |
|---|---|---|
| `classify` | Clasifica el reporte por categoría, severidad y confianza | `category`, `severity`, `confidence`, `sensitive_location`, `road_impact` |
| `credibility` | Score de credibilidad 0.0–1.0 basado en historial del usuario y corroboración geográfica | `credibility_score` |
| `priority` | Score de prioridad ponderado 0.0–1.0 | `priority_score` |

**Categorías IA** (difieren de las categorías del formulario):  
`"Accidente de tránsito"` · `"Infraestructura"` · `"Seguridad"` · `"Emergencia climática"` · `"Servicios públicos"`

**Ponderación de prioridad:** severidad 35% · confirmaciones 20% · ubicación sensible 15% · impacto vial 15% · credibilidad 15%

### AiService (`core/services/ai_service.dart`)
Invoca la Edge Function via `supabase.functions.invoke(...)`. Tres métodos:
- `classifyReport({description, locationLabel?, transcribedAudio?})`
- `getCredibilityScore({userId, description, latitude, longitude})`
- `getPriorityScore({classification, credibilityScore})`

Valores de fallback cuando la IA es omitida: `credibilityScore=1.0`, `priorityScore=0.5`.

### AiClassification (`data/models/ai_classification.dart`)
Modelo que mapea la respuesta de la Edge Function. Campos: `category`, `severity`, `confidence`, `summary`, `sensitiveLoc`, `roadImpact`, `rawSeverity`.

### AiClassificationCard (`shared/widgets/ai_classification_card.dart`)
Widget que muestra el resultado de clasificación con:
- Badge de severidad con su color semántico (verde/naranja/rojo)
- Barra de confianza horizontal con porcentaje
- Categoría, resumen y etiquetas

---

## Mapa

- Centro inicial: `LatLng(1.2136, -77.2811)` (Pasto, Colombia)
- Marcadores solo para reportes con coordenadas no null
- **Íconos personalizados por severidad** (generados con `dart:ui` canvas en `_buildSeverityMarker`):
  - Leve (verde ✓) · Moderado (naranja ▲) · Crítico (rojo !) · Default (azul •)
- **Separación de marcadores solapados:** `_spreadPositions()` detecta reportes con las mismas coordenadas y aplica offset en espiral (~9 m) para que cada uno sea tappable individualmente
- **Bottom sheet al tocar marcador:** muestra badge de severidad, categoría, título y ubicación — reemplaza `InfoWindow`
- Chips de filtro por categoría en la parte superior
- El mapa aparece gris/en blanco si falta la API key de Google Maps

---

## Pantallas de Analytics

### StatisticsScreen (`features/analytics/statistics_screen.dart`)
- Toggle Global / Mis reportes (usa `globalAnalyticsProvider` o `userAnalyticsProvider`)
- Tarjetas de resumen: Total, Enviados, En revisión, Atendidos
- Gráfico de barras animado: actividad de los últimos 7 días
- Desglose por categoría con barras de progreso y porcentajes
- Tarjeta highlight: categoría más reportada

### HotspotsScreen (`features/analytics/hotspots_screen.dart`)
- Google Map con círculos de calor por zona
- Color por nivel de riesgo: verde (bajo) · naranja (medio) · rojo (alto)
- Radio proporcional a la densidad de reportes
- Panel inferior con resumen de zonas activas
- Bottom sheet al tocar zona: conteo, categoría top, score de riesgo

Ambas pantallas son completamente adaptativas al modo oscuro.

---

## NotificationsScreen

`features/notifications/notifications_screen.dart` — además del estado vacío estándar incluye:

- **`_RiskSummaryCard`:** nivel de riesgo en la zona (Bajo/Moderado/Alto) calculado desde `globalAnalyticsProvider`. Muestra el total de reportes y la categoría más frecuente.
- **`_CategoryPredictions`:** lista de categorías con nivel de riesgo predicho, conteo de reportes y enlace a `ReportListScreen` con filtro preseleccionado.

---

## Tablas de Supabase

### `reports`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → `auth.users` |
| `title` | text | Título del reporte |
| `description` | text | Descripción detallada |
| `category` | text | Categoría UI seleccionada por el usuario |
| `status` | text | `'Enviado'` / `'En revisión'` / `'Atendido'` |
| `latitude` | float8 | Coordenada GPS |
| `longitude` | float8 | Coordenada GPS |
| `location_label` | text | Etiqueta de ubicación legible |
| `image_url` | text | URL de imagen en Supabase Storage |
| `audio_url` | text | URL de audio en Supabase Storage |
| `ai_category` | text | Categoría asignada por IA |
| `ai_severity` | text | Severidad: leve / moderado / critico |
| `ai_confidence` | float8 | Confianza 0.0–1.0 |
| `ai_summary` | text | Resumen generado por IA |
| `priority_score` | float8 | Score de prioridad 0.0–1.0 |
| `credibility_score` | float8 | Score de credibilidad 0.0–1.0 |
| `expires_at` | timestamptz | Expiración (10 días desde creación) |

### `profiles`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | uuid | FK → `auth.users` |
| `full_name` | text | Nombre completo |
| `email` | text | Correo electrónico |

---

## Hive (persistencia local)

Definido en `core/constants/hive_boxes.dart`. Seis boxes:

| Box | Propósito |
|---|---|
| `settings` | Configuración de la app (tema, preferencias) |
| `session` | Sesión del usuario autenticado |
| `users` | Caché de datos de usuario |
| `reports` | Caché local de reportes |
| `reportDrafts` | Borradores de reportes |
| `reportCache` | Caché adicional de reportes |

Acceder con `HiveKeys.*` — nunca con strings literales.

---

## Validadores

`core/utils/validators.dart` — `AppValidators`:
- `required(value, {field})` — campo obligatorio
- `minLength(value, min, {field})` — longitud mínima
- `email(value)` — formato de correo
- `password(value)` — mínimo 8 caracteres con al menos un número

---

## Reglas de código

- **Idioma:** Todo el código, variables, comentarios, nombres de clase y documentación en **inglés**. Las strings de UI mostradas al usuario pueden estar en español.
- **Colores:** Nunca hex literal en widgets — siempre `AppColors.*` con guarda `isDark`.
- **Espaciado:** Siempre `AppSpacing.*` — nunca números mágicos de padding/margin.
- **IA no bloqueante:** El pipeline de IA envuelto en try/catch; el reporte se guarda aunque falle.
- **Navegación:** Usar `Navigator.push` / `context.go` según la capa correspondiente. No mezclar capas.
- **Riverpod:** Usar `refreshReports(ref)` después de cualquier mutación de reporte.
