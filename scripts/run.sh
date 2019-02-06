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
  "build") build_sdk "$@" ;;
  "bump-version") bump_version "$@" ;;
  "confirm-semver") confirm_semver "$@" ;;
  "help") echo "Check main() for supported commands" ;;
  "lint-podspecs") lint_podspecs "$@" ;;
  "test-file-upload")
    mkdir -p Carthage/Release
    echo "This is a test" >>Carthage/Release/file.txt
    ;;
  "") return ;;
  *) echo "Unsupported Command" ;;
  esac
}

# Set Globals
set_globals() {
  SCRIPTS_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
  SDK_DIR="$(dirname "$SCRIPTS_DIR")"
  export SDK_DIR

  SDK_KITS=(
    "FBSDKCoreKit"
    "FBSDKLoginKit"
    "FBSDKShareKit"
    "FBSDKPlacesKit"
    "FBSDKMarketingKit"
    "FBSDKTVOSKit"
    "AccountKit"
  )

  VERSION_FILES=(
    "Configurations/Version.xcconfig"
    "FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h"
    "AccountKit/AccountKit/Internal/AKFConstants.m"
  )

  MAIN_VERSION_FILE="Configurations/Version.xcconfig"

  FRAMEWORK_NAME="FacebookSDK"

  POD_SPECS=("$FRAMEWORK_NAME" "${SDK_KITS[@]}")
  POD_SPECS=("${POD_SPECS[@]/%/.podspec}")

  export POD_SPECS
}

# Build
build_sdk() {
  build_xcode_workspace() {
    xcodebuild build \
      -workspace "$1" \
      -sdk "$2" \
      -scheme "$3" \
      -configuration Debug |
      xcpretty
  }

  build_carthage() {
    carthage build --no-skip-current

    if [ "$1" == "--archive" ]; then
      for kit in "${SDK_KITS[@]}"; do
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
  "carthage") build_carthage "$@" ;;
  "xcode") build_xcode_workspace "$@" ;;
  *) echo "Unsupported Build" ;;
  esac
}

# Bump Version
bump_version() {
  local current_version
  current_version=$(grep -Eo 'FBSDK_PROJECT_VERSION=.*' "$SDK_DIR/$MAIN_VERSION_FILE" | awk -F'=' '{print $2}')
  local new_version="$1"

  local version_change_files=(
    "${VERSION_FILES[@]}"
    "${POD_SPECS[@]}"
  )

  # Replace the previous version to the new version in relative files
  for file_path in "${version_change_files[@]}"; do
    local full_file_path="$SDK_DIR/$file_path"

    if [ ! -f "$full_file_path" ]; then
      echo "*** ERROR: unable to find $full_file_path"
      continue
    fi

    local temp_file="$full_file_path.tmp"
    sed -e "s/$current_version/$new_version/g" "$full_file_path" >"$temp_file"
    if diff "$full_file_path" "$temp_file" >/dev/null; then
      echo "*** ERROR: unable to update $full_file_path"
      rm "$temp_file"
      continue
    fi

    mv "$temp_file" "$full_file_path"
  done
}

# Proper Semantic Version
confirm_semver() {
  if ! [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+($|[-+][0-9A-Za-z+.-]+$) ]]; then
    false
    return
  fi
}

lint_podspecs() {
  for spec in "${POD_SPECS[@]}"; do
    pod lib lint "$spec" "$@"
  done
}

# --------------
# Main Script
# --------------

main "$@"
