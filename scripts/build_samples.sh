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

# This script builds all of the samples in the samples subdirectory.

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# valid arguments are: no-value, "Debug" and "Release" (default)
BUILDCONFIGURATION=${1:-Release}

test -x "$XCODEBUILD" || die 'Could not find xcodebuild in $PATH'

# -----------------------------------------------------------------------------
progress_message Building samples.

# -----------------------------------------------------------------------------
# Call out to build .framework
#
if is_outermost_build; then
  . "$FB_SDK_SCRIPT/build_framework.sh" -n -c Release
fi

# -----------------------------------------------------------------------------
# Determine which samples to build.
#

# Certain subdirs of samples are not samples to be built, exclude them from the find query
FB_SAMPLES_EXCLUDED=(FBConnect.bundle Configurations)
for excluded in "${FB_SAMPLES_EXCLUDED[@]}"; do
  FB_FIND_ARGS="$FB_FIND_ARGS -not -name $excluded"
done

# -----------------------------------------------------------------------------
# Build each sample
#
function xcode_build_sample() {
  cd "$FB_SDK_SAMPLES/$1"
  progress_message "Compiling '${1}' for platform '${2}(${3})' using configuration '${4}'."
  "$XCODEBUILD" \
    -alltargets \
    -configuration "${4}" \
    -sdk $2 \
    ARCHS=$3 \
    SYMROOT="$FB_SDK_BUILD" \
    clean build \
    || die "XCode build failed for sample '${1}' for platform '${2}(${3})' using configuration '${4}'."
}

for sampledir in `find "$FB_SDK_SAMPLES" -type d -depth 1 $FB_FIND_ARGS -exec basename \{\} \;`; do
  xcode_build_sample "$sampledir" "iphonesimulator" "i386" "$BUILDCONFIGURATION"
done

# -----------------------------------------------------------------------------
# Done
#
common_success
