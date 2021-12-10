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
 The purpose of this class is to serve as thin, type-safe wrapper
 around FBSDKTypeUtility
 */
@interface FBSDKJSONField : NSObject

/**
 This can only be created by FBSDKJSONValue.
 */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
A safe method to unpack the values in the top-level JSON object.
 https://developer.apple.com/documentation/foundation/nsjsonserialization
*/
- (void)matchArray:(void (^_Nullable)(NSArray<FBSDKJSONField *> *_Nonnull))arrayMatcher
        dictionary:(void (^_Nullable)(NSDictionary<NSString *, FBSDKJSONField *> *_Nonnull))dictionaryMatcher
            string:(void (^_Nullable)(NSString *_Nonnull))stringMatcher
            number:(void (^_Nullable)(NSNumber *_Nonnull))numberMatcher
              null:(void (^_Nullable)(void))nullMatcher;

/**
 The underlying JSON object. The only guarantee we provide with this
 is that it passes [FBSDKTypeUtility isValidJSONObject:]
 */
@property (nonnull, nonatomic, readonly, strong) id rawObject;

- (NSArray<FBSDKJSONField *> *_Nullable)arrayOrNil;
- (NSDictionary<NSString *, FBSDKJSONField *> *_Nullable)dictionaryOrNil;
- (NSString *_Nullable)stringOrNil;
- (NSNumber *_Nullable)numberOrNil;
- (NSNull *_Nullable)nullOrNil;

@end

/**
 Represents Top-level JSON objects.
 */
@interface FBSDKJSONValue : NSObject

/**
 If the object does not pass [FBSDKTypeUtility isValidJSONObject:]
 this will return nil.
 */
- (_Nullable instancetype)initWithPotentialJSONObject:(id)obj;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The underlying JSON object. The only guarantee we provide with this
 is that it passes [FBSDKTypeUtility isValidJSONObject:]
 */
@property (nonatomic, readonly, strong) id rawObject;

/**
 A safe method to unpack the values in the top-level JSON object.

 The specs are per Apple's documentation: https://developer.apple.com/documentation/foundation/nsjsonserialization
 */
- (void)matchArray:(void (^_Nullable)(NSArray<FBSDKJSONField *> *))arrayMatcher
        dictionary:(void (^_Nullable)(NSDictionary<NSString *, FBSDKJSONField *> *))dictMatcher;

/**
 Returns the dictionary if that's truly what it is, otherwise, nil.
 */
- (NSDictionary<NSString *, FBSDKJSONField *> *_Nullable)matchDictionaryOrNil;

/**
 The unsafe variant which drops all the type-safety for this class.
 If this object is nonnull, you at least have guarantees from Apple that this is NSNull, NSString, NSNumber, NSArray, or NSDictionary.
 */
- (NSDictionary<NSString *, id> *_Nullable)unsafe_matchDictionaryOrNil;

- (NSArray<FBSDKJSONField *> *_Nullable)matchArrayOrNil;
- (NSArray *_Nullable)unsafe_matchArrayOrNil;

@end

/**
FBSDKTypeUtility returns id, which is problematic in our codebase.

You can wrap resulting objects in this to force users of your JSON to use
type-safe bindings.

If this is not a valid JSON object...this will return nil.
*/
FBSDKJSONValue *_Nullable FBSDKCreateJSONFromString(NSString *_Nullable string, NSError *__autoreleasing *errorRef);

NS_ASSUME_NONNULL_END
