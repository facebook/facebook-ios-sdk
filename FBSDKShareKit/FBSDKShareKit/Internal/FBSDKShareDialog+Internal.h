/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKShareDialog.h"
#import "FBSDKShareInternalURLOpening.h"

@protocol FBSDKShareUtility;
@protocol FBSDKSocialComposeViewControllerFactory;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKShareDialog ()

@property (class, nullable, nonatomic) id<FBSDKShareInternalURLOpening> internalURLOpener;
@property (class, nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) Class<FBSDKShareUtility> shareUtility;
@property (class, nullable, nonatomic) id<FBSDKBridgeAPIRequestCreating> bridgeAPIRequestFactory;
@property (class, nullable, nonatomic) id<FBSDKBridgeAPIRequestOpening> bridgeAPIRequestOpener;
@property (class, nullable, nonatomic) id<FBSDKSocialComposeViewControllerFactory> socialComposeViewControllerFactory;
@property (class, nullable, nonatomic) id<FBSDKWindowFinding> windowFinder;
@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

@end

NS_ASSUME_NONNULL_END

#endif
