/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ FBSDKAuthenticationTokenBlock)(FBSDKAuthenticationToken *_Nullable token)
NS_SWIFT_NAME(AuthenticationTokenBlock);

/**
 Internal protocol exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AuthenticationTokenCreating)
@protocol FBSDKAuthenticationTokenCreating

// UNCRUSTIFY_FORMAT_OFF
- (void)createTokenFromTokenString:(NSString *)tokenString
                             nonce:(NSString *)nonce
                       graphDomain:(NSString *)graphDomain
                        completion:(FBSDKAuthenticationTokenBlock)completion
NS_SWIFT_NAME(createToken(tokenString:nonce:graphDomain:completion:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
