#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import os


fbsource_dir = os.popen("hg root").read().strip() + "/"
fbobjc_dir = os.path.join(fbsource_dir, "fbobjc/")
buckout_dir = os.path.join(fbsource_dir, "buck-out/")

exludes = [
    "-e",
    ".*[Tt]est.*",
    "-e",
    ".*buck-out.*",
    "--gcov-exclude",
    ".*buck-out.*",
    "--gcov-exclude",
    ".*remodel-header-gen.*",
    "--gcov-exclude",
    ".*APPLE_DEVELOPER_DIR.*",
    "--gcov-exclude",
    ".*APPLE_SDKROOT.*",
    "--gcov-exclude",
    ".*APPLE_PLATFORM_DIR.*",
]

xplat = "xplat"
