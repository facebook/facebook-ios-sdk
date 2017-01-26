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

# This script builds the API documentation from source-level comments.
# This script requires jazzy be installed: https://github.com/realm/jazzy

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# Make sure jazzy is installed
hash jazzy >/dev/null || die 'Jazzy is not installed! Run `sudo gem install jazzy`'

# Then iterate over the kits
KITS=("FBSDKCoreKit"
      "FBSDKShareKit"
      "FBSDKLoginKit"
      "FBSDKMessengerShareKit"
      "AccountKit")

CNT=${#KITS[@]}

for (( i = 0; i < CNT; i++ ))
do
  KITREFDOCS=${KITS[$i]};

  # Actually generate the documentation
  jazzy --objc --framework-root $FB_SDK_ROOT/$KITREFDOCS --umbrella-header $FB_SDK_ROOT/$KITREFDOCS/$KITREFDOCS/$KITREFDOCS.h --sdk iphoneos --clean --output $FB_SDK_ROOT/docs/$KITREFDOCS

  # Zip the result so it can be uploaded easily
  pushd $FB_SDK_ROOT/docs/
  zip -r $KITREFDOCS.zip $KITREFDOCS
  popd
done

common_success
