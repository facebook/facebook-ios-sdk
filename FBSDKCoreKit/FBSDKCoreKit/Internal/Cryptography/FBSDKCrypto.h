/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Crypto)
@interface FBSDKCrypto : NSObject

/**
  Generate numOfBytes random data.

 This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (nullable NSData *)randomBytes:(NSUInteger)numOfBytes;

/**
 * Generate numOfBytes random data, base64-encoded.
 * This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (nullable NSString *)randomString:(NSUInteger)numOfBytes;

@end

NS_ASSUME_NONNULL_END
