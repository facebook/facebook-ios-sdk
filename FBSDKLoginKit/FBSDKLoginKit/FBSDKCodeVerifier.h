/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a code verifier used in the PKCE (Proof Key for Code Exchange)
 process. This is a cryptographically random string using the characters
 A-Z, a-z, 0-9, and the punctuation characters -._~ (hyphen, period,
 underscore, and tilde), between 43 and 128 characters long.
 */
NS_SWIFT_NAME(CodeVerifier)
@interface FBSDKCodeVerifier : NSObject

/// The string value of the code verifier
@property (nonatomic, readonly, copy) NSString *value;

/// The SHA256 hashed challenge of the code verifier
@property (nonatomic, readonly, copy) NSString *challenge;

/**
 Attempts to initialize a new code verifier instance with the given string.
 Creation will fail and return nil if the string is invalid.

 @param string the code verifier string
 */
- (nullable instancetype)initWithString:(NSString *)string
  NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif
