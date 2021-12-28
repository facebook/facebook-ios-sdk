#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# If $PROJECT_DIR is set, this is running from within Xcode from a project subfolder
if [ -n "$PROJECT_DIR" ]; then
    cd .. # cd one level up to find the .swiftlint.yml file
fi

# Add paths for Hg since Xcode build phases do not source the user shell profile
export PATH="/usr/local/bin:/opt/facebook/hg/bin:$PATH"

HG_ROOT=$(hg root 2>/dev/null)
if [ -n "$HG_ROOT" ]; then
  SWIFTLINT_PATH="../Tools/swiftlint/swiftlint"
  SWIFTFORMAT_PATH="internal/tools/swiftformat"
  IFS=$'\n' CHANGED_FILES=($(hg status --modified --added --no-status --rev 'ancestor(master,.)::.' && hg status --no-status --unknown --modified --added | grep -v '\.\./'))
else
  SWIFTLINT_PATH=$(which swiftlint)
  SWIFTFORMAT_PATH=$(which swiftformat)
  IFS=$'\n' CHANGED_FILES=($(git -P diff --name-only --diff-filter=MA main...HEAD && git -P diff --name-only --diff-filter=MA HEAD))
fi

# Lint changes from the current revision and uncommitted changes
if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    echo "No files changed."
    exit
fi

# SwiftLint doesn't dedup file path args
IFS=$'\n' UNIQUE_SWIFT_FILES=($(printf '%s\n' "${CHANGED_FILES[@]}" | sort -u | grep ".*\.swift$"))
if [ ${#UNIQUE_SWIFT_FILES[@]} -eq 0 ]; then
    echo "No Swift files to lint."
    exit
fi

# Run SwiftFormat
if [ -n "$SWIFTFORMAT_PATH" ]; then
  $SWIFTFORMAT_PATH "${UNIQUE_SWIFT_FILES[@]}"
else
  echo "warning: SwiftFormat not installed. Install with 'brew install swiftformat' or from https://github.com/nicklockwood/SwiftFormat"
fi

# Run SwiftLint
if [ -n "$SWIFTLINT_PATH" ]; then
  $SWIFTLINT_PATH lint "${UNIQUE_SWIFT_FILES[@]}"
else
  echo "warning: SwiftLint not installed, Install with 'brew install swiftlint' or from https://github.com/realm/SwiftLint"
fi
