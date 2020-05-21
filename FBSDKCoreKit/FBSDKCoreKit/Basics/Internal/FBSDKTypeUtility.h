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

NS_SWIFT_NAME(TypeUtility)
@interface FBSDKTypeUtility : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Returns an NSArray if the provided object is an NSArray, otherwise returns nil.
+ (NSArray *)arrayValue:(id)object;

/// Returns a BOOL if the provided object is a BOOL, otherwise returns nil.
+ (BOOL)boolValue:(id)object;

/// Returns an NSDictionary if the provided object is an NSDictionary, otherwise returns nil.
+ (NSDictionary *)dictionaryValue:(id)object;

/// Returns an object for a given key in the provided dictionary if it matches the stated type
+ (id) dictionary:(NSDictionary *)dictionary objectForKey:(NSString *)key ofType:(Class)type;

/// Checks if an object is a valid dictionary type before enumerating its keys and objects
+ (void)dictionary:(NSDictionary *)dictionary enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block;

/// Returns an NSInteger if the provided object is an NSInteger, otherwise returns nil.
+ (NSInteger)integerValue:(id)object;

/// Returns an NSNumber if the provided object is an NSNumber, otherwise returns nil.
+ (NSNumber *)numberValue:(id)object;

/// Returns the provided object if it is non-null
+ (id)objectValue:(id)object;

/// Returns an NSString if the provided object is an NSString, otherwise returns nil.
+ (NSString *)stringValue:(id)object;

/// Returns an NSTimeInterval if the provided object is an NSTimeInterval, otherwise returns nil.
+ (NSTimeInterval)timeIntervalValue:(id)object;

/// Returns an NSUInteger if the provided object is an NSUInteger, otherwise returns nil.
+ (NSUInteger)unsignedIntegerValue:(id)object;

/// Returns an NSURL if the provided object is an NSURL, otherwise returns nil.
+ (NSURL *)URLValue:(id)object;

@end
