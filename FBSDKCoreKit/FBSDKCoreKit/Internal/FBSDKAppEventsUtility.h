/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppEventDropDetermining.h"
#import "FBSDKAppEventParametersExtracting.h"
#import "FBSDKAppEventsFlushReason.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKAccessToken;

NS_SWIFT_NAME(AppEventsUtility)
@interface FBSDKAppEventsUtility : NSObject <FBSDKAdvertiserIDProviding, FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (class, nonatomic, readonly) FBSDKAppEventsUtility *shared;
@property (nullable, nonatomic, readonly, copy) NSString *advertiserID;
@property (class, nonatomic, readonly, assign) NSTimeInterval unixTimeNow;
@property (class, nonatomic, readonly, assign) BOOL isDebugBuild;

+ (NSMutableDictionary<NSString *, id> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                    shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID;
+ (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className;
+ (NSString *)flushReasonToString:(FBSDKAppEventsFlushReason)flushReason;
+ (void)logAndNotify:(NSString *)msg allowLogAsDeveloperError:(BOOL)allowLogAsDeveloperError;
+ (void)logAndNotify:(NSString *)msg;
+ (nullable NSString *)tokenStringToUseFor:(nullable FBSDKAccessToken *)token;
+ (BOOL)validateIdentifier:(nullable NSString *)identifier;
+ (BOOL)shouldDropAppEvent;
+ (BOOL)isSensitiveUserData:(NSString *)text;
+ (BOOL)isStandardEvent:(nullable NSString *)event;
+ (NSTimeInterval)convertToUnixTime:(nullable NSDate *)date;

@end

NS_ASSUME_NONNULL_END
