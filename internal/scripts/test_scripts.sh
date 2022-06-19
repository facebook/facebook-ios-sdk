#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# shellcheck disable=SC2039

# --------------
# Functions
# --------------

# Main
main() {
  TEST_FAILURES=$((0))

  test_internal_globals

  case $TEST_FAILURES in
  0) test_success "test_scripts tests" ;;
  *) test_failure "$TEST_FAILURES test_scripts tests" ;;
  esac
}

# Test Success
test_success() {
  local green='\033[0;32m'
  local none='\033[0m'
  echo "${green}* Passed:${none} $*"
}

# Test Failure
test_failure() {
  local red='\033[0;31m'
  local none='\033[0m'
  echo "${red}* Failed:${none} $*"
}

# Test Main Setup
test_internal_globals() {
  # Arrange
  if [ ! -f "$PWD/internal/scripts/internal_globals.sh" ]; then
    test_failure "You're not in the correct working directory. Please run \`cd fbsource/fbobjc/ios-sdk\` and re-run"
  fi

  # Act
  # shellcheck source=./internal_globals.sh
  . "$PWD/internal/scripts/internal_globals.sh"

  # Assert
  if [ "$FB_INTERN_GRAPH_API" != "https://interngraph.intern.facebook.com" ]; then
    test_failure "FB_INTERN_GRAPH_API not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$SDK_FB_APP_ID" != "584194605123473" ]; then
    test_failure "SDK_FB_APP_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$SDK_FB_TOKEN" != "AeNwlq1Xg7CoDH2b910" ]; then
    test_failure "SDK_FB_TOKEN not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$FB_SDK_PROJECT" != "268235620580741" ]; then
    test_failure "FB_SDK_PROJECT not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_REFERENCE_ID" != "1111513138963800" ]; then
    test_failure "DOCS_REFERENCE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_MAIN_GUIDE_ID" != "1641372119445300" ]; then
    test_failure "DOCS_MAIN_GUIDE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_UPGRADE_GUIDE_ID" != "460058470846126" ]; then
    test_failure "DOCS_UPGRADE_GUIDE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_DOWNLOAD_GUIDE_ID" != "432928110227587" ]; then
    test_failure "DOCS_DOWNLOAD_GUIDE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_CHANGELOG_GUIDE_ID" != "1929572857267386" ]; then
    test_failure "DOCS_CHANGELOG_GUIDE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$DOCS_CHANGELOG_TVOS_GUIDE_ID" != "1229880930358928" ]; then
    test_failure "DOCS_CHANGELOG_TVOS_GUIDE_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$SDK_TEST_FB_APP_ID" != "414221181947517" ]; then
    test_failure "SDK_TEST_FB_APP_ID not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$SDK_TEST_FB_APP_SECRET" != "aaabff2ccdd32888e887d2ffc3e1bf4e" ]; then
    test_failure "SDK_TEST_FB_APP_SECRET not correct"
    ((TEST_FAILURES += 1))
  fi

  if [ "$SDK_TEST_FB_CLIENT_TOKEN" != "dd1aec0b479fa0856c57f345aafa517b" ]; then
    test_failure "SDK_TEST_FB_CLIENT_TOKEN not correct"
    ((TEST_FAILURES += 1))
  fi
}

# --------------
# Main Script
# --------------

main "$@"
