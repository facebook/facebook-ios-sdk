#!/usr/bin/env fbpython
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

"""
Output JSON with build information taken from Info.plist.

This script is meant to emulate the same functionality that Android gets from scripts/manifest_info.py.
It searches the Info.plist file for important information about the build (what package it was, the version, etc)
and outputs it as JSON to be sent to the mobile builds page
"""

import json
import os
import sys

import biplist


def get_build_info(plist):
    """Create dictionary with build information from the plist."""
    version_name_key = (
        "FBAppVersion" if "FBAppVersion" in plist else "CFBundleShortVersionString"
    )
    fb_app_id = plist["FacebookAppID"] if "FacebookAppID" in plist else ""
    fb_app_id_ipad = (
        plist["FacebookAppID~ipad"] if "FacebookAppID~ipad" in plist else ""
    )

    return {
        "version_code": plist.get("CFBundleVersion", ""),
        "version_name": plist.get(version_name_key, ""),
        "package": plist.get("CFBundleIdentifier", ""),
        "min_sdk": plist.get("MinimumOSVersion", ""),
        "target_sdk": plist.get("DTPlatformVersion", ""),
        "fb_app_id": fb_app_id,
        "fb_app_id~ipad": fb_app_id_ipad,
        "release_tag": os.getenv("MANIFEST_RELEASE_TAG") or "",
        "display_name": plist.get("CFBundleDisplayName", "")
        or plist.get("CFBundleName", ""),
    }


def print_output(info):
    """Format and print build info dictionary as JSON."""
    # Don't include missing values, but include explicitly empty ones.
    info = {k: v for k, v in info.items() if v not in [None, []]}
    print(json.dumps(info, separators=(",", ":"), sort_keys=True))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: %s <Info.plist location>" % sys.argv[0], file=sys.stderr)
        exit(1)
    plist = biplist.readPlist(sys.argv[1])
    print_output(get_build_info(plist))
