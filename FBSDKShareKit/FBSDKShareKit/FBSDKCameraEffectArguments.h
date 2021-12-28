/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A container of arguments for a camera effect.
 * An argument is a NSString identified by a NSString key.
 */
NS_SWIFT_NAME(CameraEffectArguments)
@interface FBSDKCameraEffectArguments : NSObject <NSCopying, NSObject, NSSecureCoding>

/**
 Sets a string argument in the container.
 @param string The argument
 @param key The key for the argument
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)setString:(nullable NSString *)string forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));
// UNCRUSTIFY_FORMAT_ON

/**
 Gets a string argument from the container.
 @param key The key for the argument
 @return The string value or nil
 */
- (nullable NSString *)stringForKey:(NSString *)key;

/**
 Sets a string array argument in the container.
 @param array The array argument
 @param key The key for the argument
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)setArray:(nullable NSArray<NSString *> *)array forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));
// UNCRUSTIFY_FORMAT_ON

/**
 Gets an array argument from the container.
 @param key The key for the argument
 @return The array argument
 */
- (nullable NSArray<NSString *> *)arrayForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

#endif
