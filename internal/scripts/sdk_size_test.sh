#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# shellcheck disable=SC2039

# This script compares the size difference of adding various SDKs to a sample Application
# and outputs that information to the console

FB_ECHO_GREEN='\x1B[1;32;40m'
FB_ECHO_BOLD='\x1B[1m'
FB_ECHO_RESET='\x1B[0m'

if [ -z "$FB_SDK_INTERNAL_SCRIPT" ]; then
  # The directory containing this script
  # We need to go there and use pwd so these are all absolute paths
  pushd "$(dirname "${BASH_SOURCE[@]}")" || exit >/dev/null
  FB_SDK_INTERNAL_SCRIPT=$(pwd)
  popd || exit >/dev/null

  FB_SDK_SCRIPT="$(cd "$FB_SDK_INTERNAL_SCRIPT"/../../scripts || exit; pwd)"
  # The root directory where the Facebook SDK for iOS is cloned
  FB_SDK_ROOT=$(dirname "$FB_SDK_SCRIPT")

  # The directory where the target is built
  FB_SDK_BUILD=$FB_SDK_ROOT/build
fi

fb_internal_message() {
  echo "${FB_ECHO_GREEN}###${FB_ECHO_RESET} ${FB_ECHO_BOLD}${*}${FB_ECHO_RESET}"
}

# Builds an IPA file for a BUCK target specified as a parameter
# Creates a global variable with the path to the IPA
BuildBinaryAndIPA() {
  IPA=$OUT/IpaSizeTestAppPackage_$1.ipa
  fb_internal_message "Building $1 Ipa"
  buck build -v 0 "//fbobjc/ios-sdk/internal/testing/IpaSizeTestApp:IpaSizeTestAppPackage_$1" --config cxx.default_platform=iphonesimulator-x86_64 --out "$IPA"

  eval "$1_IPA_TO_TEST=$IPA"
}

PrintResult() {
  echo ""
  echo "Running ipa_size.py on $1"
  echo ""
  eval "$HOME/fbsource/fbobjc/Tools/ipa_size.py \$$1_IPA_TO_TEST"
  echo "-------------------------------------------------------------------------"
  echo ""
}

OUT=$FB_SDK_BUILD/IpaSizeTest
rm -rf "$OUT"
mkdir -p "$OUT"
cd "$OUT" || exit

# Function builds binaries and reports on ipa size
# It expects a string as an argument that seperates the sdks you want to test by a comma:
#    ex. runSizeTest "NoSDKs,FBSDKShareKit,FBSDKAll"
runSizeTest() {
  echo "-------------------------------------------------------------------------------------"
  echo "  ____        _ _     _ _               _____         _        _                     "
  echo " | __ ) _   _(_) | __| (_)_ __   __ _  |_   _|__  ___| |_     / \   _ __  _ __  ___  "
  echo " |  _ \| | | | | |/ _\ | | '_ \ / _\ |   | |/ _ \/ __| __|   / _ \ | '_ \| '_ \/ __| "
  echo " | |_) | |_| | | | (_| | | | | | (_| |   | |  __/\__ \ |_   / ___ \| |_) | |_) \__ \ "
  echo " |____/ \__,_|_|_|\__,_|_|_| |_|\__, |   |_|\___||___/\__| /_/   \_\ .__/| .__/|___/ "
  echo "                                |___/                              |_|   |_|         "
  echo "-------------------------------------------------------------------------------------"

  # We need a reference point, so build binary with no sdks
  BuildBinaryAndIPA "NoSDKs"

  # POSIX sh doesn't support arrays, so use string parsing
  SDKS="$1,"
  while [ -n "$SDKS" ]; do SDK=${SDKS%%,*}
    BuildBinaryAndIPA "$SDK"
    SDKS=${SDKS#*,}
  done

  echo ""
  echo "----------------------------------------------------"
  echo "  ____  _           ____                       _    "
  echo " / ___|(_)_______  |  _ \ ___ _ __   ___  _ __| |_  "
  echo " \___ \| |_  / _ \ | |_) / _ \ '_ \ / _ \| '__| __| "
  echo "  ___) | |/ /  __/ |  _ <  __/ |_) | (_) | |  | |_  "
  echo " |____/|_/___\___| |_| \_\___| .__/ \___/|_|   \__| "
  echo "                                                    "
  echo "----------------------------------------------------"
  echo ""

  # POSIX sh doesn't support arrays, so use string parsing
  SDKS="$1,"
  while [ -n "$SDKS" ]; do SDK=${SDKS%%,*}
    PrintResult "$SDK" "Including $SDK"
    SDKS=${SDKS#*,}
  done
}

if [ "$1" = "main_sdks" ]; then
  runSizeTest "FBSDKCoreKit,FBSDKShareKit,FBSDKLoginKit,FBSDKAll"
else
  runSizeTest "FBSDKBasics,FBSDKShareKit,FBSDKLoginKit,FBSDKCoreKit,FBSDKAll"
fi
