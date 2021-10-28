/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKGraphRequestPiggybackManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAccessTokenProviding;
@protocol FBSDKAccessTokenSetting;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKGraphRequestFactory;

@interface FBSDKGraphRequestPiggybackManager (Internal)

+ (void)configureWithTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                        settings:(id<FBSDKSettings>)settings
             serverConfiguration:(id<FBSDKServerConfigurationProviding>)serverConfiguration
             graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END
