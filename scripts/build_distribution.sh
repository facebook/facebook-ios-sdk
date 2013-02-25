#!/bin/sh
#
# Copyright 2012 Facebook
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
test -x "$PACKAGEMAKER" || die 'Could not find packagemaker in $PATH'

FB_SDK_PGK_VERSION=$(sed -n 's/.*FB_IOS_SDK_VERSION_STRING @\"\(.*\)\"/\1/p' ${FB_SDK_SRC}/FBSDKVersion.h)
# In case the hotfix value is zero, we drop the .0
FB_SDK_NORMALIZED_PGK_VERSION=$(echo ${FB_SDK_PGK_VERSION} | sed  's/^\([0-9]*\.[0-9]*\)\.0/\1/')

FB_SDK_PKG=$FB_SDK_BUILD/FacebookSDK-${FB_SDK_NORMALIZED_PGK_VERSION}.pkg
FB_SDK_FRAMEWORK_TGZ=${FB_SDK_FRAMEWORK}-${FB_SDK_NORMALIZED_PGK_VERSION}.tgz

FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR=Documents/FacebookSDK
FB_SDK_BUILD_PACKAGE_FRAMEWORK=$FB_SDK_BUILD_PACKAGE/$FB_SDK_BUILD_PACKAGE_FRAMEWORK_SUBDIR
FB_SDK_BUILD_PACKAGE_SAMPLES=$FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK/Samples
FB_SDK_BUILD_PACKAGE_DOCS=$FB_SDK_BUILD_PACKAGE/Library/Developer/Shared/Documentation/DocSets/$FB_SDK_DOCSET_NAME

# -----------------------------------------------------------------------------
# Call out to build prerequisites.
#
if is_outermost_build; then
    . $FB_SDK_SCRIPT/build_framework.sh
    . $FB_SDK_SCRIPT/build_documentation.sh
fi
echo Building Distribution.

# -----------------------------------------------------------------------------
# Compress framework for standalone distribution
#
progress_message "Compressing framework for standalone distribution."
\rm -rf ${FB_SDK_FRAMEWORK_TGZ}

# Current directory matters to tar.
cd $FB_SDK_BUILD || die "Could not cd to $FB_SDK_BUILD"
tar -c -z $FB_SDK_FRAMEWORK_NAME >  $FB_SDK_FRAMEWORK_TGZ \
  || die "tar failed to create ${FB_SDK_FRAMEWORK_NAME}.tgz"

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
\cp -R $FB_SDK_FRAMEWORK_DOCS/docset/Contents $FB_SDK_BUILD_PACKAGE_DOCS \
  || die "Could not copy $$FB_SDK_FRAMEWORK_DOCS/docset/Contents"
\cp $FB_SDK_ROOT/README $FB_SDK_BUILD_PACKAGE/Documents/FacebookSDK \
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
\rm -rf $FB_SDK_PKG
$PACKAGEMAKER \
  --doc $FB_SDK_SRC/Package/FacebookSDK.pmdoc \
  --domain user \
  --target 10.5 \
  --version $FB_SDK_VERSION \
  --out $FB_SDK_PKG \
  --title 'Facebook SDK 3.2 for iOS' \
  || die "PackageMaker reported error"

# -----------------------------------------------------------------------------
# Done
#
progress_message "Successfully built SDK distribution:"
progress_message "  $FB_SDK_FRAMEWORK_TGZ"
progress_message "  $FB_SDK_PKG"
common_success
