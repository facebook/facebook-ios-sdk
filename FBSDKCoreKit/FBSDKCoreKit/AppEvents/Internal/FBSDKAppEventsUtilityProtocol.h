/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKCoreKit/FBSDKAppEventsFlushReason.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsUtilityProtocol)
@protocol FBSDKAppEventsUtility

@property (nonatomic, readonly) NSTimeInterval unixTimeNow;

- (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className;
- (NSTimeInterval)convertToUnixTime:(nullable NSDate *)date;
- (BOOL)validateIdentifier:(nullable NSString *)identifier;
- (nullable NSString *)tokenStringToUseFor:(nullable FBSDKAccessToken *)token
                      loggingOverrideAppID:(nullable NSString *)loggingOverrideAppID;
- (NSString *)flushReasonToString:(FBSDKAppEventsFlushReason)flushReason;

@end

NS_ASSUME_NONNULL_END
