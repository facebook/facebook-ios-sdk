#!/usr/bin/env fbpython
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import os
import pathlib
import subprocess
import sys

from xcodebuild_warnings_allowlist import XCODEBUILD_WARNINGS_ALLOWLIST


def main():
    base_dir = git_base_dir() if is_git_dir() else generic_base_dir()
    os.chdir(base_dir)

    xcodebuild_command = " ".join(
        [
            "xcodebuild clean build-for-testing",
            "-workspace FacebookSDK.xcworkspace",
            "-scheme BuildAllKits-Dynamic",
            "-destination 'platform=iOS Simulator,name=iPhone 13,OS=15.0'",
        ]
    )

    completed_process = subprocess.run(
        xcodebuild_command, shell=True, check=False, capture_output=True
    )

    output_lines = completed_process.stdout.decode().splitlines()

    warning_lines = {
        line for line in output_lines if "warning: " in line or "error: " in line
    }

    # Make the output prettier by removing the base_dir from the warning file paths
    warning_lines = [line.replace(f"{base_dir}/", "") for line in warning_lines]

    non_allowlisted_warnings = []

    for warning in warning_lines:
        can_ignore = any(
            allowed_warning_text in warning
            for allowed_warning_text in XCODEBUILD_WARNINGS_ALLOWLIST
        )
        if not can_ignore:
            non_allowlisted_warnings.append(warning)

    # If there are warnings print an issue and exit
    if non_allowlisted_warnings:
        warning_count = len(non_allowlisted_warnings)
        warning_word = "WARNINGS" if warning_count > 1 else "WARNING"

        print_to_stderr(
            f"\nFAILED DUE TO THE FOLLOWING {warning_count} NON-ALLOWLISTED {warning_word}:"
        )
        for i, warning in enumerate(non_allowlisted_warnings, start=1):
            print_to_stderr(f"{i}. {warning}")

        print_to_stderr(
            "If any of these warnings should be ALLOWLISTED, add them to xcodebuild_warnings_allowlist.py"
        )

        sys.exit(1)

    if completed_process.returncode != 0:
        print(f"Failed to run xcodebuild. Return code: {completed_process.returncode}")
        print(f"STDERR: {completed_process.stderr.decode()}")
        sys.exit(completed_process.returncode)

    print("Check complete. No unexpected warnings encountered.")
    sys.exit(0)


def is_git_dir():
    return get_output("git rev-parse --is-inside-work-tree") == "true"


def git_base_dir() -> str:
    return get_output("git rev-parse --show-toplevel")


def generic_base_dir() -> str:
    scripts_dir = os.path.dirname(os.path.realpath(__file__))
    return pathlib.Path(scripts_dir).parent.absolute()


def print_to_stderr(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def get_output(command):
    """Returns the output of a shell command"""
    completed_process = subprocess.run(
        command, shell=True, check=False, capture_output=True
    )

    if completed_process.returncode == 0:
        return completed_process.stdout.decode().rstrip()
    else:
        return completed_process.stderr.decode().rstrip()


if __name__ == "__main__":
    main()
