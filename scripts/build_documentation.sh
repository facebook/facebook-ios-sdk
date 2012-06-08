#!/bin/sh
#
# Copyright 2012 Facebook
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

# This script builds the API documentation from source-level comments.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# -----------------------------------------------------------------------------
# Build pre-requisites
#
if is_outermost_build; then
    . $FB_SDK_SCRIPT/build_framework.sh -n
fi
progress_message Building Documentation.

# -----------------------------------------------------------------------------
# Build docs
#
test -d $FB_SDK_BUILD \
  || mkdir -p $FB_SDK_BUILD \
  || die "Could not create directory $FB_SDK_BUILD"

cd $FB_SDK_SRC

\headerdoc2html -o $FB_SDK_FRAMEWORK_DOCS $FB_SDK_FRAMEWORK/Headers >/dev/null 2>&1
\gatherheaderdoc $FB_SDK_FRAMEWORK_DOCS

# -----------------------------------------------------------------------------
# Done
#
common_success
