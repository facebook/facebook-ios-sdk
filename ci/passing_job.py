#!/usr/bin/env python3

import json

oncall = 'ci_experiences'

my_job = [
    {
        "command": "SandcastleUniversalCommand",
        "alias": "test-passing-ci-job",
        "oncall": oncall,
        "description": "testing yay",
        "priority": 0,
        "capabilities" : {
            "type": "lego",
            "vcs": "facebook-ios-sdk-git"
        },
        "hash": "main",
        "args": {
            "steps": [
                {
                    "name": "pass",
                    "shell": "sleep 10"
                }
            ]
        }
    }
]

print(json.dumps(my_job, indent=4))
