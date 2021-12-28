/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKReferralManagerResult;

/**
  Describes the call back to the FBSDKReferralManager
 @param result the result of the referral
 @param error the referral error, if any.
 */
typedef void (^ FBSDKReferralManagerResultBlock)(FBSDKReferralManagerResult *_Nullable result,
  NSError *_Nullable error)
NS_SWIFT_NAME(ReferralManagerResultBlock);

/**
 `FBSDKReferralManager` provides methods for starting the referral process.
*/
NS_SWIFT_NAME(ReferralManager)
DEPRECATED_MSG_ATTRIBUTE("`FBSDKReferralManager` is deprecated and will be removed in the next major release")
@interface FBSDKReferralManager : NSObject

/**
 Initialize a new instance with the provided view controller
 @param viewController the view controller to present from. If nil, the topmost  view controller will be automatically determined as best as possible.
 */
- (instancetype)initWithViewController:(nullable UIViewController *)viewController;

/**
 Open the referral dialog.
 @param handler the callback.
 */
- (void)startReferralWithCompletionHandler:(nullable FBSDKReferralManagerResultBlock)handler;

@end

NS_ASSUME_NONNULL_END

#endif
