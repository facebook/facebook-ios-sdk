#!/bin/bash
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# The purpose of this hook is to run pngcrush-compression.sh
# on every folder that contains a png image to be commited.

ROOT=`git rev-parse --show-toplevel`
PNGCRUSH_PATH="$ROOT/internal/tools/pngcrush/pngcrush.sh"
# We only want to run the open source (non-apple) pngcrush
# as the apple one prevents the files from easily being
# opened and edited

# The default behavior is to pngcrush *ALL* files (staged and unstaged). If you pass "cached" as a parameter, this is
# restricted to only staged files.
relative_to_cached=false
git_options=""
if [ "$1" == "cached" ]; then
  relative_to_cached=true
  git_options="--cached"
fi

function get_files() {
  # Find files that have changed from HEAD, filter out deleted or renamed ones,
  # restrict the results to pngs, and then strip each line to the file path
  while IFS= read -r file; do
    if [ "$file" != "" ]; then
      echo "$file"
    fi
  done <<EOF
`git diff-index --find-renames --name-status $git_options HEAD | grep -v ^D | grep -v ^R100 | grep "\.png" | cut -f2`
EOF
}

if [[ $(git log -n 1 --pretty=format:%b HEAD) == *NOCRUSH* ]]; then
  echo "NOCRUSH found in commit body. Skipping pngcrush.";
else
  while read file
  do
    if [[ $file != internal/parse-cloud-code/* ]]; then
      echo "Running pngcrush.sh on file $ROOT/$file"
      $PNGCRUSH_PATH "$ROOT/$file" > /dev/null 2>&1
      if [ "$relative_to_cached" = true ]; then
        git add "$ROOT/$file"
      fi
    fi
  done < <( get_files )
fi
