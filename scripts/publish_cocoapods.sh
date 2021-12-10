#!/bin/sh
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

set -e # immediately exit if any command has a non-zero exit status
set -u # flag undefined variables as errors
set -o pipefail # propogate errors in pipeline to be the result of the pipeline
# set -x # echo commands run (commented out for now since its noisy)

CURRENT_VERSION=$(grep -Eo 'FBSDK_VERSION_STRING @".*"' FBSDKCoreKit/FBSDKCoreKit/include/FBSDKCoreKitVersions.h | awk -F'"' '{print $2}')

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

# 5a. FBSDKTVOSKit (dependencies: FBSDKCoreKit_Basics, FBSDKLoginKit, FBSDKShareKit)
# 5b. FacebookGamingServices (dependencies: FBSDKCoreKit_Basics, FBSDKCoreKit)
push_specs_and_update FBSDKTVOSKit FacebookGamingServices

# 6. FBSDKGamingServicesKit (dependencies: FacebookGamingServices)
push_specs_and_update FBSDKGamingServicesKit
