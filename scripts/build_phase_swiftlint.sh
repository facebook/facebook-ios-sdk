#!/bin/sh
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

IOS_SDK_KIT_DIR=${PWD##*/} # The name of the current dir
cd .. # to use .swiftlint.yml from the parent directory

if [ -f ../Tools/swiftlint/swiftlint ]; then
  ../Tools/swiftlint/swiftlint lint "$IOS_SDK_KIT_DIR" "$@"
elif which swiftlint >/dev/null; then
  swiftlint lint "$IOS_SDK_KIT_DIR" "$@"
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
