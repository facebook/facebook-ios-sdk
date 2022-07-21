#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "meta-sdk-swiftlint-check",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Runs swiftlint on the Meta SDK",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["meta-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Lint",
                    "shell": "cd internal/MetaSDK && ../tools/swiftlint --strict",
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
