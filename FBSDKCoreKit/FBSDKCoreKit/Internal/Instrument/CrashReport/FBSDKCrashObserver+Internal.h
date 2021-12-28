/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKCrashObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCrashObserver ()

@property (nonatomic) id<FBSDKFeatureChecking> featureChecker;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKCrashHandler> crashHandler;

@end

NS_ASSUME_NONNULL_END
