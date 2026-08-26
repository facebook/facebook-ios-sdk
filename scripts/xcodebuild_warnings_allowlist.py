# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

XCODEBUILD_WARNINGS_ALLOWLIST = [
    "warning: Input PNG is already optimized for iPhone OS.  Copying source file to destination...",
    # Pika Warnings:
    "warning: failed to load toolchain: could not find Info.plist in /Users/facebook/Library/Developer/Toolchains/pika-",
    # Deprecation Warnings:
    "is deprecated and will be removed in the next major release",
    "warning: Building targets in manual order is deprecated",
    "warning: 'prefer_self_in_static_references' is not a valid rule identifier",
    "warning: 'web' is deprecated: The web sharing mode is deprecated. Consider using automatic sharing mode instead.",
    "warning: 'feedWeb' is deprecated: The feed web sharing mode is deprecated. Consider using automatic sharing mode instead.",
    "warning: 'feedBrowser' is deprecated: The feed browser sharing mode is deprecated. Consider using automatic or browser sharing modes instead.",
    # Build system warnings (Xcode 16+):
    "warning: tasks in 'Copy Headers' are delayed by unsandboxed script phases",
    # Toolchain noise, emitted per-target regardless of anything in this repo:
    "Metadata extraction skipped. No AppIntents.framework dependency found.",
    # The vendored SwiftLint is too old to load the current sourcekitd, so its build
    # phase prints this and the build carries on. Remove once SwiftLint is upgraded --
    # until then the rules needing sourcekitd are silently not running.
    "Fatal error: Loading sourcekitd.framework",
]

# Anything not matched above is compared against scripts/xcodebuild_warnings_baseline.txt.
# Prefer the baseline for real warnings: an allowlist entry is a pattern that suppresses
# every future instance too, which is how this check stopped catching anything.
