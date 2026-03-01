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
- `users/{uid}` — profile + live location (lat/lng written on every position update) + 12-char `shareCode` + `nicknames` map
- `users/{uid}/groups/{groupId}` — group subcollection: `id`, `name`, `memberUids[]`, `createdAt`
- `locations/{uid}` — sharing toggle + location (legacy; `TrackingScreen` now writes directly to `users/{uid}`)
- `friendRequests/{id}` — pending/accepted friend requests with `fromUserId`/`toUserId`

**Friend tracking (core feature):** Users share a 12-char alphanumeric code. Entering a friend's code resolves their UID via `FirestoreService.findUidByShareCode`, adds it to `trackedUidsProvider` (in-memory `StateProvider<Set<String>>`), and then `trackedUserProvider(uid)` streams that friend's `users/{uid}` doc in real time. Tracked users are not persisted across sessions.

**Nicknames:** Stored in `users/{myUid}.nicknames` as a map `{ friendUid: nickname }`. Read via `nicknamesProvider` (StreamProvider). Written with `FirestoreService.setNickname` / `removeNickname`. Nicknames replace display names in chips and map marker info windows.

**Groups:** Stored in `users/{myUid}/groups` subcollection. Read via `groupsProvider` (StreamProvider). Bulk start/stop via `groupTrackingNotifier` (NotifierProvider). Groups persist across sessions; tracked UIDs do not.

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

---

## Application Rules

### UX / Interaction
- **Stop-tracking icon** — every tracked-user chip shows a `Icons.location_off` delete icon (red). Tapping it immediately stops tracking that user. This is the primary stop-tracking affordance.
- **Marker tap** — tapping a friend's map marker opens a bottom sheet (`_MarkerOptionsSheet`) with: display name, current nickname, "Edit Nickname" action, and "Stop Tracking" action.
- **Nickname display** — wherever a tracked user's name appears (chip label, map marker `InfoWindow` title), show their nickname if set, otherwise fall back to `displayName` from Firestore.
- **Groups** — a group's play/stop icon toggles tracking for all members at once. The icon is orange (play) when any member is untracked, red (stop) when all members are tracked.
- **New Group dialog** — only currently-tracked users appear as member candidates (multi-select checkboxes).

### Firestore / Data
- Never write to `locations/{uid}` for new features — that collection is legacy. Write location data to `users/{uid}` only.
- Nicknames are stored as a nested map field (`nicknames.{friendUid}`) inside the user's own doc — not in a subcollection and not in the friend's doc.
- Group membership is stored as a plain `string[]` of UIDs. No denormalisation.
- Always use `SetOptions(merge: true)` when writing partial updates to `users/{uid}` to avoid overwriting unrelated fields.

### Theming
- Use `GarminColors` constants exclusively — never hardcode colour hex values in widget code.
- Headings/labels: `GoogleFonts.oswald`, `fontWeight: FontWeight.w700`.
- Body text: `GoogleFonts.roboto`.
- Monospace (share codes, codes): `GoogleFonts.robotoMono`, `letterSpacing: 2`.
- Destructive actions (stop tracking, delete): `GarminColors.error` (`#E53935`).
- Primary accent / CTAs: `GarminColors.orange` (`#FF9B00`).

### Code conventions
- All providers live in `lib/presentation/providers/`. Do not define providers inside widget files.
- Hand-written providers only (no `@riverpod` code-gen annotation).
- `ConsumerStatefulWidget` for screens that need both local state and providers; `ConsumerWidget` for stateless sub-widgets that only read providers.
- After any change to annotated classes or mocks, run `dart run build_runner build --delete-conflicting-outputs`.
- Run `flutter analyze` before committing. Zero issues required.
