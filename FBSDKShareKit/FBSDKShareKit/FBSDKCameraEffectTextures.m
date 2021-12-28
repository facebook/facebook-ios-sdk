/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKCameraEffectTextures.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKShareUtility.h"

static NSString *const FBSDKCameraEffectTexturesTexturesKey = @"textures";

@interface FBSDKCameraEffectTextures ()
@property (nonatomic) NSMutableDictionary<NSString *, UIImage *> *textures;
@end

@implementation FBSDKCameraEffectTextures

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    _textures = [NSMutableDictionary new];
  }
  return self;
}

- (void)setImage:(nullable UIImage *)image forKey:(NSString *)key
{
  [self _setValue:image forKey:key];
}

- (nullable UIImage *)imageForKey:(NSString *)key
{
  return [self _valueOfClass:UIImage.class forKey:key];
}

- (NSDictionary<NSString *, UIImage *> *)allTextures
{
  return _textures;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  return _textures.hash;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKCameraEffectTextures.class]) {
    return NO;
  }
  return [self isEqualToCameraEffectTextures:(FBSDKCameraEffectTextures *)object];
}

- (BOOL)isEqualToCameraEffectTextures:(FBSDKCameraEffectTextures *)object
{
  return [FBSDKInternalUtility.sharedUtility object:_textures isEqualToObject:[object allTextures]];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _textures = [decoder decodeObjectOfClass:NSMutableDictionary.class
                                      forKey:FBSDKCameraEffectTexturesTexturesKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_textures forKey:FBSDKCameraEffectTexturesTexturesKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKCameraEffectTextures *copy = [FBSDKCameraEffectTextures new];
  copy->_textures = [_textures copy];
  return copy;
}

- (void)_setValue:(id)value forKey:(NSString *)key
{
  if (value) {
    [FBSDKTypeUtility dictionary:_textures setObject:value forKey:key];
  } else {
    [_textures removeObjectForKey:key];
  }
}

- (id)_valueForKey:(NSString *)key
{
  key = [FBSDKTypeUtility coercedToStringValue:key];
  return (key ? [FBSDKTypeUtility objectValue:_textures[key]] : nil);
}

- (id)_valueOfClass:(__unsafe_unretained Class)cls forKey:(NSString *)key
{
  id value = [self _valueForKey:key];
  return ([value isKindOfClass:cls] ? value : nil);
}

@end

#endif
