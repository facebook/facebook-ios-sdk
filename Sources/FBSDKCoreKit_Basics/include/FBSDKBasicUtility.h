/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Dispatches the specified block on the main thread.
 @param block the block to dispatch
 */
extern void fb_dispatch_on_main_thread(dispatch_block_t block);

/**
 Dispatches the specified block on the default thread.
 @param block the block to dispatch
 */
extern void fb_dispatch_on_default_thread(dispatch_block_t block);

/**
 Describes the callback for appLinkFromURLInBackground.
 @param object the FBSDKAppLink representing the deferred App Link
 @param stop the error during the request, if any

 */
typedef id _Nullable (^ FBSDKInvalidObjectHandler)(id object, BOOL *stop)
NS_SWIFT_NAME(InvalidObjectHandler);

NS_SWIFT_NAME(BasicUtility)
@interface FBSDKBasicUtility : NSObject

/**
 Converts an object into a JSON string.
 @param object The object to convert to JSON.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @return A JSON string or nil if the object cannot be converted to JSON.
 */
+ (nullable NSString *)JSONStringForObject:(id)object
                                     error:(NSError *__autoreleasing *)errorRef
                      invalidObjectHandler:(nullable FBSDKInvalidObjectHandler)invalidObjectHandler;

/**
 Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set after serializing to JSON.
 @param key The key to set the value for.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return NO if an error occurred while serializing the object, otherwise YES.
 */
+ (BOOL)      dictionary:(NSMutableDictionary<id, id> *)dictionary
  setJSONStringForObject:(id)object
                  forKey:(id<NSCopying>)key
                   error:(NSError *__autoreleasing *)errorRef;

/**
 Converts a JSON string into an object
 @param string The JSON string to convert.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return An NSDictionary, NSArray, NSString or NSNumber containing the object representation, or nil if the string
 cannot be converted.
 */
+ (nullable id)objectForJSONString:(NSString *)string error:(NSError *__autoreleasing *)errorRef;

/**
 Constructs a query string from a dictionary.
 @param dictionary The dictionary with key/value pairs for the query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @return Query string representation of the parameters.
 */
+ (nullable NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                                           error:(NSError *__autoreleasing *)errorRef
                            invalidObjectHandler:(nullable FBSDKInvalidObjectHandler)invalidObjectHandler;

/**
 Converts simple value types to the string equivalent for serializing to a request query or body.
 @param value The value to be converted.
 @return The value that may have been converted if able (otherwise the input param).
 */
+ (id)convertRequestValue:(id)value;

/**
 Encodes a value for an URL.
 @param value The value to encode.
 @return The encoded value.
 */
+ (NSString *)URLEncode:(NSString *)value;

/**
 Parses a query string into a dictionary.
 @param queryString The query string value.
 @return A dictionary with the key/value pairs.
 */
+ (NSDictionary<NSString *, NSString *> *)dictionaryWithQueryString:(NSString *)queryString;

/**
 Decodes a value from an URL.
 @param value The value to decode.
 @return The decoded value.
 */
+ (NSString *)URLDecode:(NSString *)value;

/**
 Gzip data with default compression level if possible.
 @param data The raw data.
 @return nil if unable to gzip the data, otherwise gzipped data.
 */
+ (nullable NSData *)gzip:(NSData *)data;

+ (NSString *)anonymousID;
+ (NSString *)persistenceFilePath:(NSString *)filename;
+ (nullable NSString *)SHA256Hash:(nullable NSObject *)input;

@end

NS_ASSUME_NONNULL_END
