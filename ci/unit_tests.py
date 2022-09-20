#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "ios-sdk-unit-tests",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Runs the Unit Tests defined in the FacebookSDK workspace",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk", "unit-tests"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Generate Project files",
                    "shell": "./internal/scripts/generate-projects.sh",
                },
                {
                    "name": "Run Unit Tests",
                    "shell": """
                        export DESTINATION_ID=$( python3 ci/simulator_selection.py | tail -1 );
                        xcodebuild test -workspace FacebookSDK.xcworkspace \
                            -scheme BuildAllKits-Dynamic \
                            -destination "id=$DESTINATION_ID"
                    """,
                },
            ],
        },
    },
    {
        "alias": "meta-sdk-unit-tests",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Runs the Unit Tests defined in the MetaSDK package",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["meta-ios-sdk", "unit-tests"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Run Unit Tests",
                    "shell": """
                        export DESTINATION_ID=$( python3 ci/simulator_selection.py | tail -1 );
                        cd internal/MetaSDK;
                        xcodebuild test \
                            -scheme MetaSDK \
                            -destination "id=$DESTINATION_ID"
                    """,
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
