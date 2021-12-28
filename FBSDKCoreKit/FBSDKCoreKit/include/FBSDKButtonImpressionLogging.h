/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppEventName.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(FBButtonImpressionLogging)
@protocol FBSDKButtonImpressionLogging <NSObject>

@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *analyticsParameters;
@property (nonatomic, readonly, copy) FBSDKAppEventName impressionTrackingEventName;
@property (nonatomic, readonly, copy) NSString *impressionTrackingIdentifier;

@end

NS_ASSUME_NONNULL_END
