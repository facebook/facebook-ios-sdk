#!/bin/sh
#
# Copyright 2010-present Facebook.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script exports the source code to another directory that can be
# added to a different git repo.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

usage() {
cat <<EOF
Usage: $0 -o output_path

Exports the files that are in the current git repo index to the specified path.

OPTIONS:
    -o  Path where the files should be exported to.
EOF
}

while getopts "ho:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 0;;
    o)
      OUTPUT_DIR="$OPTARG";;
    [?])
      usage
      exit 1;;
  esac
done

if [ -z "$OUTPUT_DIR" ]; then
  echo "$0: option requires an argument -- o"
  usage
  exit 1
fi

if [ -f "$OUTPUT_DIR" ]; then
  echo "Output path cannot point to a file: $OUTPUT_DIR"
  usage
  exit 1
fi

# Create a temp directory to stage the files from the index into.
CURRENT_SCRIPT_NAME=`basename $0`
EXPORT_TEMP_DIR=`mktemp -d -t ${CURRENT_SCRIPT_NAME}` || die "Failed to create temp directory"

# Export the files from the index to the temp directory. This avoids picking
# up build artifacts or other files that are not in the git index.
git checkout-index -a --prefix="$EXPORT_TEMP_DIR"/

# Sync the exported files from the temp directory into $OUTPUT_DIR
rsync -avm --delete --exclude '.git' --exclude 'vendor/*' --exclude 'internal' "$EXPORT_TEMP_DIR"/ "$OUTPUT_DIR"/

# Cleanup the temp folder
rm -r "$EXPORT_TEMP_DIR"

# If the output directory is a git enlistment, configure the submodules
if [ -d "$OUTPUT_DIR"/.git ]; then
  # Setup/update the submodules in the output directory
  (
    cd "$OUTPUT_DIR"
    git config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
    while read SUBMODULE_PATH_KEY SUBMODULE_PATH
    do
      SUBMODULE_NAME=$(echo $SUBMODULE_PATH_KEY | sed 's/^submodule\.//g' | sed 's/\.path$//g')
      SUBMODULE_URL_KEY=$(echo $SUBMODULE_PATH_KEY | sed 's/\.path/\.url/g')
      url_key=$(echo $path_key | sed 's/\.path/.url/')
      SUBMODULE_URL=$(git config -f .gitmodules --get "$SUBMODULE_URL_KEY")
      # add each of the submodules, since we don't know if it previously existed
      git submodule add $SUBMODULE_URL $SUBMODULE_PATH
    done
    # sync in order to pick up any changes to the remote URL
    git submodule sync
    # make sure they are all up to date
    git submodule update --init --recursive
  )

  # Checkout the correct revision in each of the submodules. We need to read the
  # current revision from the local repo and then checkout that revision in the
  # output directory
  git submodule status |
  while read SUBMODULE_REVISION SUBMODULE_KEY SUBMODULE_VERSION
  do
    (
      cd "$OUTPUT_DIR"
      SUBMODULE_REVISION=$SUBMODULE_REVISION
      SUBMODULE_KEY=$SUBMODULE_KEY
      SUBMODULE_PATH=`git config -f .gitmodules --get "submodule.${SUBMODULE_KEY}.path"`
      cd "$SUBMODULE_PATH"
      git checkout -q $SUBMODULE_REVISION
    )
  done
fi

# Done
progress_message "Successfully exported to $OUTPUT_DIR"
common_success
