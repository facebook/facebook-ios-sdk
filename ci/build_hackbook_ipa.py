#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "build-hackbook-ipa",
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
                    "name": "Build Hackbook",
                    "provide_artifacts": [
                        {
                            "name": "Hackbook IPA",
                            "paths": ["internal/testing/Hackbook/build/Hackbook.ipa"],
                            "required": True,
                        },
                    ],
                    "shell": """
                        # Copy hackbook profile so xcodebuild can magically find it
                        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/
                        cp internal/tools/provisioning-profiles/Hackbook_Local_Development_9U4W97JX32.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/ || echo "Profile already exists at destination"

                        cd internal/testing/Hackbook
                        ./generate-projects.sh

                        # Archive the project
                        xcodebuild archive -project Hackbook.xcodeproj -scheme Hackbook -archivePath build/Hackbook

                        # Export the archive as an IPA
                        xcodebuild -exportArchive -archivePath build/Hackbook.xcarchive \
                            -exportPath build \
                            -exportOptionsPlist export.plist

                        # Clean up provisioning profile
                        rm ~/Library/MobileDevice/Provisioning\ Profiles/Hackbook_Local_Development_9U4W97JX32.mobileprovision
                    """,
                },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
