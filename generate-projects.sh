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
    exit
fi

VERSION=$( xcodegen --version )

if [ "$VERSION" != "Version: $EXPECTED_XCODEGEN_VERSION" ]; then
    echo "Incorrect xcodegen version. Please install or upgrade to version $EXPECTED_XCODEGEN_VERSION"
    exit
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
