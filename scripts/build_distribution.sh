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

. "${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh"

# option s to skip build
SKIPBUILD=""
while getopts "s" OPTNAME
do
  case "$OPTNAME" in
    s)
      SKIPBUILD="YES"
      ;;
  esac
done

FB_SDK_ZIP=$FB_SDK_BUILD/FacebookSDKs-${FB_SDK_VERSION_SHORT}.zip


FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
FB_SDK_BUILD_PACKAGE_SAMPLES=$FB_SDK_BUILD_PACKAGE/Samples
FB_SDK_BUILD_PACKAGE_SCRIPTS=$FB_SDK_BUILD/Scripts
FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER=$FB_SDK_BUILD_PACKAGE/DocSets/

# -----------------------------------------------------------------------------gi
# Build package directory structure
#
progress_message "Building package directory structure."
\rm -rf "$FB_SDK_BUILD_PACKAGE" "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
mkdir -p "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not create directory $FB_SDK_BUILD_PACKAGE"
mkdir -p "$FB_SDK_BUILD_PACKAGE_SAMPLES"
mkdir -p "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
mkdir -p "$FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER"

# -----------------------------------------------------------------------------
# Call out to build prerequisites.
#
if is_outermost_build; then
  if [ -z $SKIPBUILD ]; then
    . "$FB_SDK_SCRIPT/build_framework.sh" -c Release
  fi
fi
echo Building Distribution.

# -----------------------------------------------------------------------------
# Install required dependencies
#
(gem list naturally -i > /dev/null) || die "Run 'gem install naturally' first"
(gem list xcpretty -i > /dev/null) || die "Run 'gem install xcpretty' first"
(gem list rake -i > /dev/null) || die "Run 'gem install rake' first"

# -----------------------------------------------------------------------------
# Copy over stuff
#
\cp -R "$FB_SDK_BUILD"/FBSDKCoreKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKCoreKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKLoginKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKLoginKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKShareKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKShareKit.framework"
\cp -R "$FB_SDK_BUILD"/Bolts.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy Bolts.framework"
\cp -R $"$FB_SDK_ROOT"/FacebookSDKStrings.bundle "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FacebookSDKStrings.bundle"
for SAMPLE in Configurations Iconicus RPSSample Scrumptious ShareIt SwitchUserSample; do
  \rsync -avmc --exclude "${SAMPLE}.xcworkspace" "$FB_SDK_SAMPLES/$SAMPLE" "$FB_SDK_BUILD_PACKAGE_SAMPLES" \
    || die "Could not copy $SAMPLE"
done
\cp "$FB_SDK_ROOT/README.txt" "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy README"
\cp "$FB_SDK_ROOT/LICENSE" "$FB_SDK_BUILD_PACKAGE"/LICENSE.txt \
  || die "Could not copy LICENSE"


# -----------------------------------------------------------------------------
# Fixup projects to point to the SDK framework
#
for fname in $(find "$FB_SDK_BUILD_PACKAGE_SAMPLES" -name "Project.xcconfig" -print); do \
  sed 's|\(\.\.\(/\.\.\)*\)/build|\1|g;s|\.\.\(/\.\.\)*/Bolts-IOS/build/ios||g' \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done
for fname in $(find "$FB_SDK_BUILD_PACKAGE_SAMPLES" -name "project.pbxproj" -print); do \
  sed 's|\(path[[:space:]]*=[[:space:]]*\.\.\(/\.\.\)*\)/build|\1|g' \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

# -----------------------------------------------------------------------------
# Build AKFAccountKit framework
#
if [ -z $SKIPBUILD ]; then
  ("$XCTOOL" -project "${FB_SDK_ROOT}"/AccountKit/AccountKit.xcodeproj -scheme "AccountKit-Universal" -configuration Release clean build) || die "Failed to build account kit"
fi
\cp -R "$FB_SDK_BUILD"/AccountKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy AccountKit.framework"
\cp -R "$FB_SDK_BUILD"/AccountKitStrings.bundle "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy AccountKitStrings.bundle"

# -----------------------------------------------------------------------------
# Build FBNotifications framework
#

# Build stuff
\rake -f "$FB_SDK_ROOT/FBNotifications/iOS/Rakefile" package:frameworks || die "Could not build FBNotifications.framework"
\unzip "$FB_SDK_ROOT/FBNotifications/iOS/build/release/FBNotifications-iOS.zip" -d $FB_SDK_BUILD
\cp -R "$FB_SDK_BUILD"/FBNotifications.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBNotifications.framework"

# -----------------------------------------------------------------------------
# Build FBAudienceNetwork framework
#

if [ -z $SKIPBUILD ]; then
  ("$XCTOOL" -workspace "${FB_SDK_ROOT}"/ads/src/FBAudienceNetwork.xcworkspace -scheme "BuildAll-Universal" -configuration Release clean build) || die "Failed to build FBAudienceNetwork"
fi
FBAN_SAMPLES=$FB_SDK_BUILD_PACKAGE/Samples/FBAudienceNetwork
\cp -R "$FB_SDK_ROOT"/ads/build/FBAudienceNetwork.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBAudienceNetwork.framework"
\mkdir -p "$FB_SDK_BUILD_PACKAGE/Samples/FBAudienceNetwork"
\cp -R "$FB_SDK_ROOT"/ads/samples/ $FBAN_SAMPLES \
  || die "Could not copy FBAudienceNetwork samples"
# Fix up samples
for fname in $(find "$FBAN_SAMPLES" -name "project.pbxproj" -print); do \
  sed "s|../../build|../../../|g;" \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

# Fix up samples
for fname in $(find "$FBADSDK_SAMPLES" -name "project.pbxproj" -print); do \
  sed "s|../../build|../../../|g;s|../../../../ads/build|../../../|g;" \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

# -----------------------------------------------------------------------------
# Build Messenger Kit
#
if [ -z $SKIPBUILD ]; then
  ("$XCTOOL" -project "${FB_SDK_ROOT}"/FBSDKMessengerShareKit/FBSDKMessengerShareKit.xcodeproj -scheme "FBSDKMessengerShareKit-universal" -configuration Release clean build) || die "Failed to build messenger kit"
fi
\cp -R "$FB_SDK_BUILD"/FBSDKMessengerShareKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKMessengerShareKit.framework"

# -----------------------------------------------------------------------------
# Build docs
#
if [ -z $SKIPBUILD ]; then
  . "$FB_SDK_SCRIPT/build_documentation.sh"
fi
\ls -d "$FB_SDK_BUILD"/*.docset | xargs -I {} cp -R {} $FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER \
  || die "Could not copy docsets"
\cp "$FB_SDK_SCRIPT/install_docsets.sh" $FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER \
  || die "Could not copy install_docset"

# -----------------------------------------------------------------------------
# Build .zip from package directory
#
progress_message "Building .zip from package directory."
(
  cd $FB_SDK_BUILD
  ditto -ck --sequesterRsrc $FB_SDK_BUILD_PACKAGE $FB_SDK_ZIP
)

# -----------------------------------------------------------------------------
# Done
#
progress_message "Successfully built SDK zip: $FB_SDK_ZIP"
common_success
