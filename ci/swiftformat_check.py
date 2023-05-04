#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'fb_mobile_sdk_community_support'


my_job = [
    {
        "alias": "facebook-ios-sdk-swiftformat-check",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Runs swiftformat on the Facebook iOS SDK",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Format SDK",
                    "shell": """
                        internal/tools/swiftformat .

                        if [ -z "$(git status --porcelain)" ]; then
                            exit 0;
                        else
                            echo "Please run swiftformat and resubmit these changes";
                        exit 1;
                        fi
                        """
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
