#!/usr/bin/env bash
# Runs integration/UI tests across 3 Android VM configurations.
# BR-16: Pixel 4 API 30, Pixel 6 API 33, Pixel 7 API 34
#
# Prerequisites (installed via Homebrew):
#   brew install --cask android-commandlinetools
#   Add $ANDROID_HOME/cmdline-tools/latest/bin to PATH
#
# Usage:
#   bash scripts/run_ui_tests.sh [--setup-avds]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

AVDS=(
  "Pixel4_API30"
  "Pixel6_API33"
  "Pixel7_API34"
)

AVD_SCRIPTS=(
  "${SCRIPT_DIR}/avd_configs/pixel4_api30.sh"
  "${SCRIPT_DIR}/avd_configs/pixel6_api33.sh"
  "${SCRIPT_DIR}/avd_configs/pixel7_api34.sh"
)

PASS=0
FAIL=0
RESULTS=()

# ── Optional: create AVDs ─────────────────────────────────────────────────────
if [[ "${1:-}" == "--setup-avds" ]]; then
  echo "=== Setting up AVDs ==="
  for script in "${AVD_SCRIPTS[@]}"; do
    bash "${script}"
  done
fi

# ── Run tests on each AVD ─────────────────────────────────────────────────────
for i in "${!AVDS[@]}"; do
  avd="${AVDS[$i]}"
  echo ""
  echo "=== Running tests on ${avd} ==="

  # Start emulator in background
  emulator -avd "${avd}" -no-window -no-audio -gpu swiftshader_indirect &
  EMULATOR_PID=$!

  # Wait for emulator to boot
  echo "Waiting for ${avd} to boot..."
  adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done'
  sleep 5

  # Get device serial
  SERIAL=$(adb devices | grep emulator | head -1 | awk '{print $1}')

  # Run integration tests
  cd "${PROJECT_DIR}"
  if flutter test integration_test/app_test.dart -d "${SERIAL}" 2>&1; then
    PASS=$((PASS + 1))
    RESULTS+=("PASS: ${avd}")
    echo "PASS: ${avd}"
  else
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL: ${avd}")
    echo "FAIL: ${avd}"
  fi

  # Kill emulator
  kill "${EMULATOR_PID}" 2>/dev/null || true
  adb -s "${SERIAL}" emu kill 2>/dev/null || true
  sleep 3
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== UI Test Summary ==="
for result in "${RESULTS[@]}"; do
  echo "  ${result}"
done
echo ""
echo "Passed: ${PASS} / ${#AVDS[@]}"
echo "Failed: ${FAIL} / ${#AVDS[@]}"

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
