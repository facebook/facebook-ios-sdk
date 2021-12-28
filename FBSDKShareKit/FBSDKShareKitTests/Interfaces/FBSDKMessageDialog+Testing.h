/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "FBSDKShareDialogConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKMessageDialog (Testing)

@property (nonatomic) id<FBSDKAppAvailabilityChecker> appAvailabilityChecker;

- (instancetype)initWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
         appAvailabilityChecker:(id<FBSDKAppAvailabilityChecker>)appAvailabilityChecker
       shareDialogConfiguration:(nonnull id<FBSDKShareDialogConfiguration>)shareDialogConfiguration;

@end

NS_ASSUME_NONNULL_END
