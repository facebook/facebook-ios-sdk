#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "build-hackbook-simulator-ipa",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Builds a Hackbook IPA",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Build Hackbook for Simulator",
                    "provide_artifacts": [
                        {
                            "name": "Hackbook IPA",
                            "paths": ["internal/testing/Hackbook/build/Hackbook.ipa"],
                            "required": True,
                        },
                    ],
                    "shell": """
                        cd internal/testing/Hackbook
                        ./generate-projects.sh || exit 1

                        # Build the project
                        xcodebuild build -project Hackbook.xcodeproj \
                            -scheme Hackbook \
                            -derivedDataPath build \
                            -sdk iphonesimulator \
                            -configuration Release \
                        || exit 1

                        # Make it looks like an ipa so idb will install it onto a simulator
                        mkdir -p build/Hackbook/Payload
                        mv build/Build/Products/Release-iphonesimulator/Hackbook.app build/Hackbook/Payload
                        cd build
                        zip -r Hackbook.ipa Hackbook/
                    """,
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
