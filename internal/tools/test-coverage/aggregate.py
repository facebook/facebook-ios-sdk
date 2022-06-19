#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import glob
import os
import sys
from datetime import date
from enum import Enum
from subprocess import PIPE, Popen

import file_utils
import test_cov_constants as tcc


class InputType(Enum):
    library = 0
    plugin = 1


def get_arguments():
    args = sys.argv
    assert (
        len(args) > 1
    ), "Please supply an output dir \
    E.g. ~/coverage_all"

    return args[1:][0]


def read_build_paths(build_paths_file):
    build_paths = {}
    with open(build_paths_file) as f:
        line = f.readline()
        while line:
            fields = line.strip("\n").split(",")
            build_paths[fields[0]] = fields[1]
            line = f.readline()
    return build_paths


def write_summary(
    input_dir,
    build_paths_file,
    build_paths,
    output_file,
):
    with open(output_file, "w") as f:
        f.write("ds,name,covered_lines,total_lines\n")
        for file_path in glob.glob(os.path.join(input_dir, "*.txt")):
            if build_paths_file in file_path:
                continue

            module_name = os.path.splitext(os.path.basename(file_path))[0]

            executed, lines = parse_coverage(file_path)
            f.write(summary_str(module_name, executed, lines))


def parse_coverage(filename):
    executed = 0
    lines = 0
    with open(filename) as f:
        line = f.readline()
        while line:
            name, ex, total = read_coverage_line(line)
            if "TOTAL" in name:
                line = f.readline()
                continue
            executed = executed + ex
            lines = lines + total
            line = f.readline()
    return executed, lines


def read_coverage_line(line):
    fields = line.strip().split(" ")
    assert len(fields) == 3, "Coverage line incorrectly formatted: {}".format(line)

    name = fields[0]
    nums = fields[1].split("/")
    return name, int(nums[0]), int(nums[1])


def summary_str(label, executed, lines):
    return format(
        "%s,%s,%d,%d\n"
        % (
            str(date.today()),
            label,
            executed,
            lines,
        )
    )


def summary_total_str(rollup, executed, lines, input_type, rollup_type):
    return format(
        "%s,%s,%d,%d,%s,%s\n"
        % (str(date.today()), rollup, executed, lines, input_type.name, rollup_type)
    )


def run_shell_command(args):
    p = Popen(args, stdout=PIPE)
    result = p.communicate()[0].split()
    # strip the the new line characters
    return [element.strip().decode("utf-8") for element in result]


def filter_module_path(path):
    # Filter out paths that don't have BUCK target
    # otherwise coverage will be double counted if we have
    # both pluginA and pluginA/pluginA registered in CQA
    buck_file_path = get_buck_file_path(path)
    return os.path.exists(buck_file_path)


def get_buck_file_path(path):
    # Path is /Apps/LightSpeed/Plugins/LSUserBlock
    full_path = os.path.join(tcc.fbobjc_dir, path.lstrip("/"))
    return os.path.join(full_path, "BUCK")


def get_coverage_data_dir_name(input_type):
    return "LibrariesCoverage"


top_level_dir = get_arguments()
coverage_data_dir = os.path.join(top_level_dir, "LibrariesCoverage")
build_paths_file = os.path.join(coverage_data_dir, "build_paths.txt")

output_dir = os.path.join(top_level_dir, "AggregatedReports", "library")
summary_file = os.path.join(output_dir, "summary.txt")

file_utils.clean_dir(output_dir)
build_paths = read_build_paths(build_paths_file)

write_summary(
    coverage_data_dir,
    build_paths_file,
    build_paths,
    summary_file,
)
