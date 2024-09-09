# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

XCODEBUILD_WARNINGS_ALLOWLIST = [
    "warning: Input PNG is already optimized for iPhone OS.  Copying source file to destination...",
    # Pika Warnings:
    # "warning: failed to load toolchain: could not find Info.plist in /Users/facebook/Library/Developer/Toolchains/pika-11-macos-noasserts.xctoolchain",
    # "warning: failed to load toolchain: could not find Info.plist in /Users/facebook/Library/Developer/Toolchains/pika-13-macos-noasserts.xctoolchain",
    "warning: failed to load toolchain: could not find Info.plist in /Users/facebook/Library/Developer/Toolchains/pika-",
    # Deprecation Warnings:
    "is deprecated and will be removed in the next major release",
    "warning: Building targets in manual order is deprecated",
    "warning: 'prefer_self_in_static_references' is not a valid rule identifier",
    "warning: 'web' is deprecated: The web sharing mode is deprecated. Consider using automatic sharing mode instead.",
    "warning: 'feedWeb' is deprecated: The feed web sharing mode is deprecated. Consider using automatic sharing mode instead.",
]
