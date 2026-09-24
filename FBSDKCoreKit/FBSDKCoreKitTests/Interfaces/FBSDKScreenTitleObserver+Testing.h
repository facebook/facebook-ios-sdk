/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKScreenTitleObserver (Testing)

@property (atomic) id<FBSDKSettings> settings;

@end

NS_ASSUME_NONNULL_END
