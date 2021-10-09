#!/usr/bin/env fbpython
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

import os
import pathlib
import subprocess
import sys

ALLOWLISTED_WARNINGS = [
    "warning: implicit import of bridging header 'TestTools-Bridging-Header.h' via module 'TestTools' is deprecated and will be removed in a later version of Swift",
    "warning: Input PNG is already optimized for iPhone OS.  Copying source file to destination...",
    "warning: failed to load toolchain: could not find Info.plist in /Users/facebook/Library/Developer/Toolchains/pika-11-macos-noasserts.xctoolchain",
]


def main():
    base_dir = git_base_dir() if is_git_dir() else generic_base_dir()
    os.chdir(base_dir)

    xcodebuild_command = " ".join(
        [
            "xcodebuild clean build-for-testing",
            "-workspace FacebookSDK.xcworkspace",
            "-scheme BuildAllKits-Dynamic",
            "-destination 'platform=iOS Simulator,name=iPhone 12,OS=14.5'",
        ]
    )

    completed_process = subprocess.run(
        xcodebuild_command, shell=True, check=False, capture_output=True
    )

    output_lines = completed_process.stdout.decode().splitlines()

    all_warning_lines = {
        line for line in output_lines if "warning: " in line or "error: " in line
    }

    warnings_without_base_dir = [
        line.replace(f"{base_dir}/", "") for line in all_warning_lines
    ]

    not_allowlisted_warnings_without_base_dir = []

    for warning in warnings_without_base_dir:
        can_ignore = any(
            ignorable_text in warning for ignorable_text in ALLOWLISTED_WARNINGS
        )
        if not can_ignore:
            not_allowlisted_warnings_without_base_dir.append(warning)

    # If there are warnings print an issue and exit
    if not_allowlisted_warnings_without_base_dir:
        print("\nTHE FOLLOWING NON-ALLOWLISTED WARNINGS WERE ENCOUNTERED:")
        for i, warning in enumerate(not_allowlisted_warnings_without_base_dir, start=1):
            print(f"{i}. {warning}")

        warning_count = len(not_allowlisted_warnings_without_base_dir)
        print_to_stderr(f"FAILED DUE TO {warning_count} NON-ALLOWLISTED WARNINGS")
        filename = sys.argv[0]
        print_to_stderr(
            f"If any of these warnings should be ALLOWLISTED, add them to ALLOWLISTED_WARNINGS in {filename} and include a member of the Platform SDKs team on the diff review."
        )

        sys.exit(1)

    if completed_process.returncode != 0:
        print(f"Failed to run xcodebuild. Return code: {completed_process.returncode}")
        print(f"STDERR: {completed_process.stderr.decode()}")
        sys.exit(completed_process.returncode)

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
