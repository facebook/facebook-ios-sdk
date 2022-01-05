/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKReferralManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKReferralManager () <FBSDKURLOpening>

@property (class, nullable, nonatomic) id<FBSDKBridgeAPIRequestOpening> bridgeAPIRequestOpener;
@property (class, nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithBridgeAPIRequestOpener:(id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
                            internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                   settings:(id<FBSDKSettings>)settings
                               errorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(bridgeAPIRequestOpener:internalUtility:settings:errorFactory:));
// UNCRUSTIFY_FORMAT_ON

#if FBTEST
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END

#endif
