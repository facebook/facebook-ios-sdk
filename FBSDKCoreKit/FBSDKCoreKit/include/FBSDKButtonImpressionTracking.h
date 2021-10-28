/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(FBButtonImpressionTracking)
@protocol FBSDKButtonImpressionTracking <NSObject>

@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *analyticsParameters;
@property (nonatomic, readonly, copy) NSString *impressionTrackingEventName;
@property (nonatomic, readonly, copy) NSString *impressionTrackingIdentifier;

@end

NS_ASSUME_NONNULL_END
