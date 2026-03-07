#!/usr/bin/env bash
# paste.sh — Paste Mac clipboard text into a focused emulator text field.
#
# Usage:
#   bash scripts/paste.sh                  # pastes into both emulators
#   bash scripts/paste.sh emulator-5554    # pastes into one specific emulator
#   bash scripts/paste.sh emulator-5554 "some text"  # pastes given text

set -euo pipefail

TEXT="${2:-$(pbpaste)}"

if [[ -z "$TEXT" ]]; then
  echo "Clipboard is empty." >&2; exit 1
fi

paste_to() {
  local serial="$1"
  # Push text into the Android clipboard via a broadcast, then paste
  adb -s "$serial" shell am broadcast \
    -a clipper.set -e text "$TEXT" >/dev/null 2>&1 || true

  # Type text directly into whatever field is focused (most reliable)
  # Split on special chars that adb input text chokes on
  local chunk=""
  for (( i=0; i<${#TEXT}; i++ )); do
    local c="${TEXT:$i:1}"
    case "$c" in
      '@')
        [[ -n "$chunk" ]] && { adb -s "$serial" shell input text "$chunk"; chunk=""; }
        adb -s "$serial" shell input keyevent 77 ;;
      '.')
        [[ -n "$chunk" ]] && { adb -s "$serial" shell input text "$chunk"; chunk=""; }
        adb -s "$serial" shell input keyevent 56 ;;
      '!')
        [[ -n "$chunk" ]] && { adb -s "$serial" shell input text "$chunk"; chunk=""; }
        adb -s "$serial" shell input text '!' ;;
      '-')
        [[ -n "$chunk" ]] && { adb -s "$serial" shell input text "$chunk"; chunk=""; }
        adb -s "$serial" shell input text '-' ;;
      *)
        chunk+="$c" ;;
    esac
  done
  [[ -n "$chunk" ]] && adb -s "$serial" shell input text "$chunk"
  echo "  ${serial}: pasted \"${TEXT}\""
}

if [[ $# -ge 1 && "$1" != emulator-* ]] || [[ $# -eq 0 ]]; then
  # No specific serial — paste into all connected emulators
  while IFS= read -r serial; do
    paste_to "$serial"
  done < <(adb devices | awk '/emulator.*device$/{print $1}')
else
  paste_to "$1"
fi
