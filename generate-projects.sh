#!/bin/sh
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

EXPECTED_XCODEGEN_VERSION="2.24.0"

RESET='\033[0m'
YELLOW='\033[1;33m'

pgrep -f '/Applications/Xcode.*\.app/Contents/MacOS/Xcode' > /dev/null
if [ $? -eq 0 ]; then
    XCODE_WAS_OPEN="true"
    echo "⚠️  ${YELLOW}Closing Xcode!${RESET}"
    killall Xcode || true
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
    $XCODEGEN_BINARY generate --use-cache
    cd ..
done


if [ $XCODE_WAS_OPEN ]; then
    echo "${YELLOW}Reopening FacebookSDK.xcworkspace${RESET}"
    open FacebookSDK.xcworkspace
fi
