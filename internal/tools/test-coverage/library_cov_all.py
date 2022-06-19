#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import argparse
import os
import sys
from datetime import datetime
from random import shuffle
from shutil import copyfile

import file_utils as fu
import test_cov_utils as tcu


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "target", help="Path to build target. E.g. //Apps/LightSpeed:LightSpeedApp"
    )
    parser.add_argument("output_dir", help="Top level output dir. E.g. ~/coverage_all")
    parser.add_argument(
        "--limit-targets",
        action="store",
        default=None,
        const=None,
        type=int,
        nargs="?",
        dest="limit_targets",
        help="Only runs on N libraries",
    )
    parser.add_argument(
        "--buckets",
        action="store",
        default=None,
        const=None,
        type=int,
        nargs="?",
        dest="buckets",
        help="How many buckets to split the libraries into",
    )
    parser.add_argument(
        "--bucket",
        action="store",
        default=None,
        const=None,
        type=int,
        nargs="?",
        dest="bucket",
        help="Which bucket to run the script on",
    )
    return parser.parse_args()


def libraries_filter_function(library_path):
    return "//fbobjc/Apps/LightSpeed/Plugins" not in library_path


def run_coverage_script(library_targets, library_coverage_dir):
    print("Start: {}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
    temp_dir = os.path.join(library_coverage_dir, "temp")
    temp_library_summary = os.path.join(temp_dir, "summary.txt")
    for i, target in enumerate(sorted(library_targets), start=1):
        library_name = get_library_name(get_library_path(target))
        output_file = os.path.join(library_coverage_dir, library_name + ".txt")
        if os.path.exists(output_file):
            continue

        print(
            "Running coverage script for library {} of {}: {}".format(
                i, len(library_targets), target
            )
        )
        sys.stdout.flush()
        tcu.run_shell_command(["python", "library_cov.py", target, temp_dir])

        if os.path.exists(temp_library_summary):
            copyfile(temp_library_summary, output_file)
    print("Complete: {}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S")))


def write_build_paths(library_build_targets, paths_file):
    with open(paths_file, "w") as f:
        for build_target in sorted(library_build_targets):
            library_path = get_library_path(build_target)
            library_name = get_library_name(library_path)
            f.write("{},{}\n".format(library_name, library_path))


def get_library_path(build_target):
    # From //Apps/LightSpeed/Libraries/LightSpeedMIG:
    # to /Apps/LightSpeed/Libraries/LightSpeedMIG
    return build_target.replace("//", "/").replace(":", "")


def get_library_name(build_path):
    # From /Apps/LightSpeed/Libraries/LightSpeedMIG to LightSpeedMIG
    return os.path.basename(build_path)


args = parse_args()
build_target = args.target
output_dir = args.output_dir
library_coverage_dir = os.path.join(output_dir, "LibrariesCoverage")
paths_file = os.path.join(library_coverage_dir, "build_paths.txt")

fu.clean_dir(library_coverage_dir)
library_targets = [build_target]

# Write all build paths to txt, no matter whether or not bucketization
# and limited targets.
write_build_paths(library_targets, paths_file)

if args.limit_targets is not None:
    shuffle(library_targets)
    library_targets = library_targets[: args.limit_targets]
elif args.buckets is not None and args.bucket is not None and len(library_targets) > 0:
    library_targets = tcu.shard_targets_into_buckets(
        args.buckets, args.bucket, library_targets
    )

run_coverage_script(library_targets, library_coverage_dir)
