#!/usr/bin/env bash
# start_demo.sh — Starts 2 Android emulators side-by-side, installs Friend Tracker,
# sets random Australian country-town GPS locations, and logs both users in.
#
# Usage:
#   bash scripts/start_demo.sh [--build]
#
# Flags:
#   --build   Rebuild the debug APK before installing (default: reuse existing build)
#
# Prerequisites:
#   brew install --cask android-commandlinetools
#   ANDROID_HOME set, emulator/adb/aapt on PATH
#   An AVD named FriendTracker_Pixel8 must exist (or edit AVD_NAME below)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
APK="${PROJECT_DIR}/build/app/outputs/flutter-apk/app-debug.apk"
AVD_NAME="FriendTracker_Pixel8"
PACKAGE="com.friendtracker.friend_tracker"
MAIN_ACTIVITY="${PACKAGE}/.MainActivity"

# ── Test accounts ─────────────────────────────────────────────────────────────
ALPHA_EMAIL="useralpha@friendtracker.test"
BETA_EMAIL="userbeta@friendtracker.test"
PASSWORD="Test1234!"

# ── Australian country towns (VIC/NSW) ────────────────────────────────────────
# Format: "name:lat:lng"
AU_TOWNS=(
  "Bendigo VIC:-36.7570:144.2794"
  "Wagga Wagga NSW:-35.1082:147.3598"
  "Ballarat VIC:-37.5622:143.8503"
  "Orange NSW:-33.2839:149.1003"
  "Shepparton VIC:-36.3833:145.4000"
  "Tamworth NSW:-31.0927:150.9320"
  "Warrnambool VIC:-38.3833:142.4833"
  "Albury NSW:-36.0737:146.9135"
  "Mildura VIC:-34.2086:142.1312"
  "Armidale NSW:-30.5128:151.6671"
  "Swan Hill VIC:-35.3369:143.5539"
  "Dubbo NSW:-32.2500:148.6011"
  "Horsham VIC:-36.7099:142.1999"
  "Coffs Harbour NSW:-30.2963:153.1135"
  "Wangaratta VIC:-36.3580:146.3122"
  "Grafton NSW:-29.6902:152.9327"
  "Sale VIC:-38.1067:147.0669"
  "Broken Hill NSW:-31.9505:141.4534"
  "Wodonga VIC:-36.1221:146.8884"
  "Lismore NSW:-28.8150:153.2791"
)

# Pick two distinct random towns
pick_random_towns() {
  local total=${#AU_TOWNS[@]}
  local idx1=$(( RANDOM % total ))
  local idx2=$(( (idx1 + 1 + RANDOM % (total - 1)) % total ))
  TOWN1="${AU_TOWNS[$idx1]}"
  TOWN2="${AU_TOWNS[$idx2]}"
}

# ── Helper: type text into focused field via adb (autocomplete-safe) ──────────
# Sends each character individually to bypass IME domain autocomplete.
adb_type() {
  local serial="$1"
  local text="$2"
  # Android IME autocomplete can swallow text after '@' or truncate long strings.
  # Strategy: split at special chars, send each segment separately with 0.4s pauses;
  # use keyevent for '@', '.', and '!' to bypass IME interception.
  local chunk=""
  for (( i=0; i<${#text}; i++ )); do
    local c="${text:$i:1}"
    case "$c" in
      '@')
        if [[ -n "$chunk" ]]; then
          adb -s "$serial" shell input text "$chunk"
          chunk=""
          sleep 0.4
        fi
        adb -s "$serial" shell input keyevent 77  # KEYCODE_AT
        sleep 0.2
        ;;
      '.')
        if [[ -n "$chunk" ]]; then
          adb -s "$serial" shell input text "$chunk"
          chunk=""
          sleep 0.4
        fi
        adb -s "$serial" shell input keyevent 56  # KEYCODE_PERIOD
        sleep 0.2
        ;;
      '!')
        if [[ -n "$chunk" ]]; then
          adb -s "$serial" shell input text "$chunk"
          chunk=""
          sleep 0.4
        fi
        adb -s "$serial" shell input text '!'
        sleep 0.2
        ;;
      *)
        chunk+="$c"
        # Flush every 6 chars to avoid autocomplete truncation
        if [[ ${#chunk} -ge 6 ]]; then
          adb -s "$serial" shell input text "$chunk"
          chunk=""
          sleep 0.4
        fi
        ;;
    esac
  done
  if [[ -n "$chunk" ]]; then
    adb -s "$serial" shell input text "$chunk"
  fi
}

# ── Helper: clear a text field (focus it first, then select-all + delete) ─────
adb_clear_field() {
  local serial="$1"
  local x="$2"
  local y="$3"
  adb -s "$serial" shell input tap "$x" "$y"
  sleep 0.3
  adb -s "$serial" shell input keyevent 123   # MOVE_END
  sleep 0.1
  # Send 80 backspaces to wipe the field
  for _ in $(seq 1 80); do
    adb -s "$serial" shell input keyevent 67  # BACKSPACE
  done
}

# ── Helper: wait for emulator to appear in adb devices ───────────────────────
wait_for_serial() {
  local serial="$1"
  echo "  Waiting for ${serial} to come online..."
  for attempt in $(seq 1 60); do
    if adb devices | grep -q "^${serial}	device$"; then
      echo "  ${serial} is online."
      return 0
    fi
    sleep 2
  done
  echo "  ERROR: ${serial} did not come online after 120s." >&2
  return 1
}

# ── Helper: wait for Android boot to complete ────────────────────────────────
wait_for_boot() {
  local serial="$1"
  echo "  Waiting for ${serial} to finish booting..."
  for attempt in $(seq 1 60); do
    local val
    val=$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [[ "$val" == "1" ]]; then
      echo "  ${serial} booted."
      return 0
    fi
    sleep 3
  done
  echo "  ERROR: ${serial} did not boot in 180s." >&2
  return 1
}

# ── Helper: login a user ─────────────────────────────────────────────────────
login_user() {
  local serial="$1"
  local email="$2"
  local label="$3"

  echo "  [${label}] Launching app..."
  adb -s "$serial" shell am start -n "${MAIN_ACTIVITY}" >/dev/null 2>&1
  sleep 3

  echo "  [${label}] Waiting for login screen..."
  for attempt in $(seq 1 15); do
    if adb -s "$serial" shell uiautomator dump /sdcard/ui_check.xml >/dev/null 2>&1 && \
       adb -s "$serial" shell cat /sdcard/ui_check.xml 2>/dev/null | grep -q 'ENGAGE'; then
      break
    fi
    sleep 2
  done

  echo "  [${label}] Filling email: ${email}"
  # Clear and fill email field (bounds: [63,801][1017,948], center y=875)
  adb_clear_field "$serial" 540 875
  adb -s "$serial" shell input tap 540 875
  sleep 0.3
  adb_type "$serial" "$email"
  sleep 0.3

  echo "  [${label}] Filling password..."
  # Clear and fill password field (bounds: [63,990][1017,1137], center y=1063)
  adb_clear_field "$serial" 540 1063
  adb -s "$serial" shell input tap 540 1063
  sleep 0.3
  adb_type "$serial" "$PASSWORD"
  sleep 0.3

  # Get ENGAGE button position dynamically
  adb -s "$serial" shell uiautomator dump /sdcard/ui_engage.xml >/dev/null 2>&1
  local engage_y
  engage_y=$(adb -s "$serial" shell cat /sdcard/ui_engage.xml 2>/dev/null | \
    python3 -c "
import sys, re
xml = sys.stdin.read()
for n in re.findall(r'<node[^>]+>', xml):
    cd = re.search(r'content-desc=\"([^\"]+)\"', n)
    bounds = re.search(r'bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"', n)
    if cd and cd.group(1) == 'ENGAGE' and bounds:
        y = (int(bounds.group(2)) + int(bounds.group(4))) // 2
        print(y)
" 2>/dev/null || echo "1263")
  engage_y="${engage_y:-1263}"

  echo "  [${label}] Tapping ENGAGE at y=${engage_y}..."
  adb -s "$serial" shell input tap 540 "$engage_y"
  sleep 5

  # Grant location permission if dialog appears
  adb -s "$serial" shell uiautomator dump /sdcard/ui_perm.xml >/dev/null 2>&1
  if adb -s "$serial" shell cat /sdcard/ui_perm.xml 2>/dev/null | grep -q 'While using'; then
    echo "  [${label}] Granting location permission..."
    local perm_y
    perm_y=$(adb -s "$serial" shell cat /sdcard/ui_perm.xml 2>/dev/null | \
      python3 -c "
import sys, re
xml = sys.stdin.read()
# Find 'While using the app' button bounds
idx = xml.find('While using')
if idx < 0:
    print(1474)
else:
    sub = xml[max(0,idx-500):idx+200]
    m = re.search(r'bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"', sub)
    print((int(m.group(2)) + int(m.group(4))) // 2 if m else 1474)
" 2>/dev/null || echo "1474")
    adb -s "$serial" shell input tap 540 "${perm_y:-1474}"
    sleep 3
  fi

  echo "  [${label}] Login complete."
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Friend Tracker — Demo Launcher       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Step 1: Pick random Australian towns ──────────────────────────────────────
pick_random_towns
TOWN1_NAME=$(echo "$TOWN1" | cut -d: -f1)
TOWN1_LAT=$(echo "$TOWN1" | cut -d: -f2)
TOWN1_LNG=$(echo "$TOWN1" | cut -d: -f3)
TOWN2_NAME=$(echo "$TOWN2" | cut -d: -f1)
TOWN2_LAT=$(echo "$TOWN2" | cut -d: -f2)
TOWN2_LNG=$(echo "$TOWN2" | cut -d: -f3)

echo "Alpha location: ${TOWN1_NAME} (${TOWN1_LAT}, ${TOWN1_LNG})"
echo "Beta  location: ${TOWN2_NAME} (${TOWN2_LAT}, ${TOWN2_LNG})"
echo ""

# ── Step 2: Kill existing emulators on our ports ──────────────────────────────
echo "=== Stopping any existing emulators ==="
adb -s emulator-5554 emu kill 2>/dev/null || true
adb -s emulator-5556 emu kill 2>/dev/null || true
sleep 3

# ── Step 3: Start two emulator instances ──────────────────────────────────────
echo ""
echo "=== Starting emulators ==="
emulator -avd "${AVD_NAME}" -read-only -port 5554 \
  -no-window -no-audio -gpu swiftshader_indirect \
  -wipe-data 2>/dev/null &
EMU1_PID=$!

emulator -avd "${AVD_NAME}" -read-only -port 5556 \
  -no-window -no-audio -gpu swiftshader_indirect \
  -wipe-data 2>/dev/null &
EMU2_PID=$!

echo "  emulator-5554 PID=${EMU1_PID}"
echo "  emulator-5556 PID=${EMU2_PID}"

# ── Step 4: Wait for both to boot ────────────────────────────────────────────
wait_for_serial "emulator-5554"
wait_for_serial "emulator-5556"
wait_for_boot   "emulator-5554"
wait_for_boot   "emulator-5556"
sleep 5  # extra settle time

# ── Step 5: Build APK if requested ───────────────────────────────────────────
if [[ "${1:-}" == "--build" ]]; then
  echo ""
  echo "=== Building debug APK ==="
  cd "${PROJECT_DIR}"
  flutter build apk --debug
fi

# ── Step 6: Install APK on both ──────────────────────────────────────────────
echo ""
echo "=== Installing APK ==="
adb -s emulator-5554 install -r "${APK}" &
adb -s emulator-5556 install -r "${APK}" &
wait
echo "  Installed on both emulators."

# ── Step 7: Set GPS locations ────────────────────────────────────────────────
echo ""
echo "=== Setting GPS locations ==="
adb -s emulator-5554 emu geo fix "${TOWN1_LNG}" "${TOWN1_LAT}"
adb -s emulator-5556 emu geo fix "${TOWN2_LNG}" "${TOWN2_LAT}"
echo "  5554 → ${TOWN1_NAME}"
echo "  5556 → ${TOWN2_NAME}"

# ── Step 8: Login both users ─────────────────────────────────────────────────
echo ""
echo "=== Logging in users ==="
login_user "emulator-5554" "${ALPHA_EMAIL}" "Alpha"
login_user "emulator-5556" "${BETA_EMAIL}"  "Beta"

# ── Step 9: Show final screenshots ───────────────────────────────────────────
echo ""
echo "=== Screenshots saved ==="
adb -s emulator-5554 shell screencap -p /sdcard/demo_alpha.png
adb -s emulator-5554 pull /sdcard/demo_alpha.png /tmp/demo_alpha.png 2>/dev/null
adb -s emulator-5556 shell screencap -p /sdcard/demo_beta.png
adb -s emulator-5556 pull /sdcard/demo_beta.png /tmp/demo_beta.png 2>/dev/null
echo "  /tmp/demo_alpha.png"
echo "  /tmp/demo_beta.png"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Both users online. Share codes visible. ║"
echo "║  Exchange codes to start tracking!       ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Alpha (emulator-5554): ${ALPHA_EMAIL}"
echo "Beta  (emulator-5556): ${BETA_EMAIL}"
echo ""
echo "Emulator PIDs: ${EMU1_PID} ${EMU2_PID}"
echo "To stop: kill ${EMU1_PID} ${EMU2_PID}"
