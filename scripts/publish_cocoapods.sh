#!/bin/sh
# Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Developer Principles and Policies
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

set -e # immediately exit if any command has a non-zero exit status
set -u # flag undefined variables as errors
set -o pipefail # propogate errors in pipeline to be the result of the pipeline
set -x # echo commands run

push_specs_and_update() {
  for spec in "$@"; do
    pod trunk push --allow-warnings "$spec".podspec || { echo "Failed to push $spec"; exit 1; }
  done

  rm -rf ~/Library/Caches/Cocoapods && \
  rm -rf ~/.cocoapods/repos && \
  pod repo update
}

# 1. FBSDKCoreKit_Basics
push_specs_and_update FBSDKCoreKit_Basics

# 2. FBAEMKit (dependency: FBSDKCoreKit_Basics)
push_specs_and_update FBAEMKit

# 3. FBSDKCoreKit (dependencies: FBSDKCoreKit_Basics, FBAEMKit)
push_specs_and_update FBSDKCoreKit

# 4. FBSDKLoginKit, FBSDKShareKit, LegacyGamingServices (dependencies: FBSDKCoreKit_Basics, FBSDKCoreKit)
push_specs_and_update FBSDKLoginKit FBSDKShareKit LegacyGamingServices

# 5a. FBSDKTVOSKit (dependencies: FBSDKCoreKit_Basics, FBSDKLoginKit, FBSDKShareKit)
# 5b. FacebookGamingServices (dependencies: FBSDKCoreKit_Basics, FBSDKCoreKit, LegacyGamingServices)
push_specs_and_update FBSDKTVOSKit FacebookGamingServices

# 6. FBSDKGamingServicesKit (dependencies: LegacyGamingServices, FacebookGamingServices)
push_specs_and_update FBSDKGamingServicesKit

# 7. FacebookSDK
push_specs_and_update FacebokSDK
