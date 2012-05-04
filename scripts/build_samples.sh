#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds all of the samples in the samples subdirectory.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# valid arguments are: no-value, "Debug" and "Release" (default)
BUILDCONFIGURATION=${1:-Release}

test -x "$XCODEBUILD" || die 'Could not find xcodebuild in $PATH'

# -----------------------------------------------------------------------------
# Call out to build .framework
#
if is_outermost_build; then
  echo "Building framework."
  . $FB_SDK_SCRIPT/build_framework.sh
fi

# -----------------------------------------------------------------------------
# Determine which samples to build.
#

# Certain subdirs of samples are not samples to be built, exclude them from the find query
FB_SAMPLES_EXCLUDED=(FBConnect.bundle Scrumptious)
for excluded in "${FB_SAMPLES_EXCLUDED[@]}"; do
  if [ -n "$FB_FIND_ARGS" ]; then
    FB_FIND_ARGS="$FB_FIND_ARGS -o"
  fi
  FB_FIND_ARGS="$FB_FIND_ARGS -name $excluded"
done

FB_FIND_SAMPLES_CMD="find $FB_SDK_SAMPLES -type d -depth 1 ! ( $FB_FIND_ARGS )"

# -----------------------------------------------------------------------------
# Build each sample
#
function xcode_build_sample() {
  cd $FB_SDK_SAMPLES/$1
  echo "Compiling '${1}' for platform '${2}' using configuration '${3}'."
  $XCODEBUILD \
    -alltargets \
    -sdk $2 \
    -configuration "${3}" \
    SYMROOT=$FB_SDK_BUILD \
    CURRENT_PROJECT_VERSION=$FB_SDK_VERSION_FULL \
    clean build \
    >>$FB_SDK_BUILD_LOG 2>&1 \
    || die "XCode build failed for sample '${1}' on platform: ${2}."
}

for sampledir in `$FB_FIND_SAMPLES_CMD`; do
  xcode_build_sample `basename $sampledir` "iphonesimulator" "$BUILDCONFIGURATION"
done

# -----------------------------------------------------------------------------
# Done
#
common_success
