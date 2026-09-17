#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# PostToolUse hook: remind to run ./generate-projects.sh when new source files
# are created inside module directories.
# Always exits 0 — this is advisory only.

set -uo pipefail

# Read JSON from stdin and extract the file path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check Swift and ObjC source files
case "$FILE_PATH" in
  *.swift|*.m|*.h) ;;
  *) exit 0 ;;
esac

# Only check files inside module source directories
case "$FILE_PATH" in
  FBSDK*/FBSDK*/*|*/FBSDK*/FBSDK*/*|FBAEMKit/FBAEMKit/*|*/FBAEMKit/FBAEMKit/*|TestTools/TestTools/*|*/TestTools/TestTools/*) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist (shouldn't happen for Write, but be safe)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Determine the repo root
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check if the file is tracked by git (i.e., already known)
if git -C "$REPO_ROOT" ls-files --error-unmatch "$FILE_PATH" &>/dev/null; then
  # File is already tracked — no reminder needed
  exit 0
fi

echo "New file detected. Run ./generate-projects.sh to update Xcode project files."

exit 0
