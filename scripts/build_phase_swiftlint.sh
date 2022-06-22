#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# If $PROJECT_DIR is set, this is running from within Xcode from a project subfolder
if [ -n "$PROJECT_DIR" ]; then
  cd .. # cd one level up to find the .swiftlint.yml file
  PROJECT_DIR_NAME=${PROJECT_DIR##*/} # ex FBSDKShareKit
fi

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# Get list of changed files
# shellcheck disable=SC2207
IFS=$'\n' CHANGED_FILES=($(git -P diff --name-only --diff-filter=MA main...HEAD && git -P diff --name-only --diff-filter=MA HEAD))

SWIFTLINT_PATH="internal/tools/swiftlint"
SWIFTFORMAT_PATH="internal/tools/swiftformat"

# If we don't have access to the internal directory, use whatever version is installed
if [ -d "$SWIFTFORMAT_PATH" ]; then
    SWIFTLINT_PATH=$(which swiftlint)
    SWIFTFORMAT_PATH=$(which swiftformat)
fi

# Lint changes from the current revision and uncommitted changes
if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    echo "No files changed."
    exit
fi

# Run the script from the comand line and pass in "--debug" as an argument for debugging
# i.e. scripts/build_phase_swiftlint.sh --debug
if [ "$1" = "--debug" ]; then
  printf "\\nCHANGED_FILES:\\n"
  printf "%s\n" "${CHANGED_FILES[@]}"
fi


# SwiftLint doesn't dedup file path args
# shellcheck disable=SC2207
IFS=$'\n' UNIQUE_SWIFT_FILES=($(printf '%s\n' "${CHANGED_FILES[@]}" | sort -u | grep ".*\.swift$"))
if [ ${#UNIQUE_SWIFT_FILES[@]} -eq 0 ]; then
    echo "No Swift files to lint."
    exit
fi

if [ "$1" = "--debug" ]; then
  printf "\\nUNIQUE_SWIFT_FILES:\\n"
  printf "%s\n" "${UNIQUE_SWIFT_FILES[@]}"
fi

# Fix for issue in which a file was added in a previous commit but is removed in the working copy
LINTABLE_FILES=()
for file in "${UNIQUE_SWIFT_FILES[@]}"; do
    if [[ -e $file ]]; then
      LINTABLE_FILES+=("$file")
    elif [ "$1" = "--debug" ]; then
      echo "FILE DOES NOT EXIST: $file"
    fi
done

if [ "$1" = "--debug" ]; then
  printf "\\nLINTABLE_FILES:\\n"
  printf "%s\n" "${LINTABLE_FILES[@]}"
fi


# Run SwiftFormat
if [ -n "$SWIFTFORMAT_PATH" ]; then
  if [ -n "$PROJECT_DIR_NAME" ]; then # if within Xcode filter by kit name
    $SWIFTFORMAT_PATH --lint "${LINTABLE_FILES[@]}" 2>&1 | grep "$PROJECT_DIR_NAME" || true
  else
    $SWIFTFORMAT_PATH --lint "${LINTABLE_FILES[@]}"
  fi
else
  echo "warning: SwiftFormat not installed. Install with 'brew install swiftformat' or from https://github.com/nicklockwood/SwiftFormat"
fi

# Run SwiftLint
if [ -n "$SWIFTLINT_PATH" ]; then
  if [ -n "$PROJECT_DIR_NAME" ]; then # if within Xcode filter by kit name
    $SWIFTLINT_PATH lint "${LINTABLE_FILES[@]}" | grep "$PROJECT_DIR_NAME" || true
  else
    $SWIFTLINT_PATH lint "${LINTABLE_FILES[@]}"
  fi
else
  echo "warning: SwiftLint not installed, Install with 'brew install swiftlint' or from https://github.com/realm/SwiftLint"
fi
