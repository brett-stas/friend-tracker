# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Analyze (lint)
flutter analyze

# Run all unit/widget tests
flutter test

# Run a single test file
flutter test test/unit/services/location_service_test.dart

# Run integration tests (requires a connected device/emulator)
flutter test integration_test/app_test.dart

# Regenerate Riverpod/Mockito code
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

**State management:** Riverpod (`flutter_riverpod` + `riverpod_annotation`). All providers live in `lib/presentation/providers/`. Hand-written providers (no `@riverpod` annotation) are used throughout.

**Auth flow:** `main.dart` watches `authStateProvider` (a `StreamProvider<User?>` wrapping Firebase Auth). Authenticated users land on `TrackingScreen`; unauthenticated users see `LoginScreen`.

**Firestore data model:**
- `users/{uid}` — profile + live location (lat/lng written on every position update) + 12-char `shareCode`
- `locations/{uid}` — sharing toggle + location (legacy; `TrackingScreen` now writes directly to `users/{uid}`)
- `friendRequests/{id}` — pending/accepted friend requests with `fromUserId`/`toUserId`

**Friend tracking (core feature):** Users share a 12-char alphanumeric code. Entering a friend's code resolves their UID via `FirestoreService.findUidByShareCode`, adds it to `trackedUidsProvider` (in-memory `StateProvider<Set<String>>`), and then `trackedUserProvider(uid)` streams that friend's `users/{uid}` doc in real time. Tracked users are not persisted across sessions.

**Location pipeline:**
1. `myLocationProvider` (StreamProvider) — requests permission then streams `Position` via `LocationService`
2. `TrackingScreen` listens to location changes and writes them to `users/{uid}` via `FirestoreService.updateLocationInProfile`
3. `trackedUserProvider` streams each friend's profile doc (which contains their latest lat/lng)

**Theming:** Garmin-inspired dark theme defined in `lib/config/theme.dart`. Use `GarminColors` constants for all colors. Primary accent is `GarminColors.orange` (`#FF9B00`). Headings use Oswald font; body uses Roboto; monospace fields use Roboto Mono.

**Test layout:**
- `test/unit/` — unit tests with Mockito mocks (regenerate with `build_runner`)
- `test/widget/` — widget tests
- `test/integration/` — integration test duplicates (also in `integration_test/`)
- `integration_test/` — on-device integration tests

**Code generation:** `location_repository_test.mocks.dart` and `location_service_test.mocks.dart` are generated files — do not edit manually; run `build_runner` after changing annotated classes.
