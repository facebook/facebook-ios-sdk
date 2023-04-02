/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKCrashHandlerProtocol.h>
#import <FBSDKCoreKit_Basics/FBSDKCrashObserving.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashHandler)
@interface FBSDKCrashHandler : NSObject <FBSDKCrashHandler>

@property (class, nonatomic, readonly) FBSDKCrashHandler *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)disable;
+ (void)addObserver:(id<FBSDKCrashObserving>)observer;
+ (void)removeObserver:(id<FBSDKCrashObserving>)observer;
+ (void)clearCrashReportFiles;
+ (NSString *)getFBSDKVersion;
- (void)saveException:(NSException *)exception;

- (void)disable;

@end

NS_ASSUME_NONNULL_END
