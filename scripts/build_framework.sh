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

# process options, valid arguments -c [Debug|Release] -n -s [scheme]
BUILDCONFIGURATION=Debug
NOEXTRAS=1
SCHEME=BuildAllKits
while getopts ":ntc:s:" OPTNAME
do
  case "$OPTNAME" in
    "s")
      SCHEME=$OPTARG
      ;;
    "c")
      BUILDCONFIGURATION=$OPTARG
      ;;
    "n")
      NOEXTRAS=1
      ;;
    "t")
      NOEXTRAS=0
      ;;
    "?")
      echo "$0 -c [Debug|Release] -n"
      echo "       -c sets configuration (default=Debug)"
      echo "       -n no test run (default)"
      echo "       -t test run"
      echo "       -s scheme (default=BuildAllKits)"
      die
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


# -----------------------------------------------------------------------------

progress_message Updating Submodules

# -----------------------------------------------------------------------------
(cd "$FB_SDK_ROOT"; git submodule foreach 'git fetch --tags'; git submodule update --init --recursive)

# -----------------------------------------------------------------------------

progress_message Building Framework.

# -----------------------------------------------------------------------------
# Compile binaries
#
test -d "$FB_SDK_BUILD" \
  || mkdir -p "$FB_SDK_BUILD" \
  || die "Could not create directory $FB_SDK_BUILD"

cd "$FB_SDK_ROOT"
("$XCTOOL" -workspace "${FB_SDK_ROOT}"/FacebookSDK.xcworkspace -scheme "${SCHEME}" -configuration "${BUILDCONFIGURATION}" clean build) || die "Failed to build"

# -----------------------------------------------------------------------------
# Run unit tests
#

if [ ${NOEXTRAS:-0} -eq  1 ];then
  progress_message "Skipping unit tests."
else
  progress_message "Running unit tests."
  cd "$FB_SDK_ROOT"
  "$FB_SDK_SCRIPT/run_tests.sh" -c $BUILDCONFIGURATION
fi

# -----------------------------------------------------------------------------
# Generate strings
#
progress_message "Generating strings"
(
  cd "$FB_SDK_ROOT"
  find FBSDKCoreKit/ FBSDKShareKit/ FBSDKLoginKit/ FBSDKTVOSKit/ -name "*.m" | xargs genstrings -o FacebookSDKStrings.bundle/Resources/en.lproj/
)

# -----------------------------------------------------------------------------
# Done
#

progress_message "Framework version info: ${FB_SDK_VERSION_RAW}"
common_success
