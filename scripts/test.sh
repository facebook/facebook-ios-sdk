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
    BasicKit)    echo "FBSDKCoreKit_Basics" ;;
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

DESTINATION="platform=iOS Simulator,name=iPhone 16"
WORKSPACE="FacebookSDK.xcworkspace"

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
