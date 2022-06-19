#!/usr/bin/env fpython
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import os
import re
import subprocess
import sys


def main():
    hg_root = run("hg root").rstrip()
    sdk_dir = f"{hg_root}/fbobjc/ios-sdk"

    jest_e2e_dir = f"{hg_root}/xplat/endtoend/jest-e2e"
    jest_e2e_file = f"{jest_e2e_dir}/libdef/jest-e2e.js"

    hackbook_jest_ios_dir = f"{jest_e2e_dir}/apps/hackbook/__tests__/iOS"
    hackbook_launch_test_file = f"{hackbook_jest_ios_dir}/hb4iLaunchTest-e2e.js"

    version = extract_updated_version(sdk_dir)
    update_jest_definitions(jest_e2e_file, version)
    update_hackbook_test(hackbook_launch_test_file, version)

    print("Success! Jest support files updated.")
    sys.exit(0)


def update_jest_definitions(file: str, version: str) -> None:
    with open(file, "r") as f:
        contents = f.read()

    comment_marker = "// HACKBOOK FOR IOS - DO NOT EDIT COMMENT OR THINGS WILL BREAK"
    line_to_add = f"  | 'hb4i.{version}'"
    replacement = f"{comment_marker}\n{line_to_add}"

    # This is hacky but it works
    updated_contents = contents.replace(comment_marker, replacement)

    if contents == updated_contents:
        print_error_and_exit(f"Unable to add {line_to_add} to {file}")
    else:
        with open(file, "w") as f:
            f.write(updated_contents)


def update_hackbook_test(file: str, version: str) -> None:
    with open(file, "r") as f:
        contents = f.read()

    comment_marker = "/* Config begins here (Do not remove) */"
    config_to_add = f"""\
  .withConfig('{version}', {{
    environment: {{
      agent: 'iOS',
      app: 'hb4i.{version}',
    }},
  }})"""
    replacement = f"{comment_marker}\n{config_to_add}"

    # This is hacky but it works
    updated_contents = contents.replace(comment_marker, replacement)
    if contents == updated_contents:
        print_error_and_exit(f"Unable to add {config_to_add} to {file}")
    else:
        with open(file, "w") as f:
            f.write(updated_contents)


def extract_updated_version(sdk_dir):
    os.chdir(sdk_dir)

    print("Checking FBSDKCoreKit.h for updated sdk version...")
    changes = run(
        "hg diff -c $(hg whereami) FBSDKCoreKit/FBSDKCoreKit/include/FBSDKCoreKitVersions.h"
    )

    if not changes:
        print("There are no changes to FBSDKCoreKitVersions.h in the previous commit")
        sys.exit(0)

    regex = r"((?:[0-9]{1}|[1-9][0-9]+)\.(?:[0-9]{1}|[1-9][0-9]+)\.(?:[0-9]{1}|[1-9][0-9]+))"
    versions = re.findall(regex, changes)

    if len(versions) != 2 or versions[0] == versions[1]:
        message = f"""\
No updated SDK version found.

Full changeset:

{changes}

Exiting. Goodbye.
"""
        print(message)
        sys.exit(0)

    return versions[1]


def print_error_and_exit(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
    sys.exit(1)


def run(command):
    completed_process = subprocess.run(
        command, shell=True, check=True, capture_output=True
    )
    return completed_process.stdout.decode()


if __name__ == "__main__":
    exit(main())
