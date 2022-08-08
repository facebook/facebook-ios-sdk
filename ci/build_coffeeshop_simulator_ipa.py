#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "build-coffeeshop-simulator-ipa",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Builds a CoffeeShop IPA",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk"],
        "args": {
            "oncall": ONCALL,
            "steps": [
                {
                    "name": "Build CoffeeShop for Simulator",
                    "provide_artifacts": [
                        {
                            "name": "CoffeeShop IPA",
                            "paths": ["internal/testing/CoffeeShop/build/CoffeeShop.ipa"],
                            "required": True,
                        },
                    ],
                    "shell": """
                        cd internal/testing/CoffeeShop
                        ./generate-projects.sh || exit 1

                        # Build the project
                        xcodebuild build -project CoffeeShop.xcodeproj \
                            -scheme CoffeeShop \
                            -derivedDataPath build \
                            -sdk iphonesimulator \
                            -configuration Release \
                        || exit 1

                        # Make it looks like an ipa so idb will install it onto a simulator
                        mkdir -p build/CoffeeShop/Payload
                        mv build/Build/Products/Release-iphonesimulator/CoffeeShop.app build/CoffeeShop/Payload
                        cd build
                        zip -r CoffeeShop.ipa CoffeeShop/
                    """,
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
