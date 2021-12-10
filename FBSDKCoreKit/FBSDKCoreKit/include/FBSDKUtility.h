/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
  Class to contain common utility methods.
 */
NS_SWIFT_NAME(Utility)
@interface FBSDKUtility : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Parses a query string into a dictionary.
 @param queryString The query string value.
 @return A dictionary with the key/value pairs.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (NSDictionary<NSString *, NSString *> *)dictionaryWithQueryString:(NSString *)queryString
NS_SWIFT_NAME(dictionary(withQuery:));
// UNCRUSTIFY_FORMAT_ON

/**
  Constructs a query string from a dictionary.
 @param dictionary The dictionary with key/value pairs for the query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return Query string representation of the parameters.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                                  error:(NSError **)errorRef
NS_SWIFT_NAME(query(from:))
__attribute__((swift_error(nonnull_error)));
// UNCRUSTIFY_FORMAT_ON

/**
  Decodes a value from an URL.
 @param value The value to decode.
 @return The decoded value.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (NSString *)URLDecode:(NSString *)value
NS_SWIFT_NAME(decode(urlString:));
// UNCRUSTIFY_FORMAT_ON

/**
  Encodes a value for an URL.
 @param value The value to encode.
 @return The encoded value.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (NSString *)URLEncode:(NSString *)value
NS_SWIFT_NAME(encode(urlString:));
// UNCRUSTIFY_FORMAT_ON

/**
  Creates a timer using Grand Central Dispatch.
 @param interval The interval to fire the timer, in seconds.
 @param block The code block to execute when timer is fired.
 @return The dispatch handle.
 */
+ (dispatch_source_t)startGCDTimerWithInterval:(double)interval block:(dispatch_block_t)block;

/**
 Stop a timer that was started by startGCDTimerWithInterval.
 @param timer The dispatch handle received from startGCDTimerWithInterval.
 */
+ (void)stopGCDTimer:(dispatch_source_t)timer;

/**
 Get SHA256 hased string of NSString/NSData

 @param input The data that needs to be hashed, it could be NSString or NSData.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (nullable NSString *)SHA256Hash:(NSObject *)input
NS_SWIFT_NAME(sha256Hash(_:));
// UNCRUSTIFY_FORMAT_ON

/**
 Returns the graphdomain stored in FBSDKAuthenticationToken
 */
+ (NSString *)getGraphDomainFromToken;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
+ (NSURL *)unversionedFacebookURLWithHostPrefix:(NSString *)hostPrefix
                                           path:(NSString *)path
                                queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                          error:(NSError *__autoreleasing *)errorRef;

@end

NS_ASSUME_NONNULL_END
