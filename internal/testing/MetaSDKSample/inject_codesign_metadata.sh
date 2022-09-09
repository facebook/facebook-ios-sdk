#!/bin/bash
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

set -e

if [ $# -lt 1 ]
then
  SCRIPT_BASENAME=$(basename "$0")
  printf "Usage: ./%s <App bundle path>\n\n" "$SCRIPT_BASENAME" 1>&2
  exit 1
fi

SCRIPT_DIRNAME=$(dirname "$0")
APP_BUNDLE_PATH="$1"

# Root
cp "$SCRIPT_DIRNAME"/BUCK_code_sign_args.plist "$APP_BUNDLE_PATH"/BUCK_code_sign_args.plist
cp "$SCRIPT_DIRNAME"/BUCK_code_sign_entitlements.plist "$APP_BUNDLE_PATH"/BUCK_code_sign_entitlements.plist

# Frameworks with default args
for fwkname in \
    "E2EUtils.framework" \
    "OHHTTPStubs.framework" ; do \
  cp "$SCRIPT_DIRNAME"/BUCK_code_sign_args.plist "$APP_BUNDLE_PATH"/Frameworks/"$fwkname"/BUCK_code_sign_args.plist;
  cp "$SCRIPT_DIRNAME"/BUCK_code_sign_entitlements.plist "$APP_BUNDLE_PATH"/Frameworks/"$fwkname"/BUCK_code_sign_entitlements.plist;
done;
