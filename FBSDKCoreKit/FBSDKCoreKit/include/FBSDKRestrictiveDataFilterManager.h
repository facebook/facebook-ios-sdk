/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKServerConfigurationProviding;

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_RestrictiveDataFilterManager)
@interface FBSDKRestrictiveDataFilterManager : NSObject <FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider NS_DESIGNATED_INITIALIZER;

- (void)enable;
- (void)processEvents:(NSArray<NSDictionary<NSString *, id> *> *)events;
- (nullable NSDictionary<FBSDKAppEventParameterName, id> *)processParameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
                                                                   eventName:(FBSDKAppEventName)eventName;
@end

NS_ASSUME_NONNULL_END
