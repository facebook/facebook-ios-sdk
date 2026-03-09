#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# PostToolUse hook: auto-format Swift files after Write or Edit.
# Reads tool_input from JSON on stdin, extracts file_path,
# and runs swiftformat on Swift files only.
# Always exits 0 — formatting failures should not block work.

set -uo pipefail

# Read JSON from stdin and extract the file path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Skip if no file path or not a Swift file
if [ -z "$FILE_PATH" ] || [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

# Skip if file doesn't exist (e.g., was deleted)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Determine the repo root (where .swiftformat lives)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Prefer internal swiftformat binary if available, fall back to system install
if [ -x "$REPO_ROOT/internal/tools/swiftformat" ]; then
  SWIFTFORMAT="$REPO_ROOT/internal/tools/swiftformat"
elif command -v swiftformat &>/dev/null; then
  SWIFTFORMAT="swiftformat"
else
  # No swiftformat available — skip silently
  exit 0
fi

# Run swiftformat on the single file using the repo's config
"$SWIFTFORMAT" "$FILE_PATH" --config "$REPO_ROOT/.swiftformat" &>/dev/null

exit 0
