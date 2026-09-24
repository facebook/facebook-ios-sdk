/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@protocol FBSDKDataPersisting;
@protocol FBSDKSettings;
@protocol FBSDKFeatureChecking;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppLinkURLCache (Testing)

@property (nonatomic) id<FBSDKDataPersisting> dataStore;
@property (atomic) id<FBSDKSettings> settings;
@property (atomic) id<FBSDKFeatureChecking> featureChecker;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
