/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKTimeSpentRecorderCreating.h"

@protocol FBSDKEventLogging;
@protocol FBSDKServerConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TimeSpentRecorderFactory)
@interface FBSDKTimeSpentRecorderFactory : NSObject <FBSDKTimeSpentRecorderCreating>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
        serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;

@end

NS_ASSUME_NONNULL_END
