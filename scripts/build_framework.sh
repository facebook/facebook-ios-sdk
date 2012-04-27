#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds the FBiOSSDK.framework that is distributed at
# https://github.com/facebook/facebook-ios-sdk/downloads/FBiOSSDK.framework.tgz

# our only parameter so far, valid arguments are: no-value, "Debug" and "Release" (default)
BUILDCONFIGURATION=${1:-Release}

. $(dirname $0)/common.sh
test -x "$XCODEBUILD" || die 'Could not find xcodebuild in $PATH'
test -x "$LIPO" || die 'Could not find lipo in $PATH'

FB_SDK_UNIVERSAL_BINARY=$FB_SDK_BUILD/${BUILDCONFIGURATION}-universal/$FB_SDK_BINARY_NAME

# -----------------------------------------------------------------------------
# Compile binaries 
#
test -d $FB_SDK_BUILD \
  || mkdir -p $FB_SDK_BUILD \
  || die "Could not create directory $FB_SDK_BUILD"

cd $FB_SDK_SRC
function xcode_build_target() {
  echo "Compiling for platform: ${1}."
  $XCODEBUILD \
    -target "facebook-ios-sdk" \
    -sdk $1 \
    -configuration "${2}" \
    SYMROOT=$FB_SDK_BUILD \
    CURRENT_PROJECT_VERSION=$FB_SDK_VERSION_FULL \
    clean build \
    >>$FB_SDK_BUILD_LOG 2>&1 \
    || die "XCode build failed for platform: ${1}."
}

xcode_build_target "iphonesimulator" "$BUILDCONFIGURATION"
xcode_build_target "iphoneos" "$BUILDCONFIGURATION"

# -----------------------------------------------------------------------------
# Merge lib files for different platforms into universal binary
#
echo "Building $FB_SDK_BINARY_NAME library using lipo."
mkdir -p $(dirname $FB_SDK_UNIVERSAL_BINARY)

$LIPO \
  -create \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphonesimulator/libfacebook_ios_sdk.a \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphoneos/libfacebook_ios_sdk.a \
  -output $FB_SDK_UNIVERSAL_BINARY \
  >>$FB_SDK_BUILD_LOG 2>&1 \
  || die "lipo failed - could not create universal static library"

# -----------------------------------------------------------------------------
# Build .framework out of binaries
#
echo "Building $FB_SDK_FRAMEWORK_NAME."

\rm -rf $FB_SDK_FRAMEWORK
mkdir $FB_SDK_FRAMEWORK \
  || die "Could not create directory $FB_SDK_FRAMEWORK"
mkdir $FB_SDK_FRAMEWORK/Versions
mkdir $FB_SDK_FRAMEWORK/Versions/A
mkdir $FB_SDK_FRAMEWORK/Versions/A/Headers
mkdir $FB_SDK_FRAMEWORK/Versions/A/DeprecatedHeaders
mkdir $FB_SDK_FRAMEWORK/Versions/A/Resources

\cp \
  $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphoneos/facebook-ios-sdk/*.h \
  $FB_SDK_FRAMEWORK/Versions/A/Headers \
  || die "Error building framework while copying SDK headers"
\cp \
  $FB_SDK_SRC/*.h \
  $FB_SDK_FRAMEWORK/Versions/A/DeprecatedHeaders \
  || die "Error building framework while copying deprecated SDK headers"
\cp \
  $FB_SDK_SRC/JSON/*.h \
  $FB_SDK_FRAMEWORK/Versions/A/DeprecatedHeaders \
  || die "Error building framework while copying deprecated JSON headers"
\cp \
  $FB_SDK_SRC/Framework/Resources/* \
  $FB_SDK_FRAMEWORK/Versions/A/Resources \
  || die "Error building framework while copying Resources"
\cp -r \
  $FB_SDK_SRC/*.bundle \
  $FB_SDK_FRAMEWORK/Versions/A/Resources \
  || die "Error building framework while copying bundle to Resources"
\cp \
  $FB_SDK_UNIVERSAL_BINARY \
  $FB_SDK_FRAMEWORK/Versions/A/FBiOSSDK \
  || die "Error building framework while copying FBiOSSDK"

# Current directory matters to ln.
cd $FB_SDK_FRAMEWORK
ln -s ./Versions/A/Headers ./Headers
ln -s ./Versions/A/Resources ./Resources
ln -s ./Versions/A/FBiOSSDK ./FBiOSSDK
cd $FB_SDK_FRAMEWORK/Versions
ln -s ./A ./Current

# -----------------------------------------------------------------------------
# Build docs 
#
echo "Building docs."

\headerdoc2html -o $FB_SDK_FRAMEWORK_DOCS $FB_SDK_FRAMEWORK/Headers >/dev/null 2>&1

# -----------------------------------------------------------------------------
# Done
#
common_success
