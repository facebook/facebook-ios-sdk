#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# PostToolUse hook: warn if a Swift or ObjC file is missing the Meta copyright header.
# Outputs a reminder to Claude's context via stdout rather than blocking.
# Always exits 0 — this is advisory only.

set -uo pipefail

# Read JSON from stdin and extract the file path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check Swift and ObjC files
case "$FILE_PATH" in
  *.swift|*.m|*.h) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check for the required copyright header
if ! head -5 "$FILE_PATH" | grep -q "Copyright (c) Meta Platforms, Inc. and affiliates"; then
  echo "WARNING: $FILE_PATH is missing the required Meta copyright header."
  echo "Please add the following header at the top of the file:"
  echo ""
  echo "/*"
  echo " * Copyright (c) Meta Platforms, Inc. and affiliates."
  echo " * All rights reserved."
  echo " *"
  echo " * This source code is licensed under the license found in the"
  echo " * LICENSE file in the root directory of this source tree."
  echo " */"
fi

exit 0
