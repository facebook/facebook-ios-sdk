#!/usr/bin/env python3

import json
from common import *

ONCALL = 'platform_sdks'

def analyze(scheme, configuration, artifact_name):
    """
    If there are analyzer issues, then we grep the next 10 lines after the
    'analyzer issues' line is found
    """
    return "xcodebuild clean analyze \
                -workspace FacebookSDK.xcworkspace \
                -scheme {} \
                -configuration {} \
                >| tmp.txt 2>&1 && \
                if grep -q 'analyzer issues' tmp.txt; \
                then grep_command_output=$(grep -A 10 'analyzer issues' tmp.txt); \
                echo \"Please run Product > Analyze in Xcode to see the analyzer warnings\"; \
                echo \"$grep_command_output\"; \
                mv tmp.txt {}.txt; \
                exit 1; \
                fi;".format(scheme, configuration, artifact_name)

my_job = [
    {
        "alias": "ios-sdk-xcode-analyzer",
        "capabilities": ios_sdk_capabilities(),
        "command": "SandcastleUniversalCommand",
        "description": "Analyze command",
        "oncall": ONCALL,
        "priority": 0,
        "tags": ["facebook-ios-sdk", "xcodebuild"],
        "args": {
        "oncall": ONCALL,
        "steps": [
            {
                "name": "Generate Project files",
                "shell": "./internal/scripts/generate-projects.sh",
            },
            {
                "name": "Analyze All Kits",
                "provide_artifacts": [
                    {
                        "name": "Analyzer Output for all kits",
                        "paths": ["allKitsOutput.txt"],
                        "required": False,
                        "upload_when": ["USER_ERROR"],
                    },
                ],
                "shell": analyze("BuildAllKits-Dynamic", "Debug", "allKitsOutput"),
            },
        ],
        },
    }
]

print(json.dumps(my_job, indent=4))
