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
. "$FB_AD_SDK_SCRIPT/common.sh"

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

check_binary_has_bitcode() {
	# static lib only
	local BINARY=$1
	local BITCODE_SCRIPT="${FB_AD_SDK_ROOT}"/scripts/bitcodesize.rb

	local ISSUES=$("$BITCODE_SCRIPT" "$BINARY")

	if [ ! -z "$ISSUES" ] ; then
		echo "$ISSUES"
		echo "ERROR: Bitcode not found or weirdly small for $1. Check logs above.";
    	exit 1
    fi
}

# valid arguments -s -p [AudienceNetwork|FacebookSDK]
# option s to skip build
SKIPBUILD=""
while getopts "sp:" OPTNAME
do
  case "$OPTNAME" in
    s)
      SKIPBUILD="YES"
      ;;
		p)
			PACKAGE=$OPTARG
			;;
  esac
done

if [ -z $PACKAGE ]; then
	PACKAGE=$PACAKAGE_FACEBOOK
fi

# -----------------------------------------------------------------------------
# Install required dependencies
#
(gem list naturally -i > /dev/null) || die "Run 'gem install naturally' first"
(gem list xcpretty -i > /dev/null) || die "Run 'gem install xcpretty' first"
(gem list rake -i > /dev/null) || die "Run 'gem install rake' first"

# -----------------------------------------------------------------------------
# Build FBAudienceNetwork framework
#
if [ "$PACKAGE" == "$PACAKAGE_AN" ]; then

	# refuse to build with unclean state
	repository_unclean=$(hg status -i ios-sdk/ | grep -v .DS_Store)
	if [ "$repository_unclean" ]; then
		echo "Detected unclean repository state:"
		echo "$repository_unclean"
		die "Please run 'hg purge --all' before building"
	fi

	AN_ZIP=$FB_AD_SDK_BUILD/$FB_AD_SDK_BINARY_NAME-$FB_AD_SDK_VERSION.zip
	AN_BUILD_PACKAGE=$FB_AD_SDK_BUILD/package
	AN_SAMPLES=$AN_BUILD_PACKAGE/Samples/FBAudienceNetwork
	AN_STATIC_REPORT="${FB_SDK_ROOT}"/FBAudienceNetworkFramework.out
	AN_DYNAMIC_REPORT="${FB_SDK_ROOT}"/FBAudienceNetworkDynamicFramework.out

	if [ -z $SKIPBUILD ]; then
		buck build //ios-sdk/ads/src/FBAudienceNetwork:FBAudienceNetworkFramework --build-report "$AN_STATIC_REPORT" || die "Failed to build FBAudienceNetwork"
		buck build //ios-sdk/ads/src/FBAudienceNetwork:FBAudienceNetworkDynamicFramework --build-report "$AN_DYNAMIC_REPORT" || die "Failed to build FBAudienceNetworkDynamicFramework"

		AN_BUCK_STATIC_OUTPUT="${FB_SDK_ROOT}/../"$(cat "$AN_STATIC_REPORT" | grep -E -m 1 '"output"' | awk -F '"' '{ print $4 }')
		AN_BUCK_DYNAMIC_OUTPUT="${FB_SDK_ROOT}/../"$(cat "$AN_DYNAMIC_REPORT" | grep -E -m 1 '"output"' | awk -F '"' '{ print $4 }')

		rsync -avmc "$AN_BUCK_STATIC_OUTPUT" "$FB_AD_SDK_BUILD" \
		  || die "Could not copy FBAudienceNetwork.framework"
		rsync -avmc "$AN_BUCK_DYNAMIC_OUTPUT" "$FB_AD_SDK_BUILD" \
		  || die "Could not copy FBAudienceNetworkDynamicFramework.framework"

		rm "$AN_STATIC_REPORT"
		rm "$AN_DYNAMIC_REPORT"
	fi

	rsync -avmc "$FB_AD_SDK_BUILD"/FBAudienceNetwork.framework "$AN_BUILD_PACKAGE" \
	  || die "Could not copy FBAudienceNetwork.framework"
	rsync -avmc "$FB_AD_SDK_BUILD"/FBAudienceNetworkDynamicFramework.framework "$AN_BUILD_PACKAGE" \
	  || die "Could not copy FBAudienceNetworkDynamicFramework.framework"
	mkdir -p "$AN_BUILD_PACKAGE/Samples/FBAudienceNetwork"
	rsync -avmc "$FB_SDK_ROOT"/ads/samples/ "$AN_SAMPLES" \
	  || die "Could not copy FBAudienceNetwork samples"
	# Fix up samples
	for fname in $(find "$AN_SAMPLES" -name "project.pbxproj" -print); do \
	  sed 's|"\\"\$(SRCROOT)/\.\./\.\./\.\./build\\"",||g;s|\.\./\.\./\.\./build||g;' \
	    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
	done

	check_binary_has_architectures "$FB_AD_SDK_BUILD"/FBAudienceNetwork.framework/FBAudienceNetwork "$COMMON_ARCHS";
	check_binary_has_architectures "$FB_AD_SDK_BUILD"/FBAudienceNetworkDynamicFramework.framework/FBAudienceNetworkDynamicFramework "$COMMON_ARCHS";

	check_binary_has_bitcode "$FB_AD_SDK_BUILD"/FBAudienceNetwork.framework/FBAudienceNetwork

	# Fix up samples
	for fname in $(find "$AN_SAMPLES" -name "project.pbxproj" -print); do \
	  sed "s|../../build|../../../|g;" \
	    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
	done
	for fname in $(find "$AN_SAMPLES" -name "*-PUBLIC.xcodeproj" -print); do \
	  newfname="$(echo ${fname} | sed -e 's/-PUBLIC//')" ; \
	    rm -rf "${newfname}"; \
	    mv "${fname}" "${newfname}" ; \
	done

	LANG=C

	# Remove all BUCK related files from AN samples
	find "$AN_SAMPLES" -name "BUCK" -delete
	find "$AN_SAMPLES" -name "build-buck.sh" -delete
	find "$AN_SAMPLES" -name "Buck-Info.plist" -delete
	find "$AN_SAMPLES" -name "Entitlements" -type d -exec rm -r "{}" \;

	find "$AN_SAMPLES" -name "entitlements.plist" -delete

	find "$AN_SAMPLES" -name "Info.plist" -exec perl -p -i -0777 -e 's/\s*<key>CFBundleURLTypes<\/key>\s*<array>\s*<dict>\s*<key>CFBundleURLSchemes<\/key>\s*<array>\s*<string>fb\d*<\/string>\s*<\/array>\s*<\/dict>\s*<\/array>\s*<key>FacebookAppID<\/key>\s*<string>\d*<\/string>\s*<key>FacebookDisplayName<\/key>\s*<string>.*<\/string>\s*<key>LSApplicationQueriesSchemes<\/key>\s*<array>\s*<string>fbapi<\/string>\s*<string>fb-messenger-api<\/string>\s*<string>fbauth2<\/string>\s*<string>fbshareextension<\/string>\s*<\/array>\n//g' {} \;
	find "$AN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e 's/\n\s*com\.apple\.Keychain = {\s*enabled = 1;\s*};//gms' {} \;
	find "$AN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e '/NativeAdSample.entitlements/d' {} \;
	find "$AN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e '/AdBiddingSample.entitlements/d' {} \;
	find "$AN_SAMPLES" -name "project.pbxproj" -exec perl -p -i -0777 -e 's/^\s*<FileRef\n\s*location = "group:\.\.\/\.\.\/FBSDKCoreKit\/FBSDKCoreKit\.xcodeproj">\n\s*<\/FileRef>\n//gms' {} \;
	find "$AN_SAMPLES" -type f -exec sed -i '' -E -e "/fbLoginButton/d" {} \;
	find "$AN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKCoreKit/d" {} \;
	find "$AN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKLogin/d" {} \;
	find "$AN_SAMPLES" -type f -exec sed -i '' -E -e "/FBSDKApplicationDelegate/d" {} \;
	find "$AN_SAMPLES" -type f -exec  perl -p -i -0777 -e 's/\n\/\/ START REMOVED AT DISTRIBUTION BUILD TIME.*?\/\/ END REMOVED AT DISTRIBUTION BUILD TIME\n//gms' {} \;

	# Build .zip from package directory
	progress_message "Building .zip from package directory."
	(
		cd $FB_AD_SDK_BUILD
		ditto -ck --sequesterRsrc $AN_BUILD_PACKAGE $AN_ZIP
	)
else
	# -----------------------------------------------------------------------------
	# Build FacebookSDK framework
	#
	if [ "$PACKAGE" == "$PACAKAGE_FACEBOOK" ]; then
		FB_SDK_ZIP=$FB_SDK_BUILD/FacebookSDKs-${FB_SDK_VERSION_SHORT}.zip

		FB_SDK_BUILD_PACKAGE=$FB_SDK_BUILD/package
		FB_SDK_BUILD_PACKAGE_SAMPLES=$FB_SDK_BUILD_PACKAGE/Samples
		FB_SDK_BUILD_PACKAGE_SCRIPTS=$FB_SDK_BUILD/Scripts
		FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER=$FB_SDK_BUILD_PACKAGE/DocSets/

		# Build package directory structure
		progress_message "Building package directory structure."
		rm -rf "$FB_SDK_BUILD_PACKAGE" "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
		mkdir -p "$FB_SDK_BUILD_PACKAGE" \
		  || die "Could not create directory $FB_SDK_BUILD_PACKAGE"
		mkdir -p "$FB_SDK_BUILD_PACKAGE_SAMPLES"
		mkdir -p "$FB_SDK_BUILD_PACKAGE_SCRIPTS"
		mkdir -p "$FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER"

		# Call out to build prerequisites.
		if is_outermost_build; then
		  if [ -z $SKIPBUILD ]; then
		    . "$FB_SDK_SCRIPT/build_framework.sh" -c Release
		  fi
		fi
		echo Building Distribution.

		# Copy over stuff
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

		# Fixup projects to point to the SDK framework
		for fname in $(find "$FB_SDK_BUILD_PACKAGE_SAMPLES" -name "Project.xcconfig" -print); do \
		  sed 's|\(\.\.\(/\.\.\)*\)/build|\1|g;s|\.\.\(/\.\.\)*/Bolts-IOS/build/ios||g' \
		    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
		done
		for fname in $(find "$FB_SDK_BUILD_PACKAGE_SAMPLES" -name "project.pbxproj" -print); do \
		  sed 's|\(path[[:space:]]*=[[:space:]]*\.\.\(/\.\.\)*\)/build|\1|g' \
		    ${fname} > ${fname}.tmpfile  && mv ${fname}.tmpfile ${fname}; \
		done

		# Build AKFAccountKit framework
		if [ -z $SKIPBUILD ]; then
		  (xcodebuild -project "${FB_SDK_ROOT}"/AccountKit/AccountKit.xcodeproj -scheme "AccountKit-Universal" -configuration Release clean build) || die "Failed to build account kit"
		fi
		check_binary_has_architectures "$FB_SDK_BUILD"/AccountKit.framework/AccountKit "$COMMON_ARCHS";
		\cp -R "$FB_SDK_BUILD"/AccountKit.framework "$FB_SDK_BUILD_PACKAGE" \
		  || die "Could not copy AccountKit.framework"
		\cp -R "$FB_SDK_BUILD"/AccountKitStrings.bundle "$FB_SDK_BUILD_PACKAGE" \
		  || die "Could not copy AccountKitStrings.bundle"

		# Build FBNotifications framework
		\rake -f "$FB_SDK_ROOT/FBNotifications/iOS/Rakefile" package:frameworks || die "Could not build FBNotifications.framework"
		\unzip "$FB_SDK_ROOT/FBNotifications/iOS/build/release/FBNotifications-iOS.zip" -d $FB_SDK_BUILD
		\cp -R "$FB_SDK_BUILD"/FBNotifications.framework "$FB_SDK_BUILD_PACKAGE" \
		  || die "Could not copy FBNotifications.framework"

		# Build Messenger Kit
		if [ -z $SKIPBUILD ]; then
		  (xcodebuild -project "${FB_SDK_ROOT}"/FBSDKMessengerShareKit/FBSDKMessengerShareKit.xcodeproj -scheme "FBSDKMessengerShareKit-universal" -configuration Release clean build) || die "Failed to build messenger kit"
		fi
		\cp -R "$FB_SDK_BUILD"/FBSDKMessengerShareKit.framework "$FB_SDK_BUILD_PACKAGE" \
		  || die "Could not copy FBSDKMessengerShareKit.framework"

		# Build Marketing Kit
		if [ -z $SKIPBUILD ]; then
			(xcodebuild -project "${FB_SDK_ROOT}"/FBSDKMarketingKit/FBSDKMarketingKit.xcodeproj -scheme "FBSDKMarketingKit-universal" -configuration Release clean build) || die "Failed to build marketing kit"
		fi
		\cp -R "$FB_SDK_BUILD"/FBSDKMarketingKit.framework "$FB_SDK_BUILD_PACKAGE" \
			|| die "Could not copy FBSDKMarketingKit.framework"

		# Build docs
		if [ -z $SKIPBUILD ]; then
		  . "$FB_SDK_SCRIPT/build_documentation.sh"
		fi
		\ls -d "$FB_SDK_BUILD"/*.docset | xargs -I {} cp -R {} $FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER \
		  || die "Could not copy docsets"
		\cp "$FB_SDK_SCRIPT/install_docsets.sh" $FB_SDK_BUILD_PACKAGE_DOCSETS_FOLDER \
		  || die "Could not copy install_docset"

		# Build .zip from package directory
		progress_message "Building .zip from package directory."
		(
		  cd $FB_SDK_BUILD
		  ditto -ck --sequesterRsrc $FB_SDK_BUILD_PACKAGE $FB_SDK_ZIP
		)

		# Done
		progress_message "Successfully built SDK zip: $FB_SDK_ZIP"
		common_success
	else
		progress_message "Invalid parameter: the package should be AudienceNetwork or FacebookSDK."
	fi
fi
