#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds the FBiOSSDK.framework that is distributed at
# https://github.com/facebook/facebook-ios-sdk/downloads/FBiOSSDK.framework.zip

. $(dirname $0)/common.sh
test -x "$PACKAGEMAKER" || die 'Could not find packagemaker in $PATH'

FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_VERSION_FULL}.pkg
FB_SDK_FRAMEWORK_TGZ=${FB_SDK_FRAMEWORK}-${FB_SDK_VERSION_FULL}.tgz

FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
FB_SDK_BUILD_PACKAGE_TEMPLATES=$FB_SDK_BUILD_PACKAGE/Library/Developer/XCode/Templates/FacebookSDK
FB_SDK_BUILD_PACKAGE_FRAMEWORK=$FB_SDK_BUILD_PACKAGE/Library/Developer/FacebookSDK

# -----------------------------------------------------------------------------
# Call out to build .framework
#
echo "Building framework."
. $FB_SDK_SCRIPT/build_framework.sh

# -----------------------------------------------------------------------------
# Compress framework for standalone distribution
#
echo "Compressing framework for standalone distribution."
\rm -rf ${FB_SDK_FRAMEWORK_TGZ}

# Current directory matters to tar.
cd $FB_SDK_BUILD || die "Could not cd to $FB_SDK_BUILD"
tar -c -z $FB_SDK_FRAMEWORK_NAME >  $FB_SDK_FRAMEWORK_TGZ \
  || die "tar failed to create ${FB_SDK_FRAMEWORK_NAME}.tgz"

# -----------------------------------------------------------------------------
# Build package directory structure
#
echo "Building package directory structure."
\rm -rf $FB_SDK_BUILD_PACKAGE
mkdir $FB_SDK_BUILD_PACKAGE \
  || die "Could not create directory $FB_SDK_BUILD_PACKAGE"
mkdir -p $FB_SDK_BUILD_PACKAGE_TEMPLATES
mkdir -p $FB_SDK_BUILD_PACKAGE_FRAMEWORK

\cp -r $FB_SDK_TEMPLATES/* $FB_SDK_BUILD_PACKAGE_TEMPLATES \
  || die "Could not copy $FB_SDK_TEMPLATES"
\cp -R $FB_SDK_FRAMEWORK $FB_SDK_BUILD_PACKAGE_FRAMEWORK \
  || die "Could not copy $FB_SDK_FRAMEWORK"

# -----------------------------------------------------------------------------
# Build .pkg from package directory
#
echo "Building .pkg from package directory."
\rm -rf $FB_SDK_PKG
$PACKAGEMAKER \
  --doc $FB_SDK_SRC/Package/FBiOSSDK.pmdoc \
  --domain user \
  --target 10.5 \
  --version $FB_SDK_VERSION \
  --out $FB_SDK_PKG \
  --title 'Facebook iOS SDK' \
  || die "PackageMaker reported error"

# -----------------------------------------------------------------------------
# Done
#
echo "Successfully built SDK distribution:"
echo "  $FB_SDK_FRAMEWORK_TGZ"
echo "  $FB_SDK_PKG"
common_success
