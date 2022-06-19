#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import argparse
import os
import re

import file_utils as fu
import test_cov_constants as tcc
import test_cov_utils as tcu


# Retrieve the library from argument
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "target",
        help="Path to build target. E.g. //ios-sdk:",
    )
    parser.add_argument("output_dir", help="Top level output dir. E.g. ~/coverage_all")
    parser.add_argument(
        "--html_report", help="Generates html report", action="store_true"
    )
    parser.add_argument("--xml", help="Generates xml report", action="store_true")
    return parser.parse_args()


# Find all the test targets to run buck test with
def find_tests(library):
    # Example of a command to find tests
    # buck query "kind(apple_test, testsof("//ios-sdk:"))"
    testsof_operator = "kind(apple_test, testsof({}))".format(library)
    return tcu.run_buck_query(testsof_operator)


# Find all the source files (srcs, headers, and exported_headers) of plugin dependencies
def find_srcs(srcs_input):
    # input is //Apps/LightSpeed/Libraries/LightSpeedAccessibility:
    srcs_operator = "labels(srcs, {})".format(srcs_input)
    srcs = tcu.run_buck_query(srcs_operator)
    return [tcc.fbsource_dir + src for src in srcs]


def filter_srcs_based_on_library_name(srcs_input, srcs):
    # input is //Apps/LightSpeed/Libraries/LightSpeedAccessibility:
    lib_name = re.split("/|:", srcs_input)[-1][:-1]
    srcs = list(filter(lambda src: filter_srcs_function(src, lib_name), srcs))
    return srcs


# Retains only source files that has ".[a-z]+" pattern
# e.g. .m, .h, .mm, .c, etc.
def filter_srcs_function(src, lib_name):
    if lib_name in src:
        if re.match(r".+\.[m]+$", src) or re.match(r".+\.[mm]+$", src):
            return True
    return False


# Get arguments
args = parse_args()
library = args.target
output_dir = args.output_dir

# Clean up the directories so we have a fresh start
fu.clean_dir(output_dir)
tcu.remove_coverage_files()

tests_file = os.path.join(output_dir, "tests.txt")
srcs_file = os.path.join(output_dir, "srcs.txt")
summary_file = os.path.join(output_dir, "summary.txt")
report_txt = os.path.join(output_dir, "report.txt")
report_html = os.path.join(output_dir, "report.html")
report_xml = os.path.join(output_dir, "report.xml")

# Find test targets
tests = find_tests(library)
if len(tests) == 0:
    tcu.fail("Skipping summary for: {} because there are no tests".format(library))

fu.write_list_to_file(tests_file, tests)

# Find source files of the dependencies
srcs = find_srcs(library)
srcs = filter_srcs_based_on_library_name(library, srcs)
fu.write_list_to_file(srcs_file, srcs, quoted_names=True)

# Some tests can fail, so handling the exceptions
print("Started running tests")
try:
    tcu.run_test(tests_file)
except Exception:
    tcu.fail("Exception when running tests of :{}".format(library))
print("Completed running tests")

paths = tcu.find_search_paths(tests)

print("Start running coverage report")
if args.html_report:
    tcu.run_coverage_report(tcc.fbsource_dir, report_html, paths, "html")

if args.xml:
    tcu.run_coverage_report(tcc.fbsource_dir, report_xml, paths, "xml")
# Get report in txt format
tcu.run_coverage_report(tcc.fbsource_dir, report_txt, paths, "txt")
# Parse the gcovr reports
print("Completed running coverage report")

executed, lines = tcu.parse_coverage_report(report_txt)
print("Completed parsing coverage report")
# Writes out a summary file
tcu.write_summary(executed, lines, srcs, summary_file)

print("Code Coverage report was generated successfully")

print("Coverage data       :{}".format(report_txt))

if args.html_report:
    print("Coverage html       :{}".format(report_html))

print('run "open {}" - to get detailed reports'.format(output_dir))
