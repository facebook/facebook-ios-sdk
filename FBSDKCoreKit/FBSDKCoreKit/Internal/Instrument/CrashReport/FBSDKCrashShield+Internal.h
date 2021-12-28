/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKCrashShield.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKFeatureDisabling;

@interface FBSDKCrashShield (Internal)

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking;

@end

NS_ASSUME_NONNULL_END
