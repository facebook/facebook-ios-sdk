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
# https://github.com/facebook/facebook-ios-sdk/downloads/FacebookSDK.framework.zip

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh
test -x "$PACKAGEBUILD" || die 'Could not find pkgbuild utility! Reinstall XCode?'
test -x "$PRODUCTBUILD" || die 'Could not find productbuild utility! Reinstall XCode?'
test -x "$PRODUCTSIGN" || die 'Could not find productsign utility! Reinstall XCode?'

FB_SDK_PGK_VERSION=$(sed -n 's/.*FB_IOS_SDK_VERSION_STRING @\"\(.*\)\"/\1/p' ${FB_SDK_SRC}/FacebookSDK.h)
# In case the hotfix value is zero, we drop the .0
FB_SDK_NORMALIZED_PGK_VERSION=$(echo ${FB_SDK_PGK_VERSION} | sed  's/^\([0-9]*\.[0-9]*\)\.0/\1/')

COMPONENT_FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK.pkg
FB_SDK_UNSIGNED_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_NORMALIZED_PGK_VERSION}-unsigned.pkg
FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_NORMALIZED_PGK_VERSION}.pkg

FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR=Documents/FacebookSDK
FB_SDK_BUILD_PACKAGE_FRAMEWORK=$FB_SDK_BUILD_PACKAGE/$FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR
FB_SDK_BUILD_PACKAGE_SAMPLES=$FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK/Samples
FB_SDK_BUILD_PACKAGE_DOCS=$FB_SDK_BUILD_PACKAGE/Library/Developer/Shared/Documentation/DocSets/$FB_SDK_DOCSET_NAME

CODE_SIGN_IDENTITY='Developer ID Installer: Facebook, Inc. (V9WTTPBFK9)'

# -----------------------------------------------------------------------------
# Call out to build prerequisites.
#
if is_outermost_build; then
    . $FB_SDK_SCRIPT/build_framework.sh -c Release
    . $FB_SDK_SCRIPT/build_documentation.sh
fi
echo Building Distribution.

# -----------------------------------------------------------------------------
# Build package directory structure
#
progress_message "Building package directory structure."
\rm -rf $FB_SDK_BUILD_PACKAGE
mkdir $FB_SDK_BUILD_PACKAGE \
  || die "Could not create directory $FB_SDK_BUILD_PACKAGE"
mkdir -p $FB_SDK_BUILD_PACKAGE_FRAMEWORK
mkdir -p $FB_SDK_BUILD_PACKAGE_SAMPLES
mkdir -p $FB_SDK_BUILD_PACKAGE_DOCS

\cp -R $FB_SDK_FRAMEWORK $FB_SDK_BUILD_PACKAGE_FRAMEWORK \
  || die "Could not copy $FB_SDK_FRAMEWORK"
\cp -R $FB_SDK_SAMPLES/ $FB_SDK_BUILD_PACKAGE_SAMPLES \
  || die "Could not copy $FB_SDK_BUILD_PACKAGE_SAMPLES"
\cp -R $FB_SDK_FRAMEWORK_DOCS/Contents $FB_SDK_BUILD_PACKAGE_DOCS \
  || die "Could not copy $$FB_SDK_FRAMEWORK_DOCS/Contents"
\cp $FB_SDK_ROOT/README.txt $FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK \
  || die "Could not copy README"
\cp $FB_SDK_ROOT/LICENSE $FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK \
  || die "Could not copy LICENSE"

# -----------------------------------------------------------------------------
# Fixup projects to point to the SDK framework
#
for fname in $(find $FB_SDK_BUILD_PACKAGE_SAMPLES -name "project.pbxproj" -print); do \
  sed "s|../../build|../../../../${FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR}|g" \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

# -----------------------------------------------------------------------------
# Build .pkg from package directory
#
progress_message "Building .pkg from package directory."
# First use pkgbuild to create component package
\rm -rf $COMPONENT_FB_SDK_PKG
$PACKAGEBUILD --root "$FB_SDK_BUILD/package" \
 		 --identifier "com.facebook.sdk.pkg" \
 		 --version $FB_SDK_NORMALIZED_PGK_VERSION   \
 		 $COMPONENT_FB_SDK_PKG || die "Failed to pkgbuild component package"

# Build product archive (note --resources should point to the folder containing the README)
\rm -rf $FB_SDK_UNSIGNED_PKG
$PRODUCTBUILD --distribution "$FB_SDK_SCRIPT/productbuild_distribution.xml" \
 			 --package-path $FB_SDK_BUILD \
			 --resources "$FB_SDK_BUILD/package/Documents/FacebookSDK/" \
			 $FB_SDK_UNSIGNED_PKG || die "Failed to productbuild the product archive"

progress_message "Signing package."
\rm -rf $FB_SDK_PKG
$PRODUCTSIGN -s "$CODE_SIGN_IDENTITY" $FB_SDK_UNSIGNED_PKG $FB_SDK_PKG \
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
