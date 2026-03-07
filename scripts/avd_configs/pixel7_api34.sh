#!/usr/bin/env bash
# AVD: Pixel 7 — API 34 (Android 14)
# BR-16: UI tests rotate across 3 Android VMs

set -euo pipefail

AVD_NAME="Pixel7_API34"
API_LEVEL=34
ABI="x86_64"
DEVICE="pixel_7"
SYSTEM_IMAGE="system-images;android-${API_LEVEL};google_apis;${ABI}"

if ! sdkmanager --list_installed 2>/dev/null | grep -q "${SYSTEM_IMAGE}"; then
  echo "Installing system image: ${SYSTEM_IMAGE}"
  sdkmanager "${SYSTEM_IMAGE}"
fi

if ! avdmanager list avd 2>/dev/null | grep -q "Name: ${AVD_NAME}"; then
  echo "Creating AVD: ${AVD_NAME}"
  echo "no" | avdmanager create avd \
    --name "${AVD_NAME}" \
    --package "${SYSTEM_IMAGE}" \
    --device "${DEVICE}" \
    --force
fi

echo "AVD ${AVD_NAME} is ready."
