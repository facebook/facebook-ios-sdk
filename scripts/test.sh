#!/bin/sh
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# Convenience script for running SDK tests.
#
# Usage:
#   ./scripts/test.sh              # Run all tests (BuildAllKits-Dynamic)
#   ./scripts/test.sh LoginKit     # Run FBSDKLoginKit-Dynamic tests
#   ./scripts/test.sh CoreKit      # Run FBSDKCoreKit-Dynamic tests
#   ./scripts/test.sh ShareKit     # Run FBSDKShareKit-Dynamic tests
#   ./scripts/test.sh GamingKit    # Run FBSDKGamingServicesKit-Dynamic tests
#   ./scripts/test.sh AEMKit       # Run FBAEMKit-Dynamic tests
#   ./scripts/test.sh BasicKit     # Run FBSDKCoreKit_Basics tests

set -euo pipefail

# Map short names to xcodebuild scheme names
map_scheme() {
  case "$1" in
    LoginKit)    echo "FBSDKLoginKit-Dynamic" ;;
    CoreKit)     echo "FBSDKCoreKit-Dynamic" ;;
    ShareKit)    echo "FBSDKShareKit-Dynamic" ;;
    GamingKit)   echo "FBSDKGamingServicesKit-Dynamic" ;;
    AEMKit)      echo "FBAEMKit-Dynamic" ;;
    BasicKit)    echo "FBSDKCoreKit_Basics-Dynamic" ;;
    *)
      echo "Unknown kit: $1" >&2
      echo "Available kits: LoginKit, CoreKit, ShareKit, GamingKit, AEMKit, BasicKit" >&2
      exit 1
      ;;
  esac
}

# Determine scheme
if [ $# -eq 0 ]; then
  SCHEME="BuildAllKits-Dynamic"
else
  SCHEME=$(map_scheme "$1")
fi

WORKSPACE="FacebookSDK.xcworkspace"

# Find an available iPhone simulator destination dynamically, taking the newest runtime.
# The OS must be carried through with the name: a destination that names a device but omits the
# OS resolves against the latest installed runtime, and a device from an older runtime does not
# exist there (an "iPhone 15" picked off an iOS 17 runtime fails on an Xcode whose latest is
# iOS 26). Sorting by OS descending also keeps this on the newest runtime as Xcode versions change.
DESTINATION_SPEC=$(xcodebuild -scheme "$SCHEME" -workspace "$WORKSPACE" -showdestinations 2>/dev/null \
  | grep 'platform:iOS Simulator' \
  | grep 'name:iPhone' \
  | sed -n 's/.*OS:\([0-9][0-9.]*\).*name:\(.*\) }.*/\1|\2/p' \
  | sort -t'|' -k1,1 -Vr \
  | head -1 || true)

# `|| true` above so that a scheme with no matching destination reaches this check rather than
# aborting the pipeline under `set -e`, which exits silently with no output at all.
if [ -z "$DESTINATION_SPEC" ]; then
  echo "Error: no iPhone simulator destination found for scheme '$SCHEME'." >&2
  echo "Check the scheme exists: xcodebuild -workspace $WORKSPACE -list" >&2
  exit 1
fi

DEVICE_OS=${DESTINATION_SPEC%%|*}
DEVICE_NAME=${DESTINATION_SPEC#*|}

DESTINATION="platform=iOS Simulator,name=$DEVICE_NAME,OS=$DEVICE_OS"

echo "Running tests for scheme: $SCHEME"

# Build the xcodebuild command
XCODEBUILD_CMD="xcodebuild test \
  -workspace $WORKSPACE \
  -scheme $SCHEME \
  -configuration Debug \
  -destination '$DESTINATION'"

# Pipe through xcpretty if available
if command -v xcpretty >/dev/null 2>&1; then
  eval "$XCODEBUILD_CMD" | xcpretty
else
  eval "$XCODEBUILD_CMD"
fi
