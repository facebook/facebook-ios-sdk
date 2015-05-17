#!/bin/sh
#
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

# this script configures your iOS simulator for unit tests
# Note: On Mac OS X, an easy way to generate a MACHINE_UNIQUE_USER_TAG is with the following:
#   system_profiler SPHardwareDataType | grep -i "Serial Number (system):" | awk '{print $4}'

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

if [ "$#" -lt 3 ]; then
      echo "Usage: $0 APP_ID APP_SECRET CLIENT_TOKEN [MACHINE_UNIQUE_USER_KEY]"
      echo "  APP_ID                   your unit-testing Facebook application's App ID"
      echo "  APP_SECRET               your unit-testing Facebook application's App Secret"
      echo "  CLIENT_TOKEN             your unit-testing Facebook application's client token"
      echo "  MACHINE_UNIQUE_USER_TAG  optional text used to ensure this machine will use its own set of test users rather than sharing"
      die 'Arguments do not conform to usage'
fi

function write_xcconfig {
    echo "IOS_SDK_TEST_APP_ID = $2" > $1
    echo "IOS_SDK_TEST_APP_SECRET = $3" >> $1
    echo "IOS_SDK_TEST_CLIENT_TOKEN = $4" >> $1
    echo "IOS_SDK_MACHINE_UNIQUE_USER_KEY = $5" >> $1

    echo "Wrote test app configuration to: $1"
}

XCCONFIG_FILE="$FB_SDK_ROOT"/Configurations/TestAppIdAndSecret.xcconfig

write_xcconfig "$XCCONFIG_FILE" "$1" "$2" "$3" "$4"


