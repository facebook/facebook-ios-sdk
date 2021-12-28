/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AuthenticationTokenHeader)
@interface FBSDKAuthenticationTokenHeader : NSObject

/// Value that represents the algorithm that was used to sign the JWT.
@property (nonatomic, readonly, strong) NSString *alg;

/// The type of the JWT.
@property (nonatomic, readonly, strong) NSString *typ;

/// Key identifier used in identifying the key to be used to verify the signature.
@property (nonatomic, readonly, strong) NSString *kid;

/**
 Returns a new instance, when one can be created from the parameters given, otherwise `nil`.
 @param encodedHeader Base64-encoded string of the header.
 */
+ (nullable FBSDKAuthenticationTokenHeader *)headerFromEncodedString:(NSString *)encodedHeader;

@end

NS_ASSUME_NONNULL_END
