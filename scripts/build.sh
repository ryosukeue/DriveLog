#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

xcodebuild \
  -project DriveLog/DriveLog.xcodeproj \
  -scheme DriveLog \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
