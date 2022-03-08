#!/bin/sh
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

EXPECTED_XCODEGEN_VERSION="2.25.0"

RESET='\033[0m'
YELLOW='\033[1;33m'

REOPEN_XCODE=false

pgrep -f '/Applications/Xcode.*\.app/Contents/MacOS/Xcode' > /dev/null
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    if [ "$1" != "--skip-closing-xcode" ]; then
        echo "⚠️  ${YELLOW}Closing Xcode!${RESET}"
        killall Xcode || true
        REOPEN_XCODE=true
    fi
fi

XCODEGEN_BINARY="xcodegen"
if [ -f internal/tools/xcodegen ]; then
    CWD=$(pwd)
    XCODEGEN_BINARY="${CWD}/internal/tools/xcodegen"
elif ! command -v xcodegen >/dev/null; then
    echo "WARNING: Xcodegen not installed, run 'brew install xcodegen' or visit https://github.com/yonaskolb/XcodeGen"
    exit 1
fi

CURRENT_XCODEGEN_VERSION=$($XCODEGEN_BINARY --version)
CURRENT_XCODEGEN_VERSION=${CURRENT_XCODEGEN_VERSION#"Version: "} # Strip "Version :" prefix
if [ "$CURRENT_XCODEGEN_VERSION" != "$EXPECTED_XCODEGEN_VERSION" ]; then
    echo "${YELLOW}WARNING: Expected xcodegen version is $EXPECTED_XCODEGEN_VERSION. You have $CURRENT_XCODEGEN_VERSION.${RESET}"
    XCODEGEN_VERSION_BYPASS_FLAG='--force-with-wrong-xcodegen'
    if [ "$1" != "$XCODEGEN_VERSION_BYPASS_FLAG" ]; then
        echo "${YELLOW}You may use the $XCODEGEN_VERSION_BYPASS_FLAG flag to bypass this check.${RESET}"
        exit 1
    else
        echo "${YELLOW}Using $XCODEGEN_VERSION_BYPASS_FLAG to bypass version check. Xcode project file generation will proceed but you may encounter unexpected issues.${RESET}"
    fi
fi

for KIT_DIR in FBSDKCoreKit_Basics FBAEMKit FBSDKCoreKit TestTools FBSDKLoginKit FBSDKShareKit FBSDKGamingServicesKit; do
    cd $KIT_DIR || exit
    # Set the env var XCODEGEN_USE_CACHE to anything to use the --use-cache flag
    if [ -n "$XCODEGEN_USE_CACHE" ]; then
        # Use rm -rf ~/.xcodegen/cache if you need to reset the cache
        $XCODEGEN_BINARY generate --use-cache
    else
        $XCODEGEN_BINARY generate
    fi
    cd ..
done


if [ "$REOPEN_XCODE" = true ]; then
    echo "${YELLOW}Reopening FacebookSDK.xcworkspace${RESET}"
    open FacebookSDK.xcworkspace
fi
