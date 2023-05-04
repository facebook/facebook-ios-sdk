#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'fb_mobile_sdk_community_support'

my_job = [
    {
        "alias": "swift-interface-check",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Checks if the Swift interface has changed between revisions",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Check for Swift interface changes",
                    "shell": "./internal/scripts/verify_swift_interface_across_revisions.py",
                    "required": False,
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
