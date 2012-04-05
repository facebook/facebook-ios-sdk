#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script sets up a consistent environment for the other scripts in this directory.

# Set up paths for a specific clone of the SDK source
if [ $(dirname $0) != "$FB_SDK_SCRIPT" ]; then
  # ---------------------------------------------------------------------------
  # Versioning for the SDK
  #
  FB_SDK_VERSION_MAJOR=0
  FB_SDK_VERSION_MINOR=1
  test -n "$FB_SDK_VERSION_BUILD" || FB_SDK_VERSION_BUILD=$(date '+%Y%m%d')
  FB_SDK_VERSION=${FB_SDK_VERSION_MAJOR}.${FB_SDK_VERSION_MINOR}
  FB_SDK_VERSION_FULL=${FB_SDK_VERSION}.${FB_SDK_VERSION_BUILD}

  # ---------------------------------------------------------------------------
  # Set up paths
  #

  # The directory containing this script
  # We need to go there and use pwd so these are all absolute paths
  pushd $(dirname $0) >/dev/null
  FB_SDK_SCRIPT=$(pwd)
  popd >/dev/null

  # The root directory where the Facebook iOS SDK is cloned
  FB_SDK_ROOT=$(dirname $FB_SDK_SCRIPT)

  # Path to source files for Facebook SDK
  FB_SDK_SRC=$FB_SDK_ROOT/src

  # Path to template files for Facebook SDK
  FB_SDK_TEMPLATES=$FB_SDK_ROOT/templates

  # The directory where the target is built
  FB_SDK_BUILD=$FB_SDK_ROOT/build
  FB_SDK_BUILD_LOG=$FB_SDK_BUILD/build.log

  # The name of the Facebook iOS SDK
  FB_SDK_BINARY_NAME=FBiOSSDK

  # The name of the Facebook iOS SDK framework
  FB_SDK_FRAMEWORK_NAME=${FB_SDK_BINARY_NAME}.framework

  # The path to the built Facebook iOS SDK .framework
  FB_SDK_FRAMEWORK=$FB_SDK_BUILD/$FB_SDK_FRAMEWORK_NAME
fi

# Set up one-time variables
if [ -z $FB_SDK_ENV ]; then
  FB_SDK_ENV=env1
  FB_SDK_BUILD_DEPTH=0

  # Explains where the log is if this is the outermost build or if
  # we hit a fatal error.
  function show_summary() {
    test -r $FB_SDK_BUILD_LOG && echo "Build log is at $FB_SDK_BUILD_LOG"
  }

  # Calls show_summary if this is the outermost build.
  # Do not call outside common.sh.
  function pop_common() {
    FB_SDK_BUILD_DEPTH=$(($FB_SDK_BUILD_DEPTH - 1))
    test 0 -eq $FB_SDK_BUILD_DEPTH && show_summary
  }

  # Deletes any previous build log if this is the outermost build.
  # Do not call outside common.sh.
  function push_common() {
    test 0 -eq $FB_SDK_BUILD_DEPTH && \rm -f $FB_SDK_BUILD_LOG
    FB_SDK_BUILD_DEPTH=$(($FB_SDK_BUILD_DEPTH + 1))
  }

  # Any script that includes common.sh must call this once if it finishes
  # successfully.
  function common_success() { pop_common; }

  # Call this when there is an error.  This does not return.
  function die() {
    echo ""
    echo "FATAL: $*" >&2
    show_summary
    exit 1
  }

  # < XCode 4.3.1
  XCODEBUILD=/Developer/usr/bin/xcodebuild
  if [ ! -x XCODEBUILD ]; then
    # XCode from app store
    XCODEBUILD=/Applications/XCode.app/Contents/Developer/usr/bin/xcodebuild
  fi

  test -n "$XCODEBUILD"   || XCODEBUILD=$(which xcodebuild)
  test -n "$LIPO"         || LIPO=$(which lipo)
  test -n "$PACKAGEMAKER" || PACKAGEMAKER=$(which PackageMaker)

  # PackageMaker is not typically in $PATH
  test -n "$PACKAGEMAKER" \
    || PACKAGEMAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
fi

# Increment depth every time we . this file.  At the end of any script
# that .'s this file, there should be a call to common_finish to decrement.
push_common
