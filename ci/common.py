#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

def ios_sdk_capabilities(**kwargs):
    capabilities = {
        "tenant": "ios_diff",
        "type": "lego-mac",
        "vcs": "facebook-ios-sdk-git"
    }
    capabilities.update(kwargs)
    return capabilities

def swift_run_runner(args):
    return python.dedent(
        """\
    cd internal/scripts/Runner
    swift run --build-path=`mkscratch path` runner {args}
    """.format(args = args),
    )
