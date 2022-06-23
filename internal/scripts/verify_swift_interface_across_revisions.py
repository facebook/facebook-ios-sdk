#!/usr/bin/env fbpython
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import os
import pathlib
import subprocess
import sys
import shutil
from os.path import exists
from sdk_kit_names import kits


def main():
    generate_projects()

    for kit in kits:
        # Output file paths need to be outside of the directory so that we don't pollute the history we're trying to examine.
        base_revision_interface_path = f"/tmp/{kit}_base"
        current_revision_interface_path = f"/tmp/{kit}_current"

        print("Building Swift interface for base revision.")
        checkout_base_commit()
        build_swift_interface(kit, base_revision_interface_path)
        print("Building Swift interface for current revision.")
        checkout_current_commit()
        build_swift_interface(kit, current_revision_interface_path)

        compare_swift_interfaces(kit, base_revision_interface_path, current_revision_interface_path)


def compare_swift_interfaces(kit, base_revision_interface_path, current_revision_interface_path):
    print(f"Comparing {kit} interfaces")

    command = " ".join(
        [
            "git --no-pager diff",
            "--no-ext-diff",
            "--unified=0",
            "--color-moved=dimmed-zebra",
            "--no-prefix",
            "--no-index",
            f"{base_revision_interface_path} {current_revision_interface_path}",
            "| awk '!seen[$0]++'"
        ]
    )

    output = get_output(command)

    if output:
        print_to_stderr(
            " ".join(
                [
                    f"\nDifferences detected between the {kit} public Swift interface on this diff and the base revision.",
                    f"Please ensure that the CHANGELOG is updated in this diff.\n",
                    f"If this is a new feature, post in ShipRoom for feedback - https://fb.workplace.com/groups/257212025903510.",
                    f"\n {output}",
                    f"\n\nCheck the job log for the full set of changes and instructions on what to do next."
                ]
            )
        )

        sys.exit(1)


def generate_projects():
    os.chdir(git_base_dir())

    subprocess.run(
        "./generate-projects.sh --skip-closing-xcode", shell=True, check=False, capture_output=True
    )


def build_swift_interface(kit, output_file_path):
    os.chdir(git_base_dir())

    xcodebuild_command = " ".join(
        [
            "xcodebuild build",
            "-workspace FacebookSDK.xcworkspace",
            f"-scheme {kit}-Dynamic",
            "-sdk iphonesimulator",
            "-derivedDataPath build",
        ]
    )
    completed_process = subprocess.run(
        xcodebuild_command, shell=True, check=True, capture_output=True
    )

    swift_interface_path=f"build/Build/Products/Debug-iphonesimulator/{kit}.framework/Modules/{kit}.swiftmodule/x86_64-apple-ios-simulator.swiftinterface"
    if exists(swift_interface_path):
        shutil.copyfile(swift_interface_path, output_file_path)
    else:
        # There has gotta be a better way to do this natively
        # Also, this whole idea is a little troll.
        # If there is no interface then it's basically the same
        # as an empty string for comparison purposes.
        # This will catch changes, deletions, and additions.
        subprocess.run(
            f"echo '' > {output_file_path}", shell=True, check=False, capture_output=True
        )


def checkout_base_commit():
    subprocess.run(
        "git checkout $( git rev-parse @~ )", shell=True, check=True, capture_output=True
    )


def checkout_current_commit():
    subprocess.run(
        "git switch -d -", shell=True, check=True, capture_output=True
    )


def git_base_dir() -> str:
    return get_output("git rev-parse --show-toplevel")


def get_output(command):
    """Returns the output of a shell command"""
    completed_process = subprocess.run(
        command, shell=True, check=True, capture_output=True
    )

    if completed_process.returncode == 0:
        return completed_process.stdout.decode().rstrip()
    else:
        return completed_process.stderr.decode().rstrip()


def print_to_stderr(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


if __name__ == "__main__":
    main()
