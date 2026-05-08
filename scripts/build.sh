#!/bin/sh
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# Convenience script for building SDK modules.
#
# Usage:
#   ./scripts/build.sh              # Build all (BuildAllKits-Dynamic)
#   ./scripts/build.sh LoginKit     # Build FBSDKLoginKit-Dynamic
#   ./scripts/build.sh CoreKit      # Build FBSDKCoreKit-Dynamic
#   ./scripts/build.sh ShareKit     # Build FBSDKShareKit-Dynamic
#   ./scripts/build.sh GamingKit    # Build FBSDKGamingServicesKit-Dynamic
#   ./scripts/build.sh AEMKit       # Build FBAEMKit-Dynamic
#   ./scripts/build.sh BasicKit     # Build FBSDKCoreKit_Basics

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

WORKSPACE="FacebookSDK.xcworkspace"

# Find the first available iPhone simulator destination dynamically
DEVICE_NAME=$(xcodebuild -scheme "$SCHEME" -workspace "$WORKSPACE" -showdestinations 2>/dev/null \
  | grep 'iOS Simulator' \
  | grep -o 'name:[^,}]*' \
  | grep 'iPhone' \
  | head -1 \
  | sed 's/name://;s/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$DEVICE_NAME" ]; then
  echo "Warning: No iPhone simulator found via -showdestinations, defaulting to 'iPhone 16'" >&2
  DEVICE_NAME="iPhone 16"
fi

DESTINATION="platform=iOS Simulator,name=$DEVICE_NAME"

echo "Building scheme: $SCHEME (destination: $DEVICE_NAME)"

# Build the xcodebuild command
XCODEBUILD_CMD="xcodebuild build \
  -workspace $WORKSPACE \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination '$DESTINATION'"

# Pipe through xcpretty if available
if command -v xcpretty >/dev/null 2>&1; then
  eval "$XCODEBUILD_CMD" | xcpretty
else
  eval "$XCODEBUILD_CMD"
fi
