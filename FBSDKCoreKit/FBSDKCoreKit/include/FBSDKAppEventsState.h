/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKEventsProcessing.h>
#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKAppOperationalDataType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// this type is not thread safe.
NS_SWIFT_NAME(_AppEventsState)
@interface FBSDKAppEventsState : NSObject <NSCopying, NSSecureCoding>

@property (class, nullable, nonatomic) NSArray<id<FBSDKEventsProcessing>> *eventProcessors;

@property (nonatomic, readonly, copy) NSArray<NSDictionary<NSString *, id> *> *events;
@property (nonatomic, readonly, assign) NSUInteger numSkipped;
@property (nonatomic, readonly, copy) NSString *tokenString;
@property (nonatomic, readonly, copy) NSString *appID;
@property (nonatomic, readonly, getter = areAllEventsImplicit) BOOL allEventsImplicit;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithToken:(nullable NSString *)tokenString appID:(nullable NSString *)appID NS_DESIGNATED_INITIALIZER;

- (void)addEvent:(NSDictionary<NSString *, id> *)eventDictionary isImplicit:(BOOL)isImplicit withOperationalParameters:(nullable NSDictionary<FBSDKAppOperationalDataType, NSDictionary<NSString *, id> *> *)operationalParameters;
- (void)addEventsFromAppEventState:(FBSDKAppEventsState *)appEventsState;
- (BOOL)isCompatibleWithAppEventsState:(nullable FBSDKAppEventsState *)appEventsState;
- (BOOL)isCompatibleWithTokenString:(NSString *)tokenString appID:(NSString *)appID;
- (NSDictionary<NSString *, NSString *> *)JSONStringForEventsAndOperationalParametersIncludingImplicitEvents:(BOOL)includeImplicitEvents;
- (NSString *)extractReceiptData;

@end

NS_ASSUME_NONNULL_END
