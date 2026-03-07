# Friend Tracker — Business Rules

> Authoritative source for all business logic decisions.
> Last updated: 2026-03-07

---

## BR-01: Location Sharing is Always Mutual

Both users must agree before either can see the other's location.
A location sharing request must be **accepted** by the recipient.
Sharing cannot be one-way.

## BR-02: Either User Can Stop Tracking Unilaterally

Once tracking is established, either user can stop tracking the other at any time
without notifying the other party. Stopping is immediate and unilateral.

## BR-03: Location Requests Can Be Declined

A recipient may decline a location sharing request.
The sender is NOT notified of the decline (to preserve recipient privacy).
A declined request is soft-deleted (status set to `declined`).

## BR-04: Users Are Found by Share Code OR Email/Username

To initiate a location request, a user can find another by:
- Entering their exact 12-character alphanumeric share code, OR
- Entering their registered email address or display name

## BR-05: Shared Tracking Groups Have a Maximum of 12 Members

A group cannot exceed 12 members including the creator.
Attempting to add a 13th member is rejected with a clear error.

## BR-06: Only the Group Creator Can Add or Remove Members

Group membership is managed exclusively by the user who created the group.
Other members cannot invite or remove anyone.

## BR-07: Groups Have a Mandatory End Date

Every group must have an end date set at creation time.
End dates cannot be set in the past.
The end date can be updated by the creator only.

## BR-08: 24-Hour Expiry Warning

All group members receive an in-app notification/prompt 24 hours before
the group's end date. The warning is shown once per group per member.

## BR-09: Groups Are Automatically Removed After End Date

When a group's end date passes, the group document is deleted from Firestore.
Expiry is checked on app foreground resume via workmanager.
Client-side expiry check is acceptable (no Cloud Functions required).

## BR-10: Group Tracking is All-or-Nothing per Member

Activating a group starts tracking ALL members of that group.
Deactivating a group stops tracking ALL members of that group.
Individual member tracking within a group cannot be toggled independently.

## BR-11: User Icons Are Chosen from Font Awesome

Each user selects one icon from Font Awesome (via font_awesome_flutter).
The icon is displayed on map markers and user chips for all other users.
If no icon is chosen, a default icon (map pin) is shown.
Icons are stored as icon name strings in `users/{uid}.iconName`.

## BR-12: Dashboard Is Admin-Only

The live usage dashboard is visible only to the app owner.
Access is gated by matching the signed-in UID to a hardcoded admin UID.
No end user ever sees the dashboard screen or navigation item.

## BR-13: Groups Are Stored in a Top-Level Firestore Collection

Shared tracking groups are stored in `groups/{groupId}` (top-level),
NOT in `users/{uid}/groups/{groupId}` (subcollection).
This allows all members to read the group data.
Legacy subcollection groups are migrated on first load.

## BR-14: Connections (Accepted Mutual Tracking) Are Persisted

Accepted location sharing pairs are stored in `connections/{id}` with:
- `uid1`, `uid2`: the two user IDs (uid1 < uid2 alphabetically)
- `status`: `active` or `stopped`
- `initiatorUid`: who sent the original request
- `createdAt`: timestamp

On app start, the user's active connections are loaded and those UIDs
are added to the tracked set automatically.

## BR-15: Minimum 3 Users Shown in Map Tests

All map widget tests must simulate and display at least 3 distinct
user locations simultaneously on the map to verify multi-user rendering.

## BR-16: UI Tests Rotate Across 3 Android VMs

Integration/UI tests are run on:
1. Pixel 4 emulator — API 30 (Android 11)
2. Pixel 6 emulator — API 33 (Android 13)
3. Pixel 7 emulator — API 34 (Android 14)

## BR-17: Commits Only After All Tests Pass

No code is committed until `flutter analyze` reports zero issues
AND all unit/widget tests pass. Test failures are fixed before committing.

## BR-18: Never Write to Legacy locations/{uid} Collection

All location data is written to `users/{uid}` only.
The `locations/{uid}` collection is legacy and must not receive new writes.

## BR-19: Color and Font Conventions

- All colors use `GTrackerColors` constants — no hardcoded hex in widget code
- Destructive actions: `GTrackerColors.error` (#E53935)
- Primary CTAs: `GTrackerColors.orange` (#FF9B00)
- Headings: `GoogleFonts.oswald`, FontWeight.w700
- Body: `GoogleFonts.roboto`
- Codes / monospace: `GoogleFonts.robotoMono`, letterSpacing: 2

## BR-20: Provider Conventions

- All providers live in `lib/presentation/providers/`
- Hand-written providers only — no @riverpod code-gen annotation
- ConsumerStatefulWidget for screens with local state + providers
- ConsumerWidget for stateless sub-widgets that only read providers
