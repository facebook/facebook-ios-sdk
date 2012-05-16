#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds the API documentation from source-level comments.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# -----------------------------------------------------------------------------
# Build pre-requisites
#
if is_outermost_build; then
    . $FB_SDK_SCRIPT/build_framework.sh -n
fi
echo Building Documentation.

# -----------------------------------------------------------------------------
# Build docs
#
test -d $FB_SDK_BUILD \
  || mkdir -p $FB_SDK_BUILD \
  || die "Could not create directory $FB_SDK_BUILD"

cd $FB_SDK_SRC

\headerdoc2html -o $FB_SDK_FRAMEWORK_DOCS $FB_SDK_FRAMEWORK/Headers >/dev/null 2>&1

# -----------------------------------------------------------------------------
# Done
#
common_success
