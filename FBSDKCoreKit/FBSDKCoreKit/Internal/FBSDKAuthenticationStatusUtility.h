/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/* FBSDKAuthenticationTokenStatusChecker_h */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenProtocols.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKProfileProtocols.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AuthenticationStatusUtility)
@interface FBSDKAuthenticationStatusUtility : NSObject

@property (class, nullable, nonatomic) Class<FBSDKProfileProviding> profileSetter;
@property (class, nullable, nonatomic) id<FBSDKSessionProviding> sessionDataTaskProvider;
@property (class, nullable, nonatomic) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> accessTokenWallet;
@property (class, nullable, nonatomic) Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> authenticationTokenWallet;

/**
 Sets dependencies. This must be called during SDK initialization.
 */
+ (void)configureWithProfileSetter:(Class<FBSDKProfileProviding>)profileSetter
           sessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
                 accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)accessTokenWallet
         authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationWallet;

/**
  Fetches the latest authentication status from server. This will invalidate
  the current user session if the returned status is not authorized.
 */
+ (void)checkAuthenticationStatus;

#if FBTEST && DEBUG

+ (void)resetClassDependencies;

#endif

@end

NS_ASSUME_NONNULL_END

#endif
