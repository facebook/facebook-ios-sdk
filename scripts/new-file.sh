#!/bin/sh
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# Scaffold a new Swift source file and its test stub.
#
# Usage:
#   ./scripts/new-file.sh LoginKit RefreshRateLimiter
#   ./scripts/new-file.sh LoginKit Internal/RefreshRateLimiter
#
# Creates:
#   <Module>/<Module>/<Path>.swift          (source file)
#   <Module>/<Module>Tests/<Name>Tests.swift (test file)
#
# Does NOT modify project.yml — XcodeGen globs directories automatically.
# Run ./generate-projects.sh after creating files.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <Kit> <RelativePath>" >&2
  echo "  Kit: LoginKit, CoreKit, ShareKit, GamingKit, AEMKit, BasicKit" >&2
  echo "  RelativePath: ClassName or Internal/ClassName" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0 LoginKit RefreshRateLimiter" >&2
  echo "  $0 LoginKit Internal/RefreshRateLimiter" >&2
  exit 1
fi

KIT="$1"
REL_PATH="$2"

# Map short names to module directories
map_module() {
  case "$1" in
    LoginKit)    echo "FBSDKLoginKit" ;;
    CoreKit)     echo "FBSDKCoreKit" ;;
    ShareKit)    echo "FBSDKShareKit" ;;
    GamingKit)   echo "FBSDKGamingServicesKit" ;;
    AEMKit)      echo "FBAEMKit" ;;
    BasicKit)    echo "FBSDKCoreKit_Basics" ;;
    *)
      echo "Unknown kit: $1" >&2
      echo "Available kits: LoginKit, CoreKit, ShareKit, GamingKit, AEMKit, BasicKit" >&2
      exit 1
      ;;
  esac
}

MODULE=$(map_module "$KIT")

# Extract the class name (last component of the path, without extension)
CLASS_NAME=$(basename "$REL_PATH")

# Determine if this is an internal file
IS_INTERNAL=false
if echo "$REL_PATH" | grep -q "^Internal/"; then
  IS_INTERNAL=true
fi

# Build the Swift class name (internal types get underscore prefix)
if [ "$IS_INTERNAL" = true ]; then
  SWIFT_CLASS_NAME="_${CLASS_NAME}"
else
  SWIFT_CLASS_NAME="$CLASS_NAME"
fi

# Build file paths
SOURCE_FILE="${MODULE}/${MODULE}/${REL_PATH}.swift"
TEST_FILE="${MODULE}/${MODULE}Tests/${CLASS_NAME}Tests.swift"

# Map module to import name
map_import() {
  case "$1" in
    FBSDKLoginKit)            echo "FBSDKLoginKit" ;;
    FBSDKCoreKit)             echo "FBSDKCoreKit" ;;
    FBSDKShareKit)            echo "FBSDKShareKit" ;;
    FBSDKGamingServicesKit)   echo "FBSDKGamingServicesKit" ;;
    FBAEMKit)                 echo "FBAEMKit" ;;
    FBSDKCoreKit_Basics)      echo "FBSDKCoreKit_Basics" ;;
  esac
}

IMPORT_NAME=$(map_import "$MODULE")

# Copyright header
HEADER='/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */'

# Refuse to overwrite existing files
if [ -f "$SOURCE_FILE" ]; then
  echo "Error: $SOURCE_FILE already exists. Refusing to overwrite." >&2
  exit 1
fi

if [ -f "$TEST_FILE" ]; then
  echo "Error: $TEST_FILE already exists. Refusing to overwrite." >&2
  exit 1
fi

# Create directories if needed
mkdir -p "$(dirname "$SOURCE_FILE")"
mkdir -p "$(dirname "$TEST_FILE")"

# Write source file
cat > "$SOURCE_FILE" << EOF
$HEADER

import Foundation

final class $SWIFT_CLASS_NAME {}
EOF

# Write test file
cat > "$TEST_FILE" << EOF
$HEADER

@testable import $IMPORT_NAME
import XCTest

final class ${CLASS_NAME}Tests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
  }
}
EOF

echo "Created: $SOURCE_FILE"
echo "Created: $TEST_FILE"
echo ""
echo "Run ./generate-projects.sh to update Xcode project files."
