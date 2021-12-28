/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKCrashObserving;

NS_SWIFT_NAME(CrashHandlerProtocol)
@protocol FBSDKCrashHandler

- (void)addObserver:(id<FBSDKCrashObserving>)observer;
- (void)clearCrashReportFiles;

@end

NS_ASSUME_NONNULL_END
