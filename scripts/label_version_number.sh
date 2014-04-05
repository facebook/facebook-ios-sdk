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

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 MAJOR MINOR [HOTFIX [BETA]]"
    echo "  MAJOR         major version number"
    echo "  MINOR         minor version number"
    echo "  HOTFIX        hotfix version number"
    echo "  BETA          'b' if this is a beta release"
    die 'Arguments do not conform to usage'
fi

cd $FB_SDK_SRC

VERSION_STRING="$1"."$2"

if [ "$3" != "" ]; then
    VERSION_STRING="$VERSION_STRING"."$3"
fi
if [ "$4" != "" ]; then
    # We actually append 'b' regardless of what was passed.
    VERSION_STRING="$VERSION_STRING".b
fi

TAG_NAME=sdk-version-"$VERSION_STRING"

git tag -a "$TAG_NAME" HEAD \
    || die 'Failed to tag HEAD. If this is a duplicate tag, please delete the old one first.'

progress_message "Tagged HEAD as $TAG_NAME"
progress_message "Be sure to use 'git push --tags' in order to push tags upstream."

common_success
