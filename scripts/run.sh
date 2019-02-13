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
    # Set global variables

    SCRIPTS_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
    SDK_DIR="$(dirname "$SCRIPTS_DIR")"

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
    POD_SPECS[7]="AccountKit/${POD_SPECS[7]}"

    CURRENT_VERSION=$(grep -Eo 'FBSDK_PROJECT_VERSION=.*' "$SDK_DIR/$MAIN_VERSION_FILE" | awk -F'=' '{print $2}')
    export CURRENT_VERSION
  fi

  local command_type="$1"
  shift

  case "$command_type" in
  "build") build_sdk "$@" ;;
  "bump-version") bump_version "$@" ;;
  "is-valid-semver") is_valid_semver "$@" ;;
  "does-version-exist") does_version_exist "$@" ;;
  "release") release_sdk "$@" ;;
  "tag-push-current-version") tag_push_current_version "$@" ;;
  "lint") lint_sdk "$@" ;;
  "test-file-upload")
    mkdir -p Carthage/Release
    echo "This is a test" >>Carthage/Release/file.txt
    ;;
  "--help" | "help" | *) echo "Check main() for supported commands" ;;
  esac
}

# Bump Version
bump_version() {
  local new_version="$1"

  if [ "$new_version" == "$CURRENT_VERSION" ]; then
    echo "This version is the same as the current version"
    false
    return
  fi

  if ! is_valid_semver "$new_version"; then
    echo "This version isn't a valid semantic versioning"
    false
    return
  fi

  echo "Changing from: $CURRENT_VERSION to: $new_version"

  local version_change_files=(
    "${VERSION_FILES[@]}"
    "${POD_SPECS[@]}"
  )

  # Replace the previous version to the new version in relative files
  for file_path in "${version_change_files[@]}"; do
    local full_file_path="$SDK_DIR/$file_path"

    if [ ! -f "$full_file_path" ]; then
      echo "*** NOTE: unable to find $full_file_path."
      continue
    fi

    local temp_file="$full_file_path.tmp"
    sed -e "s/$CURRENT_VERSION/$new_version/g" "$full_file_path" >"$temp_file"
    if diff "$full_file_path" "$temp_file" >/dev/null; then
      echo "*** ERROR: unable to update $full_file_path"
      rm "$temp_file"
      continue
    fi

    mv "$temp_file" "$full_file_path"
  done
}

# Tag push current version
tag_push_current_version() {
  if ! is_valid_semver "$CURRENT_VERSION"; then
    exit 1
  fi

  if does_version_exist "$CURRENT_VERSION"; then
    echo "Version $CURRENT_VERSION already exists"
    false
    return
  fi

  git tag -a "v$CURRENT_VERSION" -m "Version $CURRENT_VERSION"
  git push origin "v$CURRENT_VERSION"
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
  *) echo "Unsupported Build: $build_type" ;;
  esac
}

# Lint
lint_sdk() {
  # Lint Podspecs
  lint_podspecs() {
    for spec in "${POD_SPECS[@]}"; do
      if [ ! -f "$spec" ]; then
        echo "*** ERROR: unable to lint $spec"
        continue
      fi

      pod lib lint "$spec" "$@"
    done
  }

  local lint_type="$1"
  shift

  case "$lint_type" in
  "podspecs") release_cocoapods "$@" ;;
  *) echo "Unsupported Lint: $lint_type" ;;
  esac
}

# Release
release_sdk() {

  # Release Cocoapods
  release_cocoapods() {
    for spec in "${POD_SPECS[@]}"; do
      if [ ! -f "$spec" ]; then
        echo "*** ERROR: unable to release $spec"
        continue
      fi

      pod trunk push "$spec" "$@"
    done
  }

  local release_type="$1"
  shift

  case "$release_type" in
  "cocoapods") release_cocoapods "$@" ;;
  *) echo "Unsupported Release: $release_type" ;;
  esac
}

# Proper Semantic Version
is_valid_semver() {
  if ! [[ "$1" =~ ^([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)($|[-+][0-9A-Za-z+.-]+$) ]]; then
    false
    return
  fi
}

# Check Version Tag Exists
does_version_exist() {
  local version_to_check="$1"

  if [ "$version_to_check" == "" ]; then
    version_to_check=$CURRENT_VERSION
  fi

  if git rev-parse "v$version_to_check" >/dev/null 2>&1; then
    return
  fi

  false
}

# --------------
# Main Script
# --------------

main "$@"
