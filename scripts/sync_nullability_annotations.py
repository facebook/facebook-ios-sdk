#!/usr/bin/env fbpython
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import os
import pathlib
import re
import subprocess
import sys
from typing import List, Optional


def find_m_file_for_h_file(h_file_path, all_m_files):
    # Check in the same folder
    m_file_path = h_file_path.replace(".h", ".m")
    if os.path.exists(m_file_path):
        return m_file_path

    # Check in the whole project
    m_file_basename = os.path.basename(h_file_path).replace(".h", ".m")

    # How many implementations file have this name?
    matches = [f for f in all_m_files if f.endswith(m_file_basename)]
    matches_count = len(matches)

    if matches_count == 1:
        return matches[0]

    # Finding 0 matches is fine since many header files won't match a corresponding m file, ex TestTools-Bridging-Header.h
    # but finding more than one match would be weird
    if matches_count > 1:
        print(f"More than one match found for {m_file_basename}. Matches: {matches}")
    return None


def main():
    base_dir = determine_base_dir()
    os.chdir(base_dir)

    all_h_files = get_files_with_extension("*.h")
    all_m_files = get_files_with_extension("*.m")

    print(f"Found {len(all_h_files)} '*.h' files and {len(all_m_files)} '*.m' files")

    for h_file_path in all_h_files:
        # key: method name with newlines and nullable removed
        # value: the original method
        method_map = {}

        m_file_path = find_m_file_for_h_file(h_file_path, all_m_files)

        if not m_file_path:
            # Many .h files won't have a corresponding .m file, example bridging header
            continue

        if m_file_path in all_m_files:
            all_m_files.remove(m_file_path)
        else:
            print(f"Path exists: {m_file_path} but was not found in 'all_m_files'")

        h_file_text = read_text_from_file(h_file_path)
        m_file_text = read_text_from_file(m_file_path)

        # For each method definition in the .h file, add it to the method_map
        for match in re.finditer(
            r"^([+-].*?);$", h_file_text, flags=re.MULTILINE | re.DOTALL
        ):
            method_declaration = match.group(1)
            method_declaration = re.sub(
                r"\n(NS_SWIFT_NAME|NS_SWIFT_UNAVAILABLE).*", "", method_declaration
            )
            key_for_method = key_for_method_declaration(method_declaration)

            if method_declaration != key_for_method:
                method_map[key_for_method] = method_declaration

        # For each method definition in the .m file, replace it from the method_map
        updated_m_file_text = m_file_text
        for match in re.finditer(
            r"^([+-].*?)\n{$", m_file_text, flags=re.MULTILINE | re.DOTALL
        ):
            method_declaration = match.group(1)
            key_for_method = key_for_method_declaration(method_declaration)

            if key_for_method in method_map:
                method_definition_from_header = method_map[key_for_method]
                updated_m_file_text = updated_m_file_text.replace(
                    method_declaration, method_definition_from_header
                )

        if updated_m_file_text != m_file_text:
            write_text_to_file(updated_m_file_text, m_file_path)

    # unmatched_m_files = [f for f in all_m_files if not f.endswith("Tests.m")]
    # unmatched_m_files.remove("FBSDKCoreKit/FBSDKCoreKitTests/Internal/AppEvents/ViewHierarchy/ObjCTestObject.m")
    # print(unmatched_m_files)


def read_text_from_file(file: str) -> str:
    with open(file, "r") as f:
        text = f.read()
    return text


def write_text_to_file(text: str, file: str) -> None:
    with open(file, "w") as f:
        f.write(text)


def key_for_method_declaration(method_declaration: str) -> str:
    # Remove nullability keywords
    key = method_declaration.replace("nullable ", "").replace(" _Nullable ", " ")
    # Remove newlines
    key = re.sub(r"\s*\n\s*", " ", key, flags=re.MULTILINE | re.DOTALL)
    return key


def determine_base_dir() -> str:
    base_dir = get_output("git rev-parse --show-toplevel")
    if not base_dir:
        this_file_dir = os.path.dirname(os.path.realpath(__file__))
        base_dir = str(pathlib.Path(this_file_dir).parent.absolute())
    return base_dir


def get_files_with_extension(extension: str) -> List[str]:
    files_str = get_output(f"git ls-files '{extension}'")
    if not files_str:
        files_str = get_output(f"hg files -I '**/{extension}'")
        if not files_str:
            print(f"No files found with extension: {extension}", file=sys.stderr)
            sys.exit(1)

    files = files_str.splitlines()

    filtered_files = [f for f in files if not f.startswith(("samples", "testing"))]
    return filtered_files


def write_lines_to_file(lines: List[str], file: str) -> None:
    with open(file, "w") as f:
        f.writelines(lines)


def get_output(command: str) -> Optional[str]:
    """Returns the output of a shell command, or None if it fails"""
    completed_process = subprocess.run(
        command, shell=True, check=False, capture_output=True
    )

    if completed_process.returncode != 0:
        # Uncomment for debugging
        # print(f"Failed: {command}"\nSTDERR: {completed_process.stderr.decode()}")
        return None

    return completed_process.stdout.decode().rstrip()


if __name__ == "__main__":
    main()
