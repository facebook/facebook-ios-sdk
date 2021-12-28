/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ FBSDKAuthenticationTokenBlock)(FBSDKAuthenticationToken *_Nullable token)
NS_SWIFT_NAME(AuthenticationTokenBlock);

NS_SWIFT_NAME(AuthenticationTokenCreating)
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
