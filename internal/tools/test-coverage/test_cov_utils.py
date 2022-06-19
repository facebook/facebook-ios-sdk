#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import os
import re
import sys
from subprocess import PIPE, Popen

import test_cov_constants as tcc


"""
Provides a set of helpers for test coverage scripts.
"""


def _gcovr_options_for_mode(mode):
    if mode == "html":
        return ["--html", "--html-details"]
    if mode == "xml":
        return ["--xml-pretty"]
    return []


# Remove .gcda and .gcov files to clean up any vestigial coverage
def remove_coverage_files():
    args = ["find", tcc.buckout_dir, "-name", "*.gcda", "-delete"]
    run_shell_command(args)

    args = ["find", tcc.buckout_dir, "-name", "*.gcov", "-delete"]
    run_shell_command(args)


# Run buck test
def run_test(tests_file):
    args = [
        "buck",
        "test",
        "--no-cache",
        "--config",
        "user.code_coverage=true",
        "--config",
        "user.ls_enable_generation_of_test_target_if_target_doesnt_have_one=true",
        "--flagfile",
        tests_file,
    ]
    run_shell_command(args)


def fail(error):
    sys.stderr.write(
        "\n==================== Coverage Scripts Error ====================\n\n"
    )
    sys.stderr.write(error)
    sys.stderr.write("\n\n")
    sys.stderr.write("========================================================\n")
    sys.stderr.flush()
    sys.exit(1)


def _get_buck_out_dir(target):
    # logic to get paths for gcda and gcno files. This will be used as input parameters to gcovr report
    print("Getting buck out dir for: {}".format(target))
    args = [
        "buck",
        "targets",
        target,
        "--show-output",
        "--config",
        "user.ls_enable_generation_of_test_target_if_target_doesnt_have_one=true",
    ]
    output = run_shell_command(args)
    # output is in one line, for example:
    # //fbobjc/Apps/LightSpeed/Plugins/MSGGDPR:MSGGDPRPluginEntryPointsImplsTests buck-out/gen/ce9b6f2e/fbobjc/Apps/LightSpeed/Plugins/MSGGDPR:MSGGDPRPluginEntryPointsImplsTests#apple-test-bundle,dwarf,no-include-frameworks,no-linkermap/MSGGDPRPluginEntryPointsImplsTests.xctest
    if len(output) > 1:
        buck_out_location = output[1]
        print("buck_out_location {}".format(buck_out_location))

        # convert //fbobjc/Apps/LightSpeed/Plugins/MSGGDPR:MSGGDPRPluginTests to
        # /fbobjc/Apps/LightSpeed/Plugins/MSGGDPR
        sub_path = target.split(":")[0][1:]
        print("sub_path {}".format(sub_path))

        # convert buck-out/gen/ce9b6f2e/fbobjc/Apps/LightSpeed/Plugins/MSGGDPR/MSGGDPRPluginEntryPointsImplsTests/SomePath/SomePath to
        # buck-out/gen/ce9b6f2e/fbobjc/Apps/LightSpeed/Plugins/MSGGDPR
        buck_out_dir = buck_out_location.split(sub_path)[0] + sub_path
        print("buck_out_dir {}".format(buck_out_dir))
        return buck_out_dir
    print("Unexpected output after running buck targets: {}".format(output))
    return ""


# Find the locations for gcovr to locate coverage data files
# The coverage data files are created at where BUCK is defined for the module
# For example, if BUCK is at ~/fbsource/fbobjc/Apps/LightSpeed/Plugins/LSUserBlock,
# Then coverage data files will be at:
# ~/fbsource/fbobjc/buck-out/gen/<Hash>/fbobjc/Apps/LightSpeed/Plugins/LSUserBlock
def find_search_paths(tests):

    buck_out_dir_list = map(_get_buck_out_dir, tests)
    # remove duplicates
    buck_out_dir_list = list(dict.fromkeys(buck_out_dir_list))
    # create fbsource path, only if buck-out dir is valid
    search_paths = [
        os.path.join(tcc.fbsource_dir, path)
        for path in buck_out_dir_list
        if len(path) > 0
    ]
    print("paths to look for coverage data: {}".format(search_paths))
    return search_paths


def run_coverage_report(source_dir, output_file, search_paths, mode):
    arglist = [
        "buck",
        "run",
        "fbsource//third-party/gcovr:gcovr",
        "--",
        "-r",
        source_dir,
        "-o",
        output_file,
    ]
    arglist.extend(_gcovr_options_for_mode(mode))
    arglist.extend(tcc.exludes)
    arglist.extend([path for path in search_paths if os.path.exists(path)])
    run_shell_command(arglist)


# Parses the raw gcovr coverage reports to extract executed and total lines
def parse_coverage_report(report_txt):
    executed = {}
    lines = {}

    # Indicates if the name of the source file has been parsed
    name_parsed = False

    with open(report_txt) as f:
        # Skip the first 6 lines
        i = 0
        while i < 6:
            line = f.readline()
            i = i + 1
            if "Directory" in line:
                dir_name = _split_line(line)[1]

        while line:
            line = f.readline()
            # Skip the last few lines that contains --- and TOTAL
            if "-------" in line or "TOTAL" in line:
                continue

            # If there's only 1 field, then it will be source file name on its own line
            fields = _split_line(line)
            if len(fields) == 1:
                name_parsed = True
                name = dir_name + fields[0]
                continue

            # If name isn't on its own line, then it's together with coverage data
            if not name_parsed:
                name = dir_name + fields[0]

            # Extract the lines and executed counts
            name_parsed = False
            total = int(fields[1])
            ex = int(fields[2])

            # Add executed and lines to the dictionary
            if name in lines:
                executed[name] = executed[name] + ex
                lines[name] = lines[name] + total
            else:
                executed[name] = ex
                lines[name] = total

        return executed, lines


# Writes out a summary file
def write_summary(executed, lines, srcs, summary_file):
    with open(summary_file, "w") as f:
        total_executed = 0
        total_lines = 0

        for name in sorted(filter(lambda src: src in srcs, lines.keys())):
            total_executed = total_executed + executed[name]
            total_lines = total_lines + lines[name]

            f.write(_summary_str(name, executed[name], lines[name]))

        # write summary for all source files
        f.write(_summary_str("TOTAL", total_executed, total_lines))
        coverage_percent = (
            float(total_executed) / float(total_lines) * 100 if total_lines else 0
        )
        print("Summary for all source files.")
        print("Total lines executed: {}".format(total_executed))
        print("Total lines: {}".format(total_lines))
        print("Coverage Percent: {}%".format(round(coverage_percent, 2)))


def run_buck_query(operator, file=None, generate_empty_test_target=True):
    args = ["buck", "query"]
    args.append(operator)
    if generate_empty_test_target:
        args.append("--config")
        args.append("user.code_coverage=true")
        args.append("--config")
        args.append(
            "user.ls_enable_generation_of_test_target_if_target_doesnt_have_one=true"
        )
    if file is not None:
        args.append("--flagfile")
        args.append(file)
    return run_shell_command(args)


def run_shell_command(args):
    p = Popen(args, stdout=PIPE)
    result = p.communicate()[0].split()
    # strip the the new line characters
    return [element.strip().decode("utf-8") for element in result]


def shard_targets_into_buckets(total_buckets, bucket, targets):
    assert total_buckets > 0 and total_buckets <= len(targets), (
        "Input buckets was {}, which must be > 0 and <= the number of targets: {}"
    ).format(total_buckets, len(targets))

    assert bucket >= 0 and bucket < total_buckets, (
        "Input bucket was {}, which must be >= 0 "
        "and < the number of total buckets: {}"
    ).format(bucket, total_buckets)

    targets = targets[bucket::total_buckets]
    print("Running coverage script on targets: " + str(targets))
    return targets


def _split_line(line):
    # Replace multiple spaces with one and split by space
    line = re.sub("  *", " ", line).replace("\n", "")
    return line.split(" ")


def _summary_str(label, executed, lines):
    return format(
        "%s %d/%d %3.1f%% \n" % (label, executed, lines, executed * 100.0 / lines)
    )
