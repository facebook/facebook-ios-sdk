#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'fb_mobile_sdk_community_support'

my_job = [
    {
        "alias": "ios-sdk-swiftlint-check",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Runs swiftlint on the Meta SDK",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Lint",
                    "shell": "internal/tools/swiftlint --strict",
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
