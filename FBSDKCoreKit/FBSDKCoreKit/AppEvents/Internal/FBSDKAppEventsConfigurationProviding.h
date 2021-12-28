/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(AppEventsConfigurationProvidingBlock)
typedef void (^FBSDKAppEventsConfigurationProvidingBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAppEventsConfiguration;

NS_SWIFT_NAME(AppEventsConfigurationProviding)
@protocol FBSDKAppEventsConfigurationProviding

@property (nonatomic, readonly) id<FBSDKAppEventsConfiguration> cachedAppEventsConfiguration;

- (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationProvidingBlock)block;

@end

NS_ASSUME_NONNULL_END
