#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"

xcodebuild \
  test \
  -project DriveLog/DriveLog.xcodeproj \
  -scheme DriveLog \
  -destination "platform=iOS Simulator,name=${SIMULATOR_NAME},OS=latest" \
  -derivedDataPath .build/DerivedData \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
