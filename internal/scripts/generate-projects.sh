#!/bin/bash
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

cd $( git rev-parse --show-toplevel ) || exit

# The xcodegen binary is only built for macOS. It fails on linux with: "cannot execute binary file"

if [ "$(uname -s)" != Darwin ]; then
    echo "Merge conflict detected. The merge driver only works on macOS. Please rebase locally against master (not fbobjc/stable)" 1>&2
    exit 1
fi

./internal/tools/xcodegen generate -s internal/testing/E2EUtils/project.yml
./internal/tools/xcodegen generate -s TestTools/project.yml
./internal/tools/xcodegen generate -s FBSDKCoreKit_Basics/project.yml
./internal/tools/xcodegen generate -s FBAEMKit/project.yml
./internal/tools/xcodegen generate -s FBSDKCoreKit/project.yml
./internal/tools/xcodegen generate -s FBSDKLoginKit/project.yml
./internal/tools/xcodegen generate -s FBSDKShareKit/project.yml
./internal/tools/xcodegen generate -s FBSDKGamingServicesKit/project.yml
