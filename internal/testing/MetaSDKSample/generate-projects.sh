#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

EXPECTED_XCODEGEN_VERSION="2.29.0"

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
if [ -f ../../tools/xcodegen ]; then
    CWD=$(pwd)
    XCODEGEN_BINARY="${CWD}/../../tools/xcodegen"
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

generateProject () {
    if [ -n "$XCODEGEN_USE_CACHE" ]; then
        # Use rm -rf ~/.xcodegen/cache if you need to reset the cache
        $XCODEGEN_BINARY generate --use-cache
    else
        $XCODEGEN_BINARY generate
    fi
}

generateProject

if [ "$REOPEN_XCODE" = true ]; then
    echo "${YELLOW}Reopening MetaSDKSample.xcodeproj${RESET}"
    open MetaSDKSample.xcodeproj
fi
