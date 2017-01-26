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

# This script sets up a consistent environment for the other scripts in this directory.

# Set up paths for a specific clone of the SDK source
if [ -z "$FB_SDK_SCRIPT" ]; then
  # ---------------------------------------------------------------------------
  # Set up paths
  #

  # The directory containing this script
  # We need to go there and use pwd so these are all absolute paths
  pushd "$(dirname $BASH_SOURCE[0])" >/dev/null
  FB_SDK_SCRIPT=$(pwd)
  popd >/dev/null

  # The root directory where the Facebook SDK for iOS is cloned
  FB_SDK_ROOT=$(dirname "$FB_SDK_SCRIPT")

  # Path to sample files for Facebook SDK
  FB_SDK_SAMPLES=$FB_SDK_ROOT/samples

  # The directory where the target is built
  FB_SDK_BUILD=$FB_SDK_ROOT/build
  FB_SDK_BUILD_LOG=$FB_SDK_BUILD/build.log

  # Extract the SDK version from FacebookSDK.h
  FB_SDK_VERSION_RAW=$(sed -n 's/.*FBSDK_VERSION_STRING @\"\(.*\)\"/\1/p' "${FB_SDK_ROOT}"/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h)
  FB_SDK_VERSION_MAJOR=$(echo $FB_SDK_VERSION_RAW | awk -F'.' '{print $1}')
  FB_SDK_VERSION_MINOR=$(echo $FB_SDK_VERSION_RAW | awk -F'.' '{print $2}')
  FB_SDK_VERSION_REVISION=$(echo $FB_SDK_VERSION_RAW | awk -F'.' '{print $3}')
  FB_SDK_VERSION_MAJOR=${FB_SDK_VERSION_MAJOR:-0}
  FB_SDK_VERSION_MINOR=${FB_SDK_VERSION_MINOR:-0}
  FB_SDK_VERSION_REVISION=${FB_SDK_VERSION_REVISION:-0}
  FB_SDK_VERSION=$FB_SDK_VERSION_MAJOR.$FB_SDK_VERSION_MINOR.$FB_SDK_VERSION_REVISION
  FB_SDK_VERSION_SHORT=$(echo $FB_SDK_VERSION | sed 's/\.0$//')

  MN_SDK_VERSION_RAW=$(sed -n 's/.*FBSDK_MESSENGER_SHARE_KIT_VERSION @\"\(.*\)\"/\1/p' "${FB_SDK_ROOT}"/FBSDKMessengerShareKit/FBSDKMessengerShareKit/FBSDKMessengerShareKit.h)
  MN_SDK_VERSION_MAJOR=$(echo $MN_SDK_VERSION_RAW | awk -F'.' '{print $1}')
  MN_SDK_VERSION_MINOR=$(echo $MN_SDK_VERSION_RAW | awk -F'.' '{print $2}')
  MN_SDK_VERSION_MAJOR=${MN_SDK_VERSION_MAJOR:-0}
  MN_SDK_VERSION_MINOR=${MN_SDK_VERSION_MINOR:-0}
  MN_SDK_VERSION_SHORT=$(echo $MN_SDK_VERSION_RAW | sed 's/\.0$//')

  # The path to AudienceNetwork scripts directory
  FB_ADS_FRAMEWORK_SCRIPT=$FB_SDK_ROOT/ads/scripts
fi

# Set up one-time variables
if [ -z $FB_SDK_ENV ]; then
  FB_SDK_ENV=env1
  FB_SDK_BUILD_DEPTH=0

  # Explains where the log is if this is the outermost build or if
  # we hit a fatal error.
  function show_summary() {
    test -r "$FB_SDK_BUILD_LOG" && echo "Build log is at $FB_SDK_BUILD_LOG"
  }

  # Determines whether this is out the outermost build.
  function is_outermost_build() {
      test 1 -eq $FB_SDK_BUILD_DEPTH
  }

  # Calls show_summary if this is the outermost build.
  # Do not call outside common.sh.
  function pop_common() {
    FB_SDK_BUILD_DEPTH=$(($FB_SDK_BUILD_DEPTH - 1))
    test 0 -eq $FB_SDK_BUILD_DEPTH && show_summary
  }

  # Deletes any previous build log if this is the outermost build.
  # Do not call outside common.sh.
  function push_common() {
    test 0 -eq $FB_SDK_BUILD_DEPTH && \rm -f "$FB_SDK_BUILD_LOG"
    FB_SDK_BUILD_DEPTH=$(($FB_SDK_BUILD_DEPTH + 1))
  }

  # Echoes a progress message to stderr
  function progress_message() {
      echo "$@" >&2
  }

  # Any script that includes common.sh must call this once if it finishes
  # successfully.
  function common_success() {
      pop_common
      return 0
  }

  # Call this when there is an error.  This does not return.
  function die() {
    echo ""
    echo "FATAL: $*" >&2
    show_summary
    exit 1
  }
fi

# Increment depth every time we . this file.  At the end of any script
# that .'s this file, there should be a call to common_finish to decrement.
push_common
