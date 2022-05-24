#!/usr/bin/env python3

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "ios-sdk-xcode-integration-verification",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Facebook iOS SDK: Ensure apps including the SDK still build. \
                        Note: If this fails, try building 'testing/TestXcodeIntegration/TestXcodeIntegration.xcworkspace' locally",
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
                    "name": "Verify Xcode Integration",
                    "shell": "xcodebuild clean build -quiet \
                                -sdk iphonesimulator \
                                -workspace testing/TestXcodeIntegration/TestXcodeIntegration.xcworkspace \
                                -scheme TestXcodeIntegration",
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
