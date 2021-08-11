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

EXPECTED_XCODEGEN_VERSION="2.24.0"

RESET='\033[0m'
YELLOW='\033[1;33m'

pgrep -f '/Applications/Xcode.*\.app/Contents/MacOS/Xcode' > /dev/null
if [ $? -eq 0 ]; then
    XCODE_WAS_OPEN="true"
    echo "⚠️  ${YELLOW}Closing Xcode!${RESET}"
    killall Xcode || true
fi


if [ ! -d "Carthage/checkouts/ocmock" ]; then
    echo "OCMock is required to run some tests. Run the command 'carthage bootstrap --no-build' and try again."
    exit
fi

if ! command -v xcodegen >/dev/null; then
    echo "WARNING: Xcodegen not installed, run 'brew install xcodegen' or visit https://github.com/yonaskolb/XcodeGen"
    exit
fi

VERSION=$( xcodegen --version )

if [ "$VERSION" != "Version: $EXPECTED_XCODEGEN_VERSION" ]; then
    echo "Incorrect xcodegen version. Please install or upgrade to version $EXPECTED_XCODEGEN_VERSION"
    exit
fi

cd TestTools || exit
xcodegen generate

cd ..

cd FBSDKCoreKit_Basics || exit
xcodegen generate

cd ..

cd FBAEMKit || exit
xcodegen generate

cd ..

cd FBSDKCoreKit || exit
xcodegen generate

cd ..

cd FBSDKLoginKit || exit
xcodegen generate

cd ..

cd FBSDKShareKit || exit
xcodegen generate

cd ..

cd FBSDKGamingServicesKit || exit
xcodegen generate

cd ..

if [ $XCODE_WAS_OPEN ]; then
    echo "${YELLOW}Reopening FacebookSDK.xcworkspace${RESET}"
    open FacebookSDK.xcworkspace
fi
