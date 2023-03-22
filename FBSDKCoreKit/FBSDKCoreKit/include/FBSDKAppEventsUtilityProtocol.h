/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushReason.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsUtilityProtocol)
@protocol FBSDKAppEventsUtility

@property (nonatomic, readonly) NSTimeInterval unixTimeNow;

- (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className;
- (NSTimeInterval)convertToUnixTime:(nullable NSDate *)date;
- (BOOL)validateIdentifier:(nullable NSString *)identifier;
- (nullable NSString *)tokenStringToUseFor:(nullable FBSDKAccessToken *)token
                      loggingOverrideAppID:(nullable NSString *)loggingOverrideAppID;
- (NSString *)flushReasonToString:(FBSDKAppEventsFlushReason)flushReason;
- (void)saveCampaignIDs:(NSURL *)url;
- (nullable NSString *)getCampaignIDs;

@end

NS_ASSUME_NONNULL_END
