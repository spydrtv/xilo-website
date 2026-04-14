# XILO Music

## Overview
A cross-platform music streaming and distribution platform for independent musicians and AI music creators. Mobile (iOS/Android) is streaming-only; web is the marketplace for purchases, licensing, and creator uploads. The brand is modern, inclusive, and future-facing.

## Tech Stack & Key Decisions
- Provider + ChangeNotifier for state — app is medium complexity; providers are app-global here because player/library state persists across all tabs
- go_router with StatefulShellRoute for mobile bottom nav; web redirects to `/web` route via kIsWeb check in router redirect
- Supabase as backend (supabase_flutter ^2.8.4) — project URL and anon key initialized in both `app_services_stub.dart` (web) and `app_services_mobile.dart` (iOS)
- cached_network_image for all artwork with consistent placeholder/error handling
- google_fonts (Inter) for clean, modern typography fitting the brand
- dart:html used directly in `creator_upload_service.dart` for file picking/reading — web-only, never imported on mobile

## Architecture
- Data flows: UI → Providers → Services → Repositories → Models
- Platform split via Dart conditional imports in `lib/platform/app_services.dart` — BOTH platforms now initialize Supabase; web stub uses mock catalog data but real Supabase auth; iOS uses real Supabase for everything
- `AppServices.initialize()` is awaited in `main()` before `runApp` — returns `MusicService` and `LibraryService` typed identically on both platforms; providers never know the difference
- `SupabaseMusicRepository` extends `MusicRepository` and overrides all getters; calls `preload()` at startup to fetch all catalog data; falls back to mock data silently per-method if Supabase is unreachable or tables are empty
- `SupabaseLibraryRepository` extends `LibraryRepository`; writes to Supabase in background only when user is signed in; in-memory state always updated immediately for responsive UI
- Providers (PlayerProvider, LibraryProvider, SearchProvider) remain typed to the original service classes — no provider changes needed for Supabase integration
- PlayerProvider simulates playback with a Timer; ready to swap for `just_audio` real audio backend
- Web and mobile share the same providers/services — router redirect separates the experiences
- All purchasing/licensing/upload UI exists only on the web route; mobile is streaming-only by design — this is permanent, not temporary
- Creator auth: `CreatorUploadService` wraps Supabase auth (magic links) + Storage uploads + DB inserts; instantiated per-screen from `Supabase.instance.client` directly, not injected via providers

## Conventions
- One model per file in `models/`; pure data classes with copyWith and no Flutter imports
- Shared widgets in `widgets/common/` — all take data via constructor, none read providers
- Screen-specific sub-widgets use underscore-prefixed private classes within screen files only when trivially small
- Web-specific screens live in `screens/web/`
- Credits notice and store text appear on every track/album/EP detail via `CreditsNotice` widget

## Key Patterns & Gotchas
- Mobile routes redirect to `/web` on kIsWeb — if testing mobile UI in browser, bypass by navigating directly to `/`
- PlayerProvider Timer ticks every second to simulate playback progress; dispose cancels it
- Album art URLs use picsum.photos with seed-based paths for deterministic placeholder images
- AI creator badge (auto_awesome icon + secondary color) appears on artist cards, track tiles, and detail pages
- Featured Artists sorted by `featuredScore` = 60% playCount + 40% uploadCount (normalized); score lives on `Artist` model
- CartProvider is app-global (in main.dart); web store reads it directly — never used on mobile routes
- License types: Personal / Commercial / Sync — pricing multipliers are 2×, 8×, 20× base track price (placeholders until real payment gateway)
- PreviewTrimmer widget is web-only (creator dashboard); uses a draggable fraction-based window over a fake waveform bar

## Design System
- Dark futuristic aesthetic: near-black surfaces (#0D0D0F) with purple-to-cyan gradient accents
- Inter font throughout for clean readability; bold weights for hierarchy
- All colors in ThemeData + AppColorsExtension; gradient1 (purple) and gradient2 (cyan) are the brand signature
- 8px spacing grid with 12/16/24/32px standard increments; 12px radius for cards, 20px for pills/chips
- Now-playing screen uses TabController (Player / Lyrics tabs); lyrics show centered with 2.0 line height
