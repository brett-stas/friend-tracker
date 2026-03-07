# Friend Tracker — Product Requirements

> Saved in source control so we can build on these requirements each week.
> Last updated: 2026-03-07

---

## 1. Platform & Language

- **Flutter / Dart** (existing codebase — not a rewrite)
- Target: Android (primary), iOS (secondary)
- Minimum Android SDK: API 30 (Android 11)
- Use the latest stable Flutter SDK and all package versions

---

## 2. Location Sharing via In-App Request

### 2.1 Finding a User
- A user can search for another user by:
  - Their **12-character alphanumeric share code**, OR
  - Their **username / email address**

### 2.2 Sending a Request
- After finding a user, the initiating user sends a **location sharing request** (in-app message)
- The request is stored in Firestore: `locationRequests/{id}`
- The recipient sees the request in their **in-app inbox** with a badge count

### 2.3 Accept / Decline
- The recipient can **accept** or **decline** the request
- If **accepted**: both users immediately start tracking each other (mutual, simultaneous)
- If **declined**: no tracking occurs; the sender is not notified of the decline (privacy)

### 2.4 Stopping Sharing
- **Either user** can stop tracking the other at any time
- Stopping is unilateral — no notification sent to the other user
- Stopping only removes tracking for the user who initiated the stop

### 2.5 Multiple Simultaneous Tracking
- A user can track **multiple friends** at the same time
- All tracked friends appear on the **same map** simultaneously
- Tests must demonstrate at least **3 user locations** shown on one map

---

## 3. Shared Tracking Groups

### 3.1 Overview
- An **expansion** of the existing Groups feature (not a separate concept)
- A group allows up to **12 members** to all track each other simultaneously
- Any group member's location is visible to all other members while the group is active

### 3.2 Creation
- The **first/home screen** has a prominent **"Create Tracking Group"** button
- Only the **creator** can add members (up to 12 including themselves)
- Members are added from the user's tracked/connected friends
- Creator sets a **title** for the group
- Creator sets an **end date** (when the group will be automatically removed)

### 3.3 CRUD
- **Create**: Title, members, end date
- **Read**: List view of all groups the user belongs to
- **Update**: Creator can rename, add/remove members, change end date
- **Delete**: Creator can disband the group at any time

### 3.4 Expiry
- Groups have an **end date** set at creation
- **24 hours before** the end date, all group members receive an **in-app prompt** warning
- When the end date passes, the group is automatically removed
- Expiry check is performed on app foreground using `workmanager`

### 3.5 Sharing / Invites
- A group can only be shared (invited to) by **anyone who is already a member** — WAIT: confirmed rule is **creator only** can add members
- Group metadata (title, members, end date) is readable by all current members

### 3.6 Icons & Tracking State
- The group play/stop icon: **orange** (play) when any member is untracked; **red** (stop) when all members are tracked
- Activating a group starts tracking all members; deactivating stops tracking all members

---

## 4. User Icons

- Each user picks a **simple icon** from **Font Awesome** (external icon library via `font_awesome_flutter` package)
- The chosen icon is stored in `users/{uid}.iconName`
- All other users see this icon on:
  - Map markers (replacing the default colour pin)
  - User chips in the tracking panel
- Icon is set/changed in **Settings** or **Profile** screen

---

## 5. Admin Dashboard (Owner Only)

- **Not visible to end users**
- Accessible only when the signed-in UID matches the hardcoded **admin UID**
- Displays real-time stats via Firestore streams:
  - Total users with the app installed (users collection count)
  - Users currently sharing location (active in last 5 minutes)
  - Number of active tracking groups
  - Number of pending location requests
- Admin screen is hidden from navigation for non-admin users

---

## 6. Map Behaviour

- Map supports standard **portrait / landscape rotation** (device orientation)
- Map shows all tracked users simultaneously with distinct markers
- Each marker displays the user's chosen **Font Awesome icon** (or default if not set)
- Tapping a marker opens the existing `_MarkerOptionsSheet`

---

## 7. Testing Requirements

### 7.1 Unit & Widget Tests
- Minimum **3 simulated user locations** shown on map in widget tests
- Cover: location requests, groups CRUD, icon picker, connections, expiry notifications, dashboard stats
- Run with `flutter test`

### 7.2 UI / Integration Tests
- Rotate across **3 Android VM configurations**:
  - Pixel 4 — API 30 (Android 11)
  - Pixel 6 — API 33 (Android 13)
  - Pixel 7 — API 34 (Android 14)
- Test runner script in `scripts/run_ui_tests.sh`
- AVD config scripts in `scripts/avd_configs/`

### 7.3 CI Gate
- **Commit only after all unit/widget tests pass**
- `flutter analyze` must report zero issues before commit
- Test failures are always reported to the developer and fixed before committing

---

## 8. Tooling

- Use **Homebrew** to install or update required tools (Android SDK tools, AVD manager, etc.)
- Run `dart run build_runner build --delete-conflicting-outputs` after any model/provider change
- No prompts for minor file updates — proceed autonomously

---

## 9. Source Control

- All business rules and requirements saved in `REQUIREMENTS.md` and `BUSINESS_RULES.md`
- Both files are committed to the repository
- Updated each week as requirements evolve
