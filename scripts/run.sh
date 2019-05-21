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

set -euo pipefail

# --------------
# Imports
# --------------

if [ -f "$PWD/internal/scripts/internal_globals.sh" ]; then
  # shellcheck source=../internal/scripts/internal_globals.sh
  . "$PWD/internal/scripts/internal_globals.sh"
fi

if [ -f "$PWD/internal/scripts/intern_api.sh" ]; then
  # shellcheck source=../internal/scripts/intern_api.sh
  . "$PWD/internal/scripts/intern_api.sh"
fi

# --------------
# Functions
# --------------

# Main
main() {
  if [ -z "${SDK_SCRIPTS_DIR:-}" ]; then
    # Set global variables

    SDK_SCRIPTS_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
    SDK_DIR="$(dirname "$SDK_SCRIPTS_DIR")"

    SDK_KITS=(
      "FBSDKCoreKit"
      "FBSDKLoginKit"
      "FBSDKShareKit"
      "FBSDKPlacesKit"
      "FBSDKMarketingKit"
      "FBSDKTVOSKit"
      "AccountKit"
    )

    SDK_VERSION_FILES=(
      "Configurations/Version.xcconfig"
      "FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h"
      "AccountKit/AccountKit/Internal/AKFConstants.m"
    )

    SDK_GRAPH_API_VERSION_FILES=(
      "FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h"
      "FBSDKCoreKit/FBSDKCoreKitTests/FBSDKGraphRequestTests.m"
    )

    SDK_MAIN_VERSION_FILE="FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h"

    SDK_FRAMEWORK_NAME="FacebookSDK"

    SDK_POD_SPECS=("${SDK_KITS[@]}" "$SDK_FRAMEWORK_NAME")
    SDK_POD_SPECS=("${SDK_POD_SPECS[@]/%/.podspec}")
    SDK_POD_SPECS[6]="AccountKit/${SDK_POD_SPECS[6]}"

    SDK_LINT_POD_SPECS=(
      "FBSDKCoreKit.podspec"
      "FBSDKLoginKit.podspec"
      "FBSDKShareKit.podspec"
      "FBSDKPlacesKit.podspec"
      "FBSDKTVOSKit.podspec"
    )

    SDK_CURRENT_VERSION=$(grep -Eo 'FBSDK_VERSION_STRING @".*"' "$SDK_DIR/$SDK_MAIN_VERSION_FILE" | awk -F'"' '{print $2}')
    SDK_CURRENT_GRAPH_API_VERSION=$(grep -Eo 'FBSDK_TARGET_PLATFORM_VERSION @".*"' "$SDK_DIR/$SDK_MAIN_VERSION_FILE" | awk -F'"' '{print $2}')

    SDK_GIT_REMOTE="https://github.com/facebook/facebook-objc-sdk"

    if [ -f "$PWD/internal/scripts/internal_globals.sh" ]; then SDK_INTERNAL=1; else SDK_INTERNAL=0; fi
  fi

  local command_type=${1:-}
  if [ -n "$command_type" ]; then shift; fi

  case "$command_type" in
  "build") build_sdk "$@" ;;
  "bump-version") bump_version "$@" ;;
  "bump-api-version") bump_api_version "$@" ;;
  "bump-changelog") bump_changelog "$@" ;;
  "check-release-status") check_release_status "$@" ;;
  "is-valid-semver") is_valid_semver "$@" ;;
  "does-version-exist") does_version_exist "$@" ;;
  "release") release_sdk "$@" ;;
  "setup") setup_sdk "$@" ;;
  "tag-current-version") tag_current_version "$@" ;;
  "lint") lint_sdk "$@" ;;
  "test-file-upload")
    mkdir -p Carthage/Release
    echo "This is a test" >>Carthage/Release/file.txt
    ;;
  "--help" | "help") echo "Check main() for supported commands" ;;
  esac
}

# Setup SDK
setup_sdk() {
  local sdk_test_app_id=${1:-$SDK_TEST_FB_APP_ID}
  local sdk_test_app_secret=${2:-$SDK_TEST_FB_APP_SECRET}
  local sdk_test_client_token=${3:-$SDK_TEST_FB_CLIENT_TOKEN}
  local sdk_machine_unique_user_key=${4:-}

  {
    echo "IOS_SDK_TEST_APP_ID = $sdk_test_app_id"
    echo "IOS_SDK_TEST_APP_SECRET = $sdk_test_app_secret"
    echo "IOS_SDK_TEST_CLIENT_TOKEN = $sdk_test_client_token"
    echo "IOS_SDK_MACHINE_UNIQUE_USER_KEY = $sdk_machine_unique_user_key"
  } >>"$SDK_DIR"/Configurations/TestAppIdAndSecret.xcconfig
}

# Bump Version
bump_version() {
  local new_version=${1:-}

  if [ "$new_version" == "$SDK_CURRENT_VERSION" ]; then
    echo "This version is the same as the current version"
    false
    return
  fi

  if ! is_valid_semver "$new_version"; then
    echo "This version isn't a valid semantic versioning"
    false
    return
  fi

  echo "Changing from: $SDK_CURRENT_VERSION to: $new_version"

  local version_change_files=(
    "${SDK_VERSION_FILES[@]}"
    "${SDK_POD_SPECS[@]}"
  )

  # Replace the previous version to the new version in relative files
  for file_path in "${version_change_files[@]}"; do
    local full_file_path="$SDK_DIR/$file_path"

    if [ ! -f "$full_file_path" ]; then
      echo "*** NOTE: unable to find $full_file_path."
      continue
    fi

    local temp_file="$full_file_path.tmp"
    sed -e "s/$SDK_CURRENT_VERSION/$new_version/g" "$full_file_path" >"$temp_file"
    if diff "$full_file_path" "$temp_file" >/dev/null; then
      echo "*** ERROR: unable to update $full_file_path"
      rm "$temp_file"
      continue
    fi

    mv "$temp_file" "$full_file_path"
  done

  bump_changelog "$new_version"
}

# Bump Version
bump_api_version() {
  local new_version=${1:-}

  if [ "$new_version" == "$SDK_CURRENT_GRAPH_API_VERSION" ]; then
    echo "This version is the same as the current version"
    false
    return
  fi

  echo "Changing from: $SDK_CURRENT_GRAPH_API_VERSION to: $new_version"

  # Replace the previous version to the new version in relative files
  for file_path in "${SDK_GRAPH_API_VERSION_FILES[@]}"; do
    local full_file_path="$SDK_DIR/$file_path"

    if [ ! -f "$full_file_path" ]; then
      echo "*** NOTE: unable to find $full_file_path."
      continue
    fi

    local temp_file="$full_file_path.tmp"
    sed -e "s/$SDK_CURRENT_GRAPH_API_VERSION/$new_version/g" "$full_file_path" >"$temp_file"
    if diff "$full_file_path" "$temp_file" >/dev/null; then
      echo "*** ERROR: unable to update $full_file_path"
      rm "$temp_file"
      continue
    fi

    mv "$temp_file" "$full_file_path"
  done
}

bump_changelog() {
  local new_version=${1:-}

  # Edit Changelog
  local updated_changelog=""

  while IFS= read -r line; do
    local updated_line

    case "$line" in
    "[Full Changelog]("*"$SDK_CURRENT_VERSION...HEAD)")
      local current_date
      current_date=$(date +%Y-%m-%d)

      updated_line="\n""${line/$SDK_CURRENT_VERSION/$new_version}""\n\n"
      updated_line=$updated_line"## $new_version\n\n"
      updated_line=$updated_line"[$current_date]"
      updated_line=$updated_line"($SDK_GIT_REMOTE/releases/tag/v$new_version) |\n"
      updated_line=$updated_line"[Full Changelog]($SDK_GIT_REMOTE/compare/v$SDK_CURRENT_VERSION...v$new_version)"
      ;;
    "# Changelog") updated_line=$line ;;
    *) updated_line="\n"$line ;;
    esac

    updated_changelog=$updated_changelog$updated_line
  done <"CHANGELOG.md"

  echo "$updated_changelog" >CHANGELOG.md
}

# Tag push current version
tag_current_version() {
  if ! is_valid_semver "$SDK_CURRENT_VERSION"; then
    exit 1
  fi

  if does_version_exist "$SDK_CURRENT_VERSION"; then
    echo "Version $SDK_CURRENT_VERSION already exists"
    false
    return
  fi

  git tag -a "v$SDK_CURRENT_VERSION" -m "Version $SDK_CURRENT_VERSION"

  if [ "${1:-}" == "--push" ]; then
    git push origin "v$SDK_CURRENT_VERSION"
  fi
}

# Build
build_sdk() {
  build_xcode_workspace() {
    xcodebuild build \
      -workspace "${1:-}" \
      -sdk "${2:-}" \
      -scheme "${3:-}" \
      -configuration Debug \
      | xcpretty
  }

  build_carthage() {
    carthage build --no-skip-current

    if [ "${1:-}" == "--archive" ]; then
      carthage archive --output Carthage/Release/
    fi
  }

  local build_type=${1:-}
  if [ -n "$build_type" ]; then shift; fi

  case "$build_type" in
  "carthage") build_carthage "$@" ;;
  "xcode") build_xcode_workspace "$@" ;;
  *) echo "Unsupported Build: $build_type" ;;
  esac
}

# Lint
lint_sdk() {
  # Lint Podspecs
  lint_cocoapods() {
    pod_lint_failures=()

    for spec in "${SDK_LINT_POD_SPECS[@]}"; do
      if [ ! -f "$spec" ]; then
        echo "*** ERROR: unable to lint $spec"
        continue
      fi

      set +e
      if ! pod lib lint "$spec" "$@"; then
        pod_lint_failures+=("$spec")
      fi
      set -e
    done

    if [ ${#pod_lint_failures[@]} -ne 0 ]; then
      echo "Failed lint for: ${pod_lint_failures[*]}"
      exit 1
    else
      exit 0
    fi
  }

  local lint_type=${1:-}
  if [ -n "$lint_type" ]; then shift; fi

  case "$lint_type" in
  "cocoapods") lint_cocoapods "$@" ;;
  *) echo "Unsupported Lint: $lint_type" ;;
  esac
}

# Release
release_sdk() {

  # Release Cocoapods
  release_cocoapods() {
    for spec in "${SDK_POD_SPECS[@]}"; do
      if [ ! -f "$spec" ]; then
        echo "*** ERROR: unable to release $spec"
        continue
      fi

      set +e
      # shellcheck disable=SC2086
      if [ $TRAVIS ]; then
        pod trunk push --verbose --allow-warnings "$spec" "$@" | tee pod.log | ruby -e 'ARGF.each{ print "." }'
      else
        pod trunk push "$spec" "$@"
      fi
      set -e
    done
  }

  release_docs() {
    for kit in "${SDK_KITS[@]}"; do
      local prefix
      if [ "$kit" == "FBSDKMarketingKit" ]; then prefix="internal/"; else prefix=""; fi

      local header_file="$prefix$kit/$kit/$kit".h

      if [ ! -f "$header_file" ]; then
        echo "*** ERROR: unable to document $kit"
        continue
      fi

      jazzy \
        --framework-root "$prefix$kit" \
        --output docs/"$kit" \
        --umbrella-header "$header_file"

      # Zip the result so it can be uploaded easily
      pushd docs/ || continue
      zip -r "$kit.zip" "$kit"
      popd || continue

      if [[ $SDK_INTERNAL == 1 ]] && [ "${1:-}" == "--publish" ]; then
        api_update_reference_doc "$kit"
      fi
    done
  }

  # Generate External Docs Changelog
  release_external_changelog() {
    echo "Releasing Changelog"

    local current_version_underscore=${SDK_CURRENT_VERSION//./_}
    local current_date
    current_date=$(date +%Y-%m-%d)
    local external_changelog="## $SDK_CURRENT_VERSION - $current_date {#$current_version_underscore}"
    local start_logging=0
    local tfile
    tfile=$(mktemp)

    while IFS= read -r line; do
      case "$line" in
      "## $SDK_CURRENT_VERSION")
        start_logging=1
        ;;
      "## "*)
        if [[ $start_logging == 1 ]]; then
          start_logging=0
        fi
        ;;
      *)
        if [[ $start_logging == 1 ]]; then
          external_changelog=$external_changelog"\n"$line
        fi
        ;;
      esac
    done <"CHANGELOG.md"

    echo "$external_changelog" >"$tfile"
    api_update_guide_doc "$tfile"
  }

  local release_type=${1:-}
  if [ -n "$release_type" ]; then shift; fi

  case "$release_type" in
  "cocoapods") release_cocoapods "$@" ;;
  "docs" | "documentation") release_docs "$@" ;;
  "changelog") release_external_changelog "$@" ;;
  *) echo "Unsupported Release: $release_type" ;;
  esac
}

# Check Release Status
check_release_status() {
  local version_to_check=${1:-}
  local release_success=0

  if ! is_valid_semver "$version_to_check"; then
    echo "$version_to_check isn't a valid semantic versioning"
    ((release_success += 1))
  fi

  if ! does_version_exist "$version_to_check"; then
    echo "$version_to_check isn't tagged in GitHub"
    ((release_success += 1))
  fi

  local pod_info

  for spec in "${SDK_POD_SPECS[@]}"; do
    if [ ! -f "$spec" ]; then
      echo "*** ERROR: unable to release $spec"
      continue
    fi

    pod_info=$(pod trunk info "${spec/.podspec/}")

    if [[ $pod_info != *"$version_to_check"* ]]; then
      echo "$spec hasn't been released yet"
      ((release_success += 1))
    fi
  done

  case $release_success in
  0) return ;;
  *) false ;;
  esac
}

# Proper Semantic Version
is_valid_semver() {
  if ! [[ ${1:-} =~ ^([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)($|[-+][0-9A-Za-z+.-]+$) ]]; then
    false
    return
  fi
}

# Check Version Tag Exists
does_version_exist() {
  local version_to_check=${1:-}

  if [ "$version_to_check" == "" ]; then
    version_to_check=$SDK_CURRENT_VERSION
  fi

  if [ ! -d "$SDK_DIR"/.git ]; then
    echo "Not a Git Repository"
    return
  fi

  if git rev-parse "v$version_to_check" >/dev/null 2>&1; then
    return
  fi

  if git rev-parse "sdk-version-$version_to_check" >/dev/null 2>&1; then
    return
  fi

  false
}

# --------------
# Main Script
# --------------

main "$@"
