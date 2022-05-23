#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#  This is hacky and due to an issue where lego_mac machines are finding
#  duplicate simulators for iPhone N.
#  We can likely get rid of this hack when the issue is resolved. See:
#  https://fb.workplace.com/groups/sandcastleqna/permalink/8576712272377312/

from dataclasses import dataclass
import json
import subprocess
import sys
import time

def log_to_stderr(message: str) -> None:
    print(message, file=sys.stderr)

class ExternalTools:
    XCRUN: str = "/usr/bin/xcrun"

    @dataclass
    class Result:
        return_code: int
        stdout: str
        stderr: str

    @classmethod
    def run(
        cls, path: str, args: [str], check: bool = True, input: [str] = None
    ) -> Result:
        run_args = [path] + args
        log_to_stderr("Executing external tool: " + " ".join(run_args))

        start_time = time.time()
        completed_process = subprocess.run(
            run_args, capture_output=True, check=check, encoding="utf-8", input=input
        )

        log_to_stderr(
            f"Started at '{start_time}'. Duration: '{time.time() - start_time}'"
        )
        if completed_process.returncode != 0:
            log_to_stderr(f"Return code: {completed_process.returncode}")
            log_to_stderr(f"Stdout: {completed_process.stdout[:255]}")
            log_to_stderr(f"Stderr: {completed_process.stderr[:255]}")

        return ExternalTools.Result(
            completed_process.returncode,
            completed_process.stdout,
            completed_process.stderr,
        )

    @classmethod
    def runAndParseJson(cls, path: str, args: [str]) -> [[str, object()]]:
        result = cls.run(path, args, check=False)
        if result.return_code != 0:
            return None

        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return None


def getSimulatorId(destination: str) -> str:
    # xcodebuild fails if there are more than one applicable destinations.
    # In this case, we need to chose any of them.
    unsupported_message = "Unsupported destination format. Only 'name=...' is supported."
    log_to_stderr(f"Requested destination: {destination}.")

    name_spec = destination.split("=")
    if len(name_spec) != 2:
        raise Exception(unsupported_message)

    # 'name=...'
    if name_spec[0] == "name":
        output = ExternalTools.runAndParseJson(
            ExternalTools.XCRUN,
            ["simctl", "list", "--json", "devices", "available"],
        )
        if output is None:
            raise Exception("Device listing failed.")

        devices = [
            device
            for runtime in output["devices"].values()
            for device in runtime
            if device["name"] == name_spec[1]
        ]
        if len(devices) == 0:
            raise Exception("No suitable devices found.")

        if len(devices) > 1:
            log_to_stderr(
                f"{len(devices)} suitable devices found. Using the first one."
            )

        log_to_stderr(f"Selected device: {devices[0]}")
        return devices[0]["udid"]

    # Unsupported destination selector
    raise Exception(unsupported_message)

# TODO: Figure out a better way to pass in specific versions from the other commands
iphone_12 = getSimulatorId("name=iPhone 12")

print(iphone_12)
