/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Base64)
@interface FBSDKBase64 : NSObject

/**
 Decodes a base-64 encoded string.
 @param string The base-64 encoded string.
 @return NSData containing the decoded bytes.
 */
+ (nullable NSData *)decodeAsData:(nullable NSString *)string;

/**
 Decodes a base-64 encoded string into a string.
 @param string The base-64 encoded string.
 @return NSString with the decoded UTF-8 value.
 */
+ (nullable NSString *)decodeAsString:(nullable NSString *)string;

/**
 Encodes string into a base-64 representation.
 @param string The string to be encoded.
 @return The base-64 encoded string.
 */
+ (nullable NSString *)encodeString:(nullable NSString *)string;

/**
 Encodes URL string into a base-64 representation.
 @param base64Url The URL string to be encoded.
 @return The base-64 encoded string.
 */
+ (NSString *)base64FromBase64Url:(NSString *)base64Url;

@end

NS_ASSUME_NONNULL_END
