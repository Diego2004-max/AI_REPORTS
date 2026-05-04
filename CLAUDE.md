# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**reportes_ai** — Flutter citizen-reporting app powered by AI. Users capture urban incidents (accidents, road damage, infrastructure failures) with GPS, images, and audio. Reports are visualized on an interactive map and classified/prioritized via Gemini 2.0 Flash through Supabase Edge Functions.

Stack: Flutter · Supabase (Auth, DB, Edge Functions) · Riverpod · Go Router · Hive · Google Maps

## Development Commands

```bash
# Web (Chrome) — primary development target
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=<key> -d chrome

# Android
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=<key> -d <device-id>

# Release build
flutter build apk --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

# Static analysis
flutter analyze

# All tests
flutter test

# Single test file
flutter test test/path/to/test_file.dart
```

## Required Configuration

No key files are committed. Each developer sets up these locally:

**Google Maps — Web:** Copy `web/maps_api.example.js` → `web/maps_api.js` and set `window.GOOGLE_MAPS_API_KEY`.  
**Google Maps — Android:** Add `MAPS_API_KEY=<key>` to `android/local.properties`.  
**Google Maps — iOS:** Set key in `ios/Runner/AppDelegate.swift` via `GMSServices.provideAPIKey(...)`.  
**Supabase:** Pass as `--dart-define=SUPABASE_PUBLISHABLE_KEY=<key>`. The project URL is hardcoded in `lib/main.dart`.

Required Google Cloud APIs: Maps JavaScript API, Maps SDK for Android/iOS, Geocoding API.

## Architecture

Clean Architecture in three layers:

```
lib/
├── app/           # MaterialApp, Go Router, theme (colors, spacing, shadows, text styles)
├── core/          # Cross-cutting services: LocationService, VoiceService, SpeechService, AiService
├── data/          # Models, repository implementations, Supabase datasources, Hive local storage
├── domain/        # Abstract repository interfaces
├── features/      # Screens per feature: auth, home, map, reports, profile, analytics, settings
├── shared/        # Reusable widgets — "Vial" design system (VialButton, VialCard, VialTextField)
└── state/         # All Riverpod providers
```

Data flow: `features/` → `state/` providers → `data/repositories/` → `data/remote/supabase/` or `data/local/hive/`.

## Design System

The app uses a custom design system called **Vial** (`shared/widgets/`, `app/theme/`). All design work must follow these conventions:

**Color philosophy:** The palette uses deep navy/slate tones (not generic blue/gray) with electric accent colors. Never default to generic Material blue (`#2196F3`) or plain gray. Use the constants defined in `app/theme/app_colors.dart`.

**Current palette:**
- Light background: `#E8ECF3` · Surface: `#FFFFFF` · Text: `#1C2033`
- Dark background: `#1C2033` · Surface: `#252B40` · Text: `#F0F2FA`
- Primary accent: `#2B4BFF` (electric blue)
- Semantic: success green, warning orange, error red — each with a soft variant

**Typography:** DM Sans for body/display; Playfair Display italic for app bar titles. Do not introduce new fonts without updating `pubspec.yaml` and verifying Google Fonts availability.

**Shadows:** Neumorphic dual-color shadows (light + dark pair) defined in `app/theme/app_shadows.dart`. Use `AppShadows.card`, `.soft`, `.float`, `.accentGlow`.

**Spacing:** Always use `AppSpacing` constants (`xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`). Never use magic numbers for padding/margin.

**Dark/Light Mode:** Managed by `themeProvider` (NotifierProvider, persisted in Hive). Both themes must be fully implemented — no screen should rely on hardcoded colors. Always use `Theme.of(context)` or `AppColors` semantic tokens, never literal hex values in widgets.

## Key Providers

| Provider | Type | Purpose |
|---|---|---|
| `sessionProvider` | `NotifierProvider` | Active user session (persisted in Hive) |
| `authProvider` | `Provider` | `AuthRepositoryImpl` singleton |
| `reportRepositoryProvider` | `Provider` | `ReportRepositoryImpl` singleton |
| `allReportsProvider` | `FutureProvider` | All reports for map display |
| `userReportsProvider` | `FutureProvider` | Reports for the logged-in user |
| `recentUserReportsProvider` | `FutureProvider.family(int)` | Top N recent reports for user |
| `userReportStatsProvider` | `FutureProvider` | Per-status counts for dashboard |
| `reportRefreshProvider` | `NotifierProvider` | Increment to trigger report re-fetch |
| `themeProvider` | `NotifierProvider` | Theme mode (light/dark/system), persisted in Hive |

## Auth & Session

- `state/session_provider.dart` (`SessionNotifier`) persists `isLoggedIn`, `userId`, `userEmail`, `userName` in Hive. Session is restored on app restart.
- Go Router (`app/router/app_router.dart`) watches `sessionProvider`: redirects to `/login` when unauthenticated, to `/app` when authenticated.
- Registration creates a row in the `profiles` table; login fetches from it.

## Reports

**Two creation flows:**
1. **Written** (`CreateWrittenReportScreen`) — GPS auto-captured on open, category selector, severity toggle, description, optional image, AI analysis button.
2. **Audio** (`CreateAudioReportScreen`) — records via `VoiceService` (wraps `record` package), optional transcription via `SpeechService`.

**Report status literals:** `'Enviado'` · `'En revisión'` · `'Atendido'` — match exactly in all code.

**ReportModel invariants:**
- `latitude`/`longitude` are nullable; map markers are only created when both are non-null.
- `imagePaths` is `List<String>` but only the first element is persisted as `image_url` in Supabase.
- Reports expire 10 days after creation (`expiresAt`).

## AI Pipeline

The AI pipeline is **optional and non-blocking** — if any step fails, the report is saved without AI fields. Never make AI a hard dependency for report submission.

**Edge Function** (`supabase/functions/ai-report-processor/index.ts`) runs on Deno/TypeScript and uses Gemini 2.0 Flash. Three actions:
- `classify` — assigns category, severity, confidence, `sensitive_location`, `road_impact`
- `credibility` — scores 0.0–1.0 based on user frequency, geographic corroboration, description length
- `priority` — weighted score: severity 35%, confirmations 20%, sensitive location 15%, road impact 15%, credibility 15%

`AiService` in `core/services/ai_service.dart` invokes the function via `supabase.functions.invoke(...)`.

## Map

- Initial center: `LatLng(1.2136, -77.2811)` (Pasto, Colombia).
- Markers only rendered for reports with non-null coordinates.
- Map appears gray/blank if Google Maps API key is missing or empty.

## Supabase Tables

- **`reports`** — all `ReportModel` fields plus `ai_category`, `ai_confidence`, `priority_score`, `credibility_score`, `image_url`, `audio_url`, `expires_at`.
- **`profiles`** — `id` (FK → `auth.users`), `full_name`, `email`.

## Hive Boxes

Defined in `core/constants/hive_boxes.dart`. Six boxes: `settings`, `session`, `users`, `reports`, `reportDrafts`, `reportCache`. Keys are accessed via `HiveKeys.*` constants — never use raw strings.

## Code Language

All code, variable names, comments, class names, and documentation must be written in **English**. UI strings displayed to users may remain in Spanish (the app's target language). No new Spanish identifiers or comments should be introduced.
