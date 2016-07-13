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

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# process options, valid arguments -c [Debug|Release] -n
BUILDCONFIGURATION=Debug
SCHEMES="BuildAllKits FBSDKIntegrationTests samples"

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
      echo "       BuildAllKits: unit tests"
      echo "       FBSDKIntegrationTests: integration tests"
      echo "       samples: build sample apps"
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
# re-map v3 schemes
SCHEMES=${SCHEMES/FacebookSDKTests/BuildAllKits}
SCHEMES=${SCHEMES/FacebookSDKIntegrationTests/FBSDKIntegrationTests}
SCHEMES=${SCHEMES/FacebookSDKApplicationTests/samples}

cd "$FB_SDK_ROOT"

for SCHEME in $SCHEMES; do
  if [[ $SCHEME == "BuildAllKits" ]]; then
    # Build iOS frameworks and run unit tests
    ( $XCTOOL -workspace FacebookSDK.xcworkspace \
              -scheme "BuildAllKits" \
              -configuration $BUILDCONFIGURATION \
              -sdk iphonesimulator \
              build-tests run-tests
    ) || exit $?

    # Build tvOS frameworks
    ( $XCTOOL -workspace FacebookSDK.xcworkspace \
              -scheme "BuildAllKits_TV" \
              -configuration $BUILDCONFIGURATION \
              -sdk appletvsimulator \
              build
    ) || exit $?
  elif [[ $SCHEME == "samples" ]]; then
    ( cd "$FB_SDK_ROOT/samples/HelloTV"
      $XCTOOL -project "HelloTV.xcodeproj" -scheme "HelloTV" -sdk appletvsimulator build
    ) || exit $?

    FAILED_SAMPLES=""
    for SAMPLE in Iconicus RPSSample Scrumptious ShareIt SwitchUserSample; do
      (
        cd "$FB_SDK_ROOT/samples/$SAMPLE"
        $XCTOOL -project "$SAMPLE.xcodeproj" -scheme "$SAMPLE" -sdk iphonesimulator build
      )
      if [[ $? -ne 0 ]]; then
        FAILED_SAMPLES="$FAILED_SAMPLES $SAMPLE"
      fi
    done
    if [[ -n $FAILED_SAMPLES ]]; then
        die "Failed to build $FAILED_SAMPLES"
    fi
    if [[ -a "internal/scripts/run_internal_tests.sh" ]]; then
      source "internal/scripts/run_internal_tests.sh"
    fi
  else
    COMMAND="$XCTOOL
      -workspace FacebookSDK.xcworkspace \
      -scheme $SCHEME \
      -configuration $BUILDCONFIGURATION \
      -sdk iphonesimulator \
      build-tests run-tests"
      eval $COMMAND || die "Error while running tests ($COMMAND)"
  fi
done
