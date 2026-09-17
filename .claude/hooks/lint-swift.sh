#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# PostToolUse hook: run SwiftLint on edited Swift files to catch structural issues.
# Reports violations to stdout so the agent can self-correct.
# Always exits 0 — linting failures should not block work.

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

# Determine the repo root (where .swiftlint.yml lives)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Prefer system swiftlint (more likely to be compatible), fall back to internal binary
SWIFTLINT=""
if command -v swiftlint &>/dev/null; then
  SWIFTLINT="swiftlint"
elif [ -x "$REPO_ROOT/internal/tools/swiftlint" ]; then
  SWIFTLINT="$REPO_ROOT/internal/tools/swiftlint"
fi
if [ -z "$SWIFTLINT" ]; then
  echo "Note: swiftlint not available. Install with 'brew install swiftlint' for lint feedback."
  exit 0
fi

# Run swiftlint on the single file (non-strict — warnings only)
OUTPUT=$("$SWIFTLINT" lint --quiet --config "$REPO_ROOT/.swiftlint.yml" "$FILE_PATH" 2>/dev/null)

if [ -n "$OUTPUT" ]; then
  echo "SwiftLint violations found in $FILE_PATH:"
  echo "$OUTPUT"
fi

exit 0
