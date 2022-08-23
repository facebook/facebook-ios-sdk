/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsConfigurationProvidingBlock)
typedef void (^FBSDKAppEventsConfigurationProvidingBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAppEventsConfiguration;

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsConfigurationProviding)
@protocol FBSDKAppEventsConfigurationProviding

@property (nonatomic, readonly) id<FBSDKAppEventsConfiguration> cachedAppEventsConfiguration;

- (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationProvidingBlock)block;

@end

NS_ASSUME_NONNULL_END
