#!/bin/sh
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

set -e # immediately exit if any command has a non-zero exit status
set -u # flag undefined variables as errors
set -o pipefail # propogate errors in pipeline to be the result of the pipeline
# set -x # echo commands run (commented out for now since its noisy)

VERSION_FILE="FBSDKCoreKit_Basics/FBSDKCoreKit_Basics/include/FBSDKVersions.h"

# `|| true` so a non-match does not trip `set -o pipefail` before the check below runs.
# Without it the script exits 1 with no output at all, and the release guide invokes this
# inside `until scripts/publish_cocoapods.sh; do sleep 60; done` -- so a version that cannot
# be read looks like a transient failure and retries forever instead of saying what is wrong.
CURRENT_VERSION=$(grep -Eo 'FBSDK_VERSION_STRING @".*"' "$VERSION_FILE" 2>/dev/null | awk -F'"' '{print $2}' || true)

if [ -z "$CURRENT_VERSION" ]; then
  echo "ERROR: no FBSDK_VERSION_STRING found in $VERSION_FILE" >&2
  echo "       This is the canonical version definition; if it moved, update this script." >&2
  exit 1
fi

push_specs_and_update() {
  for spec in "$@"; do
    echo "Checking version $CURRENT_VERSION for: $spec"
    # The "|| [[ $? == 1 ]]" prevents a non-zero exit from grep to cause the script to exit (due to "set -e")
    FOUND=$(pod trunk info "$spec" | grep "$CURRENT_VERSION" || [ $? = 1 ])
    if [ -z "$FOUND" ]; then
      echo "Running: pod trunk push --allow-warnings --synchronous $spec.podspec"
      pod trunk push --allow-warnings --synchronous "$spec".podspec || { echo "Failed to push $spec"; exit 1; }
    fi
  done
}

# 1. FBSDKCoreKit_Basics
push_specs_and_update FBSDKCoreKit_Basics

# 2. FBAEMKit (dependency: FBSDKCoreKit_Basics)
push_specs_and_update FBAEMKit

# 3. FBSDKCoreKit (dependencies: FBSDKCoreKit_Basics, FBAEMKit)
push_specs_and_update FBSDKCoreKit

# 4. FBSDKLoginKit, FBSDKShareKit (dependencies: FBSDKCoreKit_Basics, FBSDKCoreKit)
push_specs_and_update FBSDKLoginKit FBSDKShareKit

# 5. FBSDKGamingServicesKit (dependencies: FBSDKCoreKit_Basics, FBSDKCoreKit)
push_specs_and_update FBSDKGamingServicesKit
