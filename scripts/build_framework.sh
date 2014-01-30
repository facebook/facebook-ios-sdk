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

# This script builds the FacebookSDK.framework that is distributed at
# https://github.com/facebook/facebook-ios-sdk/downloads/FacebookSDK.framework.tgz

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# process options, valid arguments -c [Debug|Release] -n 
BUILDCONFIGURATION=Debug
NOEXTRAS=1
while getopts ":ntc:" OPTNAME
do
  case "$OPTNAME" in
    "c")
      BUILDCONFIGURATION=$OPTARG
      ;;
    "n")
      NOEXTRAS=1
      ;;
    "t")
      NOEXTRAS=0
      ;;
    "?")
      echo "$0 -c [Debug|Release] -n"
      echo "       -c sets configuration (default=Debug)"
      echo "       -n no test run (default)"
      echo "       -t test run"
      die
      ;;
    ":")
      echo "Missing argument value for option $OPTARG"
      die
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options"
      die
      ;;
  esac
done

test -x "$XCODEBUILD" || die 'Could not find xcodebuild in $PATH'
test -x "$LIPO" || die 'Could not find lipo in $PATH'

FB_SDK_UNIVERSAL_BINARY=$FB_SDK_BUILD/${BUILDCONFIGURATION}-universal/$FB_SDK_BINARY_NAME

# -----------------------------------------------------------------------------

progress_message Building Framework.

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
    RUN_CLANG_STATIC_ANALYZER=NO \
    -target "facebook-ios-sdk" \
    -sdk $1 \
    -configuration "${2}" \
    SYMROOT=$FB_SDK_BUILD \
    clean build \
    || die "XCode build failed for platform: ${1}."
}

xcode_build_target "iphonesimulator" "${BUILDCONFIGURATION}"
xcode_build_target "iphoneos" "${BUILDCONFIGURATION}"
xcode_build_target "iphonesimulator" "${BUILDCONFIGURATION}64"
xcode_build_target "iphoneos" "${BUILDCONFIGURATION}64"

# -----------------------------------------------------------------------------
# Merge lib files for different platforms into universal binary
#
progress_message "Building $FB_SDK_BINARY_NAME library using lipo."

mkdir -p $(dirname $FB_SDK_UNIVERSAL_BINARY)

$LIPO \
  -create \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphonesimulator/libfacebook_ios_sdk.a \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphoneos/libfacebook_ios_sdk.a \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}64-iphonesimulator/libfacebook_ios_sdk.a \
    $FB_SDK_BUILD/${BUILDCONFIGURATION}64-iphoneos/libfacebook_ios_sdk.a \
  -output $FB_SDK_UNIVERSAL_BINARY \
  || die "lipo failed - could not create universal static library"

# -----------------------------------------------------------------------------
# Build .framework out of binaries
#
progress_message "Building $FB_SDK_FRAMEWORK_NAME."

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
  $FB_SDK_BUILD/${BUILDCONFIGURATION}-iphoneos/facebook-ios-sdk/*.h \
  $FB_SDK_FRAMEWORK/Versions/A/DeprecatedHeaders \
  || die "Error building framework while copying SDK headers to deprecated folder"
for HEADER in Legacy/FBConnect.h \
              Legacy/FBDialog.h \
              Legacy/FBFrictionlessRequestSettings.h \
              Legacy/FBLoginDialog.h \
              Legacy/Facebook.h \
              FBRequest.h \
              Legacy/FBSessionManualTokenCachingStrategy.h
do 
  \cp \
    $FB_SDK_SRC/$HEADER \
    $FB_SDK_FRAMEWORK/Versions/A/DeprecatedHeaders \
    || die "Error building framework while copying deprecated SDK headers"
done
\cp \
  $FB_SDK_SRC/Framework/Resources/* \
  $FB_SDK_FRAMEWORK/Versions/A/Resources \
  || die "Error building framework while copying Resources"
\cp -r \
  $FB_SDK_SRC/*.bundle \
  $FB_SDK_FRAMEWORK/Versions/A/Resources \
  || die "Error building framework while copying bundle to Resources"
\cp -r \
  $FB_SDK_SRC/*.bundle.README \
  $FB_SDK_FRAMEWORK/Versions/A/Resources \
  || die "Error building framework while copying README to Resources"
\cp \
  $FB_SDK_UNIVERSAL_BINARY \
  $FB_SDK_FRAMEWORK/Versions/A/FacebookSDK \
  || die "Error building framework while copying FacebookSDK"

# Current directory matters to ln.
cd $FB_SDK_FRAMEWORK
ln -s ./Versions/A/Headers ./Headers
ln -s ./Versions/A/Resources ./Resources
ln -s ./Versions/A/FacebookSDK ./FacebookSDK
cd $FB_SDK_FRAMEWORK/Versions
ln -s ./A ./Current

# -----------------------------------------------------------------------------
# Run unit tests 
#

if [ ${NOEXTRAS:-0} -eq  1 ];then
  progress_message "Skipping unit tests."
else
  progress_message "Running unit tests."
  cd $FB_SDK_SRC
  $FB_SDK_SCRIPT/run_tests.sh -c $BUILDCONFIGURATION facebook-ios-sdk-tests
fi

# -----------------------------------------------------------------------------
# Done
#

progress_message "Framework version info:" `perl -ne 'print "$1 " if (m/FB_IOS_SDK_MIGRATION_BUNDLE @(.+)$/ || m/FB_IOS_SDK_VERSION_STRING @(.+)$/);' $FB_SDK_SRC/Core/FBSDKVersion.h $FB_SDK_SRC/FacebookSDK.h` 
common_success
