#!/usr/bin/env bash
# AVD: Pixel 4 — API 30 (Android 11)
# BR-16: UI tests rotate across 3 Android VMs

set -euo pipefail

AVD_NAME="Pixel4_API30"
API_LEVEL=30
ABI="x86"
DEVICE="pixel_4"
SYSTEM_IMAGE="system-images;android-${API_LEVEL};google_apis;${ABI}"

# Install system image if needed (requires sdkmanager via brew)
if ! sdkmanager --list_installed 2>/dev/null | grep -q "${SYSTEM_IMAGE}"; then
  echo "Installing system image: ${SYSTEM_IMAGE}"
  sdkmanager "${SYSTEM_IMAGE}"
fi

# Create AVD if it doesn't exist
if ! avdmanager list avd 2>/dev/null | grep -q "Name: ${AVD_NAME}"; then
  echo "Creating AVD: ${AVD_NAME}"
  echo "no" | avdmanager create avd \
    --name "${AVD_NAME}" \
    --package "${SYSTEM_IMAGE}" \
    --device "${DEVICE}" \
    --force
fi

echo "AVD ${AVD_NAME} is ready."
