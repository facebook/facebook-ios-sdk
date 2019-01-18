// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKShareOpenGraphObject;
@class FBSDKSharePhoto;

/**
 Enumeration Block
 */
typedef void (^FBSDKEnumerationBlock)(NSString *key, id object, BOOL *stop)
NS_SWIFT_NAME(EnumerationBlock)
NS_SWIFT_UNAVAILABLE("");

/**
  Protocol defining operations on open graph actions and objects.

 The property keys MUST have namespaces specified on them, such as `og:image`.
 */
NS_SWIFT_NAME(ShareOpenGraphValueContaining)
@protocol FBSDKShareOpenGraphValueContaining <NSObject, NSSecureCoding>

/**
 Returns a dictionary of all the objects that lets you access each key/object in the receiver.
 */
@property (nonatomic, readonly, strong) NSDictionary<NSString *, id> *allProperties;

/**
  Returns an enumerator object that lets you access each key in the receiver.
 @return An enumerator object that lets you access each key in the receiver
 */
@property (nonatomic, readonly, strong) NSEnumerator *keyEnumerator
NS_SWIFT_UNAVAILABLE("");

/**
  Returns an enumerator object that lets you access each value in the receiver.
 @return An enumerator object that lets you access each value in the receiver
 */
@property (nonatomic, readonly, strong) NSEnumerator *objectEnumerator
NS_SWIFT_UNAVAILABLE("");

/**
  Gets an NSArray out of the receiver.
 @param key The key for the value
 @return The NSArray value or nil
 */
- (nullable NSArray<id> *)arrayForKey:(NSString *)key;

/**
  Applies a given block object to the entries of the receiver.
 @param block A block object to operate on entries in the receiver
 */
- (void)enumerateKeysAndObjectsUsingBlock:(FBSDKEnumerationBlock)block
NS_SWIFT_UNAVAILABLE("");

/**
  Gets an NSNumber out of the receiver.
 @param key The key for the value
 @return The NSNumber value or nil
 */
- (nullable NSNumber *)numberForKey:(NSString *)key;

/**
 Gets an NSString out of the receiver.
 @param key The key for the value
 @return The NSString value or nil
 */
- (nullable NSString *)stringForKey:(NSString *)key;

/**
 Gets an NSURL out of the receiver.
 @param key The key for the value
 @return The NSURL value or nil
 */
- (nullable NSURL *)URLForKey:(NSString *)key;

/**
  Gets an FBSDKShareOpenGraphObject out of the receiver.
 @param key The key for the value
 @return The FBSDKShareOpenGraphObject value or nil
 */
- (nullable FBSDKShareOpenGraphObject *)objectForKey:(NSString *)key;

/**
  Enables subscript access to the values in the receiver.
 @param key The key for the value
 @return The value
 */
- (nullable id)objectForKeyedSubscript:(NSString *)key;

/**
  Parses properties out of a dictionary into the receiver.
 @param properties The properties to parse.
 */
- (void)parseProperties:(NSDictionary<NSString *, id> *)properties;

/**
  Gets an FBSDKSharePhoto out of the receiver.
 @param key The key for the value
 @return The FBSDKSharePhoto value or nil
 */
- (nullable FBSDKSharePhoto *)photoForKey:(NSString *)key;

/**
  Removes a value from the receiver for the specified key.
 @param key The key for the value
 */
- (void)removeObjectForKey:(NSString *)key;

/**
  Sets an NSArray on the receiver.

 This method will throw if the array contains any values that is not an NSNumber, NSString, NSURL,
 FBSDKSharePhoto or FBSDKShareOpenGraphObject.
 @param array The NSArray value
 @param key The key for the value
 */
- (void)setArray:(nullable NSArray<id> *)array forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
  Sets an NSNumber on the receiver.
 @param number The NSNumber value
 @param key The key for the value
 */
- (void)setNumber:(nullable NSNumber *)number forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
  Sets an FBSDKShareOpenGraphObject on the receiver.
 @param object The FBSDKShareOpenGraphObject value
 @param key The key for the value
 */
- (void)setObject:(nullable FBSDKShareOpenGraphObject *)object forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
  Sets an FBSDKSharePhoto on the receiver.
 @param photo The FBSDKSharePhoto value
 @param key The key for the value
 */
- (void)setPhoto:(nullable FBSDKSharePhoto *)photo forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
  Sets an NSString on the receiver.
 @param string The NSString value
 @param key The key for the value
 */
- (void)setString:(nullable NSString *)string forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
  Sets an NSURL on the receiver.
 @param URL The NSURL value
 @param key The key for the value
 */
- (void)setURL:(nullable NSURL *)URL forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

@end

/**
  A base class to container Open Graph values.
 */
NS_SWIFT_NAME(ShareOpenGraphValueContainer)
@interface FBSDKShareOpenGraphValueContainer : NSObject <FBSDKShareOpenGraphValueContaining>

@end

NS_ASSUME_NONNULL_END
