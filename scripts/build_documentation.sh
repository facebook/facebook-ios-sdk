#!/bin/sh
# Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Developer Principles and Policies
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# This script builds the API documentation from source-level comments.
# This script requires appledoc be installed: https://github.com/tomaz/appledoc

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# option s to skip build
SKIPBUILD=""
while getopts "s:" OPTNAME
do
  case "$OPTNAME" in
    s)
      SKIPBUILD="YES"
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Build pre-requisites
#
if is_outermost_build; then
  if [ -z SKIPBUILD ]; then
    . "$FB_SDK_SCRIPT/build_framework.sh" -n
  fi
fi

APPLEDOC_PATH="$FB_SDK_BUILD"/appledoc
progress_message "$APPLEDOC_PATH"

if [ ! -f "$APPLEDOC_PATH" ]; then
  # appledoc is currently being refactored for v3, which will be free from GC.
  # In the meantime, use a pre-compiled binary if it is dropped into
  # vendor/appledoc_bin/
  VENDOR_APPLEDOC_PATH="$FB_SDK_ROOT"/vendor/appledoc_bin/appledoc
  if [ -f "$VENDOR_APPLEDOC_PATH" ]; then
    cp "$VENDOR_APPLEDOC_PATH" "$APPLEDOC_PATH"
  fi
fi

if [ ! -f "$APPLEDOC_PATH" ]; then
  progress_message Building appledoc
  pushd "$FB_SDK_ROOT"/vendor/appledoc/ >/dev/null
  ./install-appledoc.sh -b "$FB_SDK_BUILD" || die 'Could not build appledoc'
  popd >/dev/null
fi

# -----------------------------------------------------------------------------
# Build docs
#
progress_message Building Documentation.
test -d "$FB_SDK_BUILD" \
  || mkdir -p "$FB_SDK_BUILD" \
  || die "Could not create directory $FB_SDK_BUILD"

cd "$FB_SDK_ROOT"

rm -rf "$FB_SDK_FRAMEWORK_DOCS"

DOCSET="$FB_SDK_BUILD"/docset.build
rm -rf "$DOCSET"

hash "$APPLEDOC_PATH" &>/dev/null
if [ "$?" -eq "0" ]; then
    APPLEDOC_DOCSET_NAME="Facebook SDK $FB_SDK_VERSION_SHORT for iOS"
    "$APPLEDOC_PATH" --project-name "$APPLEDOC_DOCSET_NAME" \
	--project-company "Facebook" \
	--company-id "com.facebook" \
  --output "$DOCSET" \
	--preprocess-headerdoc \
	--docset-bundle-filename "$FB_SDK_DOCSET_NAME" \
	--docset-feed-name "$APPLEDOC_DOCSET_NAME" \
	--docset-install-path "$FB_SDK_BUILD" \
	--exit-threshold 2 \
	--no-install-docset \
	--search-undocumented-doc \
	--keep-undocumented-members \
	--keep-undocumented-objects \
	--explicit-crossref \
	"$FB_SDK_BUILD/FBSDKCoreKit.framework/Headers" \
  "$FB_SDK_BUILD/FBSDKLoginKit.framework/Headers" \
  "$FB_SDK_BUILD/FBSDKShareKit.framework/Headers" \
    || die 'appledoc execution failed'
else
    die "appledoc not installed, unable to build documentation"
fi

# -----------------------------------------------------------------------------
# Done
#
common_success
