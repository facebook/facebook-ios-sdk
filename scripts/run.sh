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

# shellcheck disable=SC2039

# --------------
# Functions
# --------------

# Main
main() {
  if [ -z "$SCRIPTS_DIR" ]; then
    set_globals
  fi

  local command_type="$1"
  shift

  case "$command_type" in
    "build" )
      build_sdk "$@" ;;
    "help" )
      echo "Check main() for supported commands" ;;
    "test-file-upload" )
      mkdir -p Carthage/Release
      echo "This is a test" >> Carthage/Release/file.txt
      ;;
    "" )
      return ;;
    *)
      echo "Unsupported Command" ;;
  esac
}

# Set Globals
set_globals() {
  SCRIPTS_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
  SDK_DIR="$(dirname "$SCRIPTS_DIR")"; export SDK_DIR;

  SDK_KITS=(
    "FBSDKCoreKit"
    "FBSDKLoginKit"
    "FBSDKShareKit"
    "FBSDKPlacesKit"
    "FBSDKMarketingKit"
    "FBSDKTVOSKit"
    "AccountKit"
  );

  FRAMEWORK_NAME="FacebookSDK"
  POD_SPECS=("$FRAMEWORK_NAME" "${SDK_KITS[@]}"); export POD_SPECS;
}

# Build
build_sdk() {
  build_xcode_workspace() {
    xcodebuild build \
      -workspace "$1" \
      -sdk "$2" \
      -scheme "$3" \
      -configuration Debug \
      | xcpretty
  }

  build_carthage() {
    carthage build --no-skip-current

    if [ "$1" == "--archive" ]; then
      for kit in "${SDK_KITS[@]}";
      do
        if [ -d "$SDK_DIR"/Carthage/Build/iOS/"$kit".framework ] ||
          [ -d "$SDK_DIR"/Carthage/Build/tvOS/"$kit".framework ]; then
          carthage archive "$kit" --output Carthage/Release/
        fi
      done
    fi
  }

  local build_type="$1"
  shift

  case "$build_type" in
    "carthage" )
      build_carthage "$@" ;;
    "xcode" )
      build_xcode_workspace "$@" ;;
    *)
      echo "Unsupported Build" ;;
  esac
}

# --------------
# Main Script
# --------------

main "$@"
