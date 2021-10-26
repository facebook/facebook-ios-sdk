/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A container of textures for a camera effect.
 * A texture for a camera effect is an UIImages identified by a NSString key.
 */
NS_SWIFT_NAME(CameraEffectTextures)
@interface FBSDKCameraEffectTextures : NSObject <NSCopying, NSObject, NSSecureCoding>

/**
 Sets the image for a texture key.
 @param image The UIImage for the texture
 @param key The key for the texture
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)setImage:(nullable UIImage *)image forKey:(NSString *)key
NS_SWIFT_NAME(set(_:forKey:));
// UNCRUSTIFY_FORMAT_ON

/**
 Gets the image for a texture key.
 @param key The key for the texture
 @return The texture UIImage or nil
 */
- (nullable UIImage *)imageForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

#endif
