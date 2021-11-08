/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrashShield.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCrashShield (Testing)
+ (void)configureWithSettings:(id<FBSDKSettings>)settings
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking;
+ (nullable NSString *)_getFeature:(id)callstack; // Using id instead of NSArray<NSString *> * for testing in Swift
+ (nullable NSString *)_getClassName:(id)entry; // Using id instead of NSString for testing in Swift
+ (void)reset;
+ (FBSDKFeature)featureForString:(NSString *)featureName;
@end

NS_ASSUME_NONNULL_END
