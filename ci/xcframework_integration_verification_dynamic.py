#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "ios-sdk-xcframeworks-integration-verification-dynamic",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Builds the dynamic XCFrameworks and integrates them into two sample projects",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Generate Project files",
                    "shell": "./internal/scripts/generate-projects.sh",
                },
                {
                    "name": "Build XCFrameworks",
                    "shell": swift_run_runner("build xcframeworks"),
                },
                {
                    "name": "Verify License Inclusion",
                    "shell": """
                        cd build/XCFrameworks/Dynamic/FBSDKCoreKit.xcframework || exit 1; \
                        if test -f "./LICENSE"; then \
                            echo 'License file found in build artifact'; \
                        else \
                            echo 'License file not found in build artifact'; exit 1; \
                        fi
                    """,
                },
                {
                    "name": "Build Sample Project - iOS",
                    "shell": "cd internal/testing/IntegrateXCFrameworksApp/iOS-Dynamic && \
                        xcodebuild -sdk iphonesimulator",
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
