#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

SWIFTLINT_PATH=../../tools/swiftlint
SWIFTFORMAT_PATH=../../tools/swiftformat

if [ -n "$SWIFTLINT_PATH" ]; then
  $SWIFTLINT_PATH lint --autocorrect
  $SWIFTLINT_PATH lint --autocorrect ../../MetaSDK
  $SWIFTLINT_PATH lint
  $SWIFTLINT_PATH lint ../../MetaSDK
else
  echo "warning: SwiftLint not installed, Install with 'brew install swiftlint' or from https://github.com/realm/SwiftLint"
fi

if [ -n "$SWIFTFORMAT_PATH" ]; then
  $SWIFTFORMAT_PATH --lint
  $SWIFTFORMAT_PATH --lint ../../MetaSDK
else
  echo "warning: SwiftFormat not installed. Install with 'brew install swiftformat' or from https://github.com/nicklockwood/SwiftFormat"
fi
