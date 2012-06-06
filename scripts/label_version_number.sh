#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

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

git tag "$TAG_NAME" HEAD \
    || die 'Failed to tag HEAD. If this is a duplicate tag, please delete the old one first.'

progress_message "Tagged HEAD as $TAG_NAME"
progress_message "Be sure to use 'git push --tags' in order to push tags upstream."

common_success
