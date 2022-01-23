/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAuthenticationTokenCreating.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Class responsible for generating an `AuthenticationToken` given a valid token string.
 An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
 */
NS_SWIFT_NAME(AuthenticationTokenFactory)
@interface FBSDKAuthenticationTokenFactory : NSObject <FBSDKAuthenticationTokenCreating>

/**
 Create an `AuthenticationToken` given a valid token string.
 Returns nil to the completion handler if the token string is invalid
 An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
 @param tokenString the raw ID token string
 @param nonce the nonce string used to associate a client session with the token
 @param graphDomain the graph domain where user is authenticated
 @param completion the completion handler
 */
- (void)createTokenFromTokenString:(NSString *_Nonnull)tokenString
                             nonce:(NSString *_Nonnull)nonce
                       graphDomain:(NSString *_Nonnull)graphDomain
                        completion:(FBSDKAuthenticationTokenBlock)completion;

/**
 Create an `AuthenticationToken` for facebook graph domain given a valid token string.
 Returns nil to the completion handler if the token string is invalid
 An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
 @param tokenString the raw ID token string
 @param nonce the nonce string used to associate a client session with the token
 @param completion the completion handler
 */
- (void)createTokenFromTokenString:(NSString *_Nonnull)tokenString
                             nonce:(NSString *_Nonnull)nonce
                        completion:(FBSDKAuthenticationTokenBlock)completion;

@end

NS_ASSUME_NONNULL_END
