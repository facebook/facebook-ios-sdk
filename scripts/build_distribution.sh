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
while getopts "s:" OPTNAME
do
  case "$OPTNAME" in
    s)
      SKIPBUILD="YES"
      ;;
  esac
done

test -x "$PACKAGEBUILD" || die 'Could not find pkgbuild utility! Reinstall XCode?'
test -x "$PRODUCTBUILD" || die 'Could not find productbuild utility! Reinstall XCode?'
test -x "$PRODUCTSIGN" || die 'Could not find productsign utility! Reinstall XCode?'

COMPONENT_FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK.pkg
FB_SDK_UNSIGNED_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_VERSION_SHORT}-unsigned.pkg
FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_VERSION_SHORT}.pkg

FB_SDK_BUILD_ROOT_DIR=Documents/FacebookSDK

FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR=$FB_SDK_BUILD_ROOT_DIR
FB_SDK_BUILD_PACKAGE_FRAMEWORK=$FB_SDK_BUILD_PACKAGE/$FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR
FB_SDK_BUILD_PACKAGE_SAMPLES=$FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK/Samples
FB_SDK_BUILD_PACKAGE_SCRIPTS=$FB_SDK_BUILD/Scripts
FB_SDK_BUILD_PACKAGE_DOCS=$FB_SDK_BUILD_PACKAGE/Library/Developer/Shared/Documentation/DocSets/$FB_SDK_DOCSET_NAME

BOLTS_BUILD_PACKAGE_FRAMEWORK_SUBDIR=$FB_SDK_BUILD_ROOT_DIR
BOLTS_BUILD_PACKAGE_FRAMEWORK=$FB_SDK_BUILD_PACKAGE/$BOLTS_BUILD_PACKAGE_FRAMEWORK_SUBDIR

CODE_SIGN_IDENTITY='Developer ID Installer: Facebook, Inc. (V9WTTPBFK9)'

# -----------------------------------------------------------------------------
# Call out to build prerequisites.
#
if is_outermost_build; then
  if [ -z $SKIPBUILD ]; then
    . "$FB_SDK_SCRIPT/build_framework.sh" -c Release
    . "$FB_SDK_SCRIPT/build_documentation.sh"
  fi
fi
echo Building Distribution.

# -----------------------------------------------------------------------------gi
# Build package directory structure
#
progress_message "Building package directory structure."
\rm -rf "$FB_SDK_BUILD_PACKAGE" "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
mkdir "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not create directory $FB_SDK_BUILD_PACKAGE"
mkdir -p "$FB_SDK_BUILD_PACKAGE_FRAMEWORK"
mkdir -p "$FB_SDK_BUILD_PACKAGE_SAMPLES"
mkdir -p "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
mkdir -p "$FB_SDK_BUILD_PACKAGE_DOCS"

\cp -R "$FB_SDK_BUILD"/FBSDKCoreKit.framework "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy FBSDKCoreKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKLoginKit.framework "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy FBSDKLoginKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKShareKit.framework "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy FBSDKShareKit.framework"
\cp -R "$FB_SDK_BUILD"/Bolts.framework "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy Bolts.framework"
\cp $"$FB_SDK_ROOT"/FacebookSDK.strings "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy FacebookSDK.strings"
\cp -R "$FB_SDK_SAMPLES/" "$FB_SDK_BUILD_PACKAGE_SAMPLES" \
  || die "Could not copy $FB_SDK_BUILD_PACKAGE_SAMPLES"
\cp -R "$FB_SDK_SCRIPT/package/preinstall" "$FB_SDK_BUILD_PACKAGE_SCRIPTS" \
  || die "Could not copy $FB_SDK_SCRIPT/package/preflight"
\cp -R "$FB_SDK_FRAMEWORK_DOCS/Contents" "$FB_SDK_BUILD_PACKAGE_DOCS" \
  || die "Could not copy $$FB_SDK_FRAMEWORK_DOCS/Contents"
\cp "$FB_SDK_ROOT/README.txt" "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy README"
\cp "$FB_SDK_ROOT/LICENSE" "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy LICENSE"

# -----------------------------------------------------------------------------
# Fixup projects to point to the SDK framework
#
for fname in $(find "$FB_SDK_BUILD_PACKAGE_SAMPLES" -name "project.pbxproj" -print); do \
  sed "s|../../build|../../../../${FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR}|g;s|../../Bolts-IOS/build/ios|../../../../${BOLTS_BUILD_PACKAGE_FRAMEWORK_SUBDIR}|g" \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

# -----------------------------------------------------------------------------
# Build FBAudienceNetwork framework
#
test -f $FB_ADS_FRAMEWORK_SCRIPT/build_distribution.sh \
  && $FB_ADS_FRAMEWORK_SCRIPT/build_distribution.sh

# -----------------------------------------------------------------------------
# Build Messenger Kit
#
("$XCTOOL" -project "${FB_SDK_ROOT}"/FBSDKMessengerShareKit/FBSDKMessengerShareKit.xcodeproj -scheme "FBSDKMessengerShareKit-universal" -configuration Release clean build) || die "Failed to build messenger kit"
\cp -R "$FB_SDK_BUILD"/FBSDKMessengerShareKit.framework "$FB_SDK_BUILD_PACKAGE_FRAMEWORK" \
  || die "Could not copy FBSDKMessengerShareKit.framework"

# -----------------------------------------------------------------------------
# Build .pkg from package directory
#
progress_message "Building .pkg from package directory."
# First use pkgbuild to create component package
\rm -rf "$COMPONENT_FB_SDK_PKG"
$PACKAGEBUILD --root "$FB_SDK_BUILD_PACKAGE" \
    --identifier "com.facebook.sdk.pkg" \
    --scripts "$FB_SDK_BUILD_PACKAGE_SCRIPTS" \
    --version $FB_SDK_VERSION_SHORT   \
    "$COMPONENT_FB_SDK_PKG" || die "Failed to pkgbuild component package"

# Build product archive (note --resources should point to the folder containing the README)
\rm -rf "$FB_SDK_UNSIGNED_PKG"
$PRODUCTBUILD --distribution "$FB_SDK_SCRIPT/package/productbuild_distribution.xml" \
    --package-path $FB_SDK_BUILD \
    --resources "$FB_SDK_BUILD/package/Documents/FacebookSDK/" \
    "$FB_SDK_UNSIGNED_PKG" || die "Failed to productbuild the product archive"

progress_message "Signing package."
\rm -rf "$FB_SDK_PKG"
"$PRODUCTSIGN" -s "$CODE_SIGN_IDENTITY" "$FB_SDK_UNSIGNED_PKG" "$FB_SDK_PKG" \
 || FAILED_TO_SIGN=1

if [ "$FAILED_TO_SIGN" == "1" ] ; then
  progress_message "Failed to sign the package. See https://our.intern.facebook.com/intern/wiki/index.php/Platform/Mobile/ContributingToMobileSDKs#Building_the_iOS_Distribution_with_PackageMaker"
fi

# -----------------------------------------------------------------------------
# Done
#
progress_message "Successfully built SDK distribution:"
if [ "$FAILED_TO_SIGN" != "1" ] ; then
  progress_message "  Signed : $FB_SDK_PKG"
fi
progress_message "  Unsigned : $FB_SDK_UNSIGNED_PKG"
common_success
