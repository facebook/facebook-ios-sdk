#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import os
import shutil


"""
Provides a set of helpers for writing/reading files.
"""


# Clean up the output directory
def clean_dir(dir):
    if os.path.exists(dir):
        shutil.rmtree(dir)

    os.makedirs(dir)


def write_list_to_file(file, list, quoted_names=False):
    with open(file, "w") as f:
        for item in list:
            # as best practice, add quotes for files used by buck query
            # otherwise buck query won't work if line contains "+"
            if quoted_names:
                f.write('"{}"\n'.format(item))
            else:
                f.write("{}\n".format(item))
