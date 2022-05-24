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
    return """\
    cd internal/scripts/Runner
    swift run runner {args}
    """.format(args = args)
