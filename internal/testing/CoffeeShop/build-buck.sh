#!/bin/bash
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

REPO_ROOT=$(dirname "$0")/../../../..
exec "$REPO_ROOT/Tools/build-buck.py" \
  --buck-app-target //fbobjc/ios-sdk/internal/testing/CoffeeShop:CoffeeShop \
  --buck-flagfile "fbsource//fbobjc/mode/an-debug" \
  --buck-msdk-dependency-target //fbobjc/msdk:jackalope \
  "$@"
