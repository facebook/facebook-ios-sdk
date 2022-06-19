#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

"""
    Script for app configurations diagnostics. Detects missing configurations for SDK feature kits.

    Usage:
        python3 ios_fb_sdk_config_diagnostics.py [-h]
                                                 [-t  {fbc,fbl,fbs} [{fbc,fbl,fbs} ...]]

    Required Package:
        typing
"""
import argparse
import os
import plistlib
import subprocess
import sys
from typing import Dict

appIdKey = "FacebookAppID"
appNameKey = "FacebookDisplayName"
bundleTypeKey = "CFBundleURLTypes"
bundleSchemeKey = "CFBundleURLSchemes"
querySchemeKey = "LSApplicationQueriesSchemes"
photoUsageKey = "NSPhotoLibraryUsageDescription"

SUPPORTED_SDK_KITS = {
    "fbc": "Facebook Core",
    "fbl": "Facebook Login",
    "fbs": "Facebook Share",
}


def print_warning(type: str, path: str):
    print(f" - Missing {type} in file {os.path.basename(path)}")


def get_ios_sdk_dir():
    hg_root = run_command("hg root")
    if not hg_root:
        sys.exit("Cannot find hg root dir")
    return os.path.join(hg_root.rstrip(), "fbobjc/ios-sdk")


def get_app_dir():
    return os.path.join(get_ios_sdk_dir(), "internal/testing/CoffeeShop")


def run_command(command: str):
    return subprocess.getoutput(command)


def check_info_plist(file: str, feature: str):
    with open(file, "rb") as fp:
        contents = plistlib.load(fp)

        if feature == "fbc":
            return check_core_settings(contents, file)
        if feature == "fbl":
            return check_feature_settings(contents, file)
        if feature == "fbs":
            # separate the calls to make sure both checks get run
            hasFeatureSettings = check_feature_settings(contents, file)
            hasShareSettings = check_share_settings(contents, file)
            return hasFeatureSettings and hasShareSettings

    return False


def check_core_settings(contents, file: str):
    foundAppId = contents.get(appIdKey, False)
    foundAppName = contents.get(appNameKey, False)
    foundBundleTypes = contents.get(bundleTypeKey, False)
    foundBundleSchemes = False
    if foundBundleTypes:
        bundleSchemes = contents[bundleTypeKey][0]
        if (type(bundleSchemes) is dict) and bundleSchemes.get(bundleSchemeKey, False):
            foundBundleSchemes = True

    if not foundAppId:
        print_warning(appIdKey, file)
    if not foundAppName:
        print_warning(appNameKey, file)
    if not foundBundleTypes:
        print_warning(bundleTypeKey, file)
    if not foundBundleSchemes:
        print_warning(bundleSchemeKey, file)

    return foundAppId and foundAppName and foundBundleTypes and foundBundleSchemes


def check_feature_settings(contents, file: str):
    # Required for any Facebook dialog that can perform an app switch (FB Login, Share, etc)
    foundQuerySchemes = contents.get(querySchemeKey, False)

    if not foundQuerySchemes:
        print_warning(querySchemeKey, file)

    return foundQuerySchemes


def check_share_settings(contents, file: str):
    foundPhotoUsageDescription = contents.get(photoUsageKey, False)

    if not foundPhotoUsageDescription:
        print_warning(photoUsageKey, file)

    return foundPhotoUsageDescription


def pretty_format_features(features: Dict[str, str]):
    return "\n".join("{!r} for {!r}. ".format(k, v) for k, v in features.items())


def format_name(featureKey: str):
    return SUPPORTED_SDK_KITS.get(featureKey)


def main():
    parser = argparse.ArgumentParser(
        description="Script for SDK Diagnostics for iOS SDK app configurations. By default, "
        "runs diagnostics for Facebook Core, Facebook Login, and Facebook Sharing."
    )
    parser.add_argument(
        "-t ",
        "--test",
        dest="features",
        nargs="+",
        action="append",
        choices=list(SUPPORTED_SDK_KITS.keys()),
        help="Run diagnostics for specific feature(s). Must specify at least one feature. Supported "
        "features: " + pretty_format_features(SUPPORTED_SDK_KITS),
    )
    args = parser.parse_args()

    print("Performing diagnostic checks for required SDK settings...")
    sdk_features = (
        args.features[0] if args.features else list(SUPPORTED_SDK_KITS.keys())
    )
    app_dir = get_app_dir()
    plist_file = os.path.join(app_dir, "CoffeeShop/info.plist")
    plist_success = True

    # Always include Facebook CoreKit
    sdk_features.sort()
    if sdk_features[0] != "fbc":
        sdk_features.insert(0, "fbc")

    for feature in sdk_features:
        print(format_name(feature))
        if not check_info_plist(plist_file, feature):
            plist_success = False

    if plist_success:
        print("\033[92mSUCCESS! Required app configurations were found.")
    else:
        print("\033[91mFAILED. See above for missing app configurations.")


if __name__ == "__main__":
    main()
