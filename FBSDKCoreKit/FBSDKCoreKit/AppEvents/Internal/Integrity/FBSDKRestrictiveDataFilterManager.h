/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKEventsProcessing.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKServerConfigurationProviding;

NS_SWIFT_NAME(RestrictiveDataFilterManager)
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
