#!/usr/bin/env python3

import json
from common import *

ONCALL = 'fb_mobile_sdk_community_support'

my_job = [
    {
        "alias": "ios-sdk-xcodebuild-warnings",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Check for xcodebuild warnings",
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
                    "name": "Check for warnings",
                    "required": False,
                    "shell": "./scripts/check_for_xcodebuild_warnings.py",
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
