/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKErrorCreating.h>

#import "FBSDKAccessToken.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestPiggybackManaging.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAccessToken (Internal)

@property (class, nullable, nonatomic, copy) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestPiggybackManaging> graphRequestPiggybackManager;
@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

+ (void)configureWithTokenCache:(id<FBSDKTokenCaching>)tokenCache
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
   graphRequestPiggybackManager:(id<FBSDKGraphRequestPiggybackManaging>)graphRequestPiggybackManager
                   errorFactory:(id<FBSDKErrorCreating>)errorFactory;

+ (void)resetTokenCache;

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

#if DEBUG && FBTEST
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END
