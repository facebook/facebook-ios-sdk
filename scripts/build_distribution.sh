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

COMMON_ARCHS="arm64 armv7 i386 x86_64"

check_binary_has_architectures() {
	local BINARY=$1
	local VALID_ARCHS=$2
	local SORTED_ARCHS
  SORTED_ARCHS=$(lipo -info "$BINARY" | cut -d: -f3 | xargs -n1 | sort | xargs)

	if [ "$SORTED_ARCHS" != "$VALID_ARCHS" ] ; then
		echo "ERROR: Invalid Architectures for $1. Expected $VALID_ARCHS   Received: $SORTED_ARCHS";
    exit 1
	fi
}

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

# -----------------------------------------------------------------------------
# Install required dependencies
#
(gem list naturally -i > /dev/null) || die "Run 'gem install naturally' first"
(gem list xcpretty -i > /dev/null) || die "Run 'gem install xcpretty' first"
(gem list rake -i > /dev/null) || die "Run 'gem install rake' first"

# -----------------------------------------------------------------------------
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
# Copy over stuff
#
\cp -R "$FB_SDK_BUILD"/FBSDKCoreKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKCoreKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKLoginKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKLoginKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKShareKit.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBSDKShareKit.framework"
\cp -R "$FB_SDK_BUILD"/FBSDKPlacesKit.framework "$FB_SDK_BUILD_PACKAGE" \
|| die "Could not copy FBSDKPlacesKit.framework"
\cp -R "$FB_SDK_BUILD"/Bolts.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy Bolts.framework"
\cp -R $"$FB_SDK_ROOT"/FacebookSDKStrings.bundle "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FacebookSDKStrings.bundle"
for SAMPLE in Configurations Iconicus RPSSample Scrumptious ShareIt SwitchUserSample FBSDKPlacesSample; do
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
  (xcodebuild -project "${FB_SDK_ROOT}"/AccountKit/AccountKit.xcodeproj -scheme "AccountKit-Universal" -configuration Release clean build) || die "Failed to build account kit"
fi
check_binary_has_architectures "$FB_SDK_BUILD"/AccountKit.framework/AccountKit "$COMMON_ARCHS";
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
  (xcodebuild -workspace "${FB_SDK_ROOT}"/ads/src/FBAudienceNetwork.xcworkspace -scheme "BuildAll-Universal" -configuration Release clean build) || die "Failed to build FBAudienceNetwork"
fi
FBAN_SAMPLES=$FB_SDK_BUILD_PACKAGE/Samples/FBAudienceNetwork
\rsync -avmc "$FB_SDK_ROOT"/ads/build/FBAudienceNetwork.framework "$FB_SDK_BUILD_PACKAGE" \
  || die "Could not copy FBAudienceNetwork.framework"
\mkdir -p "$FB_SDK_BUILD_PACKAGE/Samples/FBAudienceNetwork"
\rsync -avmc "$FB_SDK_ROOT"/ads/samples/ "$FBAN_SAMPLES" \
  || die "Could not copy FBAudienceNetwork samples"
# Fix up samples
for fname in $(find "$FBAN_SAMPLES" -name "project.pbxproj" -print); do \
  sed 's|"\\"\$(SRCROOT)/\.\./\.\./\.\./build\\"",||g;s|\.\./\.\./\.\./build||g;' \
    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
done

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

LANG=C

# Remove all BUCK related files from AN samples
find "$FBAN_SAMPLES" -name "BUCK" -delete
find "$FBAN_SAMPLES" -name "build-buck.sh" -delete
find "$FBAN_SAMPLES" -name "Buck-Info.plist" -delete
find "$FBAN_SAMPLES" -name "Entitlements" -type d -exec rm -r "{}" \;

find "$FBAN_SAMPLES" -name "entitlements.plist" -delete

find "$FBAN_SAMPLES" -name "Info.plist" -exec perl -p -i -0777 -e 's/\s*<key>CFBundleURLTypes<\/key>\s*<array>\s*<dict>\s*<key>CFBundleURLSchemes<\/key>\s*<array>\s*<string>fb\d*<\/string>\s*<\/array>\s*<\/dict>\s*<\/array>\s*<key>FacebookAppID<\/key>\s*<string>\d*<\/string>\s*<key>FacebookDisplayName<\/key>\s*<string>.*<\/string>\s*<key>LSApplicationQueriesSchemes<\/key>\s*<array>\s*<string>fbapi<\/string>\s*<string>fb-messenger-api<\/string>\s*<string>fbauth2<\/string>\s*<string>fbshareextension<\/string>\s*<\/array>\n//g' {} \;
find "$FBAN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e 's/\n\s*com\.apple\.Keychain = {\s*enabled = 1;\s*};//gms' {} \;
find "$FBAN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e '/NativeAdSample.entitlements/d' {} \;
find "$FBAN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e '/AdUnitsSample.entitlements/d' {} \;
find "$FBAN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e 's/^\s*<FileRef\n\s*location = "group:\.\.\/\.\.\/FBSDKCoreKit\/FBSDKCoreKit\.xcodeproj">\n\s*<\/FileRef>\n//gms' {} \;

find "$FBAN_SAMPLES" -type f -exec sed -i '' -E -e "/fbLoginButton/d" {} \;
find "$FBAN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKCoreKit/d" {} \;
find "$FBAN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKLogin/d" {} \;
find "$FBAN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKApplicationDelegate/d" {} \;
find "$FBAN_SAMPLES" -type f -exec  perl -p -i -0777 -e 's/\n\/\/ START REMOVED AT DISTRIBUTION BUILD TIME.*?\/\/ END REMOVED AT DISTRIBUTION BUILD TIME\n//gms' {} \;

# -----------------------------------------------------------------------------
# Build Messenger Kit
#
if [ -z $SKIPBUILD ]; then
  (xcodebuild -project "${FB_SDK_ROOT}"/FBSDKMessengerShareKit/FBSDKMessengerShareKit.xcodeproj -scheme "FBSDKMessengerShareKit-universal" -configuration Release clean build) || die "Failed to build messenger kit"
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
