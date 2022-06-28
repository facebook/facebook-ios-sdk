#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "update-legacy-hackbook",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleIOSSDKUpdateLegacyHackbookCommand",
        "description": "Checks for version bumps and adds that commit as the legacy hackbook version for end-to-end test",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "additional_vcs": [
                "fbobjc-fbsource"
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
