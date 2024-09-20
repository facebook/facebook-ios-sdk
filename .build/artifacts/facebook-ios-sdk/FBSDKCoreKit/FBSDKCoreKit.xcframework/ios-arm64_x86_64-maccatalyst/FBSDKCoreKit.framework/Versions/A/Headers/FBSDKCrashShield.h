/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKFeatureDisabling;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_CrashShield)
@interface FBSDKCrashShield : NSObject

+ (void)analyze:(NSArray<NSDictionary<NSString *, id> *> *)crashLogs;

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking
NS_SWIFT_NAME(configure(settings:graphRequestFactory:featureChecking:));

@end

NS_ASSUME_NONNULL_END
