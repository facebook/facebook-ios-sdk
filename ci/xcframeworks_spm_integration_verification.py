#!/usr/bin/env python3

import json
from common import *

ONCALL = 'platform_sdks'

my_job = [
    {
        "alias": "ios-sdk-xcframeworks-spm-integration-verification",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Archives a test app whose test app points to local xcframework binaries via SPM",
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
                        "name": "Build XCFrameworks",
                        "shell": swift_run_runner("build xcframeworks --linking static"),
                    },
                    {
                        "name": "Build Sample Project - iOS",
                        "shell": r"""
                            mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/
                            cp internal/tools/provisioning-profiles/XCFrameworkSPMIntegration_Local_Development_c394e727-d504-4194-b5e9-546787c78e50.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
                            cd testing/XCFrameworkSPMIntegration
                            export USE_LOCAL_FB_BINARIES=1
                            xcodebuild archive -scheme XCFrameworkSPMIntegration
                            rm ~/Library/MobileDevice/Provisioning\ Profiles/XCFrameworkSPMIntegration_Local_Development_c394e727-d504-4194-b5e9-546787c78e50.mobileprovision
                          """,
                    },
            ],
        },
    }
]

print(json.dumps(my_job, indent=4))
