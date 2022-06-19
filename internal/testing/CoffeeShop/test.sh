#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

xcodebuild test -workspace CoffeeShop.xcworkspace -scheme CoffeeShop -destination 'platform=iOS Simulator,name=iPhone X,OS=11.2'
