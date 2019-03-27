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

#import <FBSDKCoreKit/FBSDKCopying.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A container of arguments for a camera effect.
 * An argument is a NSString identified by a NSString key.
 */
NS_SWIFT_NAME(CameraEffectArguments)
@interface FBSDKCameraEffectArguments : NSObject <FBSDKCopying, NSSecureCoding>

/**
 Sets a string argument in the container.
 @param string The argument
 @param key The key for the argument
 */
- (void)setString:(nullable NSString *)string forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

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
- (void)setArray:(nullable NSArray<NSString *> *)array forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));

/**
 Gets an array argument from the container.
 @param key The key for the argument
 @return The array argument
 */
- (nullable NSArray<NSString *> *)arrayForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
