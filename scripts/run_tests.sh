#!/bin/sh
#
# Copyright 2010-present Facebook.
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

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# process options, valid arguments -c [Debug|Release] -n 
BUILDCONFIGURATION=Debug
SCHEMES="facebook-ios-sdk-tests FacebookSDKIntegrationTests FacebookSDKApplicationTests"

while getopts ":nc:" OPTNAME
do
  case "$OPTNAME" in
    "c")
      BUILDCONFIGURATION=$OPTARG
      ;;
    "?")
      echo "$0 [-c [Debug|Release]] [-n] [SUITE ...]"
      echo "       -c sets configuration"
      echo "       -n clean before build"
      echo "SUITE: one or more of the following (default is all):"
      echo "       facebook-ios-sdk-tests: unit tests"
      echo "       FacebookSDKIntegrationTests: integration tests"
      echo "       FacebookSDKApplicationTests: application tests"
      die
      ;;
    "n")
      CLEAN=clean
      ;;
    ":")
      echo "Missing argument value for option $OPTARG"
      die
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options"
      die
      ;;
  esac
done
shift $(( $OPTIND -1 ))

if [ -n "$*" ]; then
    SCHEMES="$*"
fi

cd "$FB_SDK_SRC"

test -d "$FB_SDK_BUILD" \
  || mkdir -p "$FB_SDK_BUILD" \
  || die "Could not create directory $FB_SDK_BUILD"

for SCHEME in $SCHEMES; do
    "$XCTOOL" \
        -project facebook-ios-sdk.xcodeproj \
        -scheme $SCHEME \
        -sdk iphonesimulator \
        -configuration "$BUILDCONFIGURATION" \
        ONLY_ACTIVE_ARCH=YES \
        SYMROOT="$FB_SDK_BUILD" \
        $CLEAN test \
        -test-sdk iphonesimulator \
        -simulator iphone \
        || die "Error while running unit tests"
done

