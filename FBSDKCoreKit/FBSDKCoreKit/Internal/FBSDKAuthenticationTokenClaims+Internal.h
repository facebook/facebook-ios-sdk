/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationTokenClaims.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationTokenClaims (Internal)

+ (nullable FBSDKAuthenticationTokenClaims *)claimsFromEncodedString:(NSString *)encodedClaims
                                                               nonce:(NSString *)expectedNonce;

@end

NS_ASSUME_NONNULL_END
