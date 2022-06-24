/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKDataPersisting.h>
#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSUserDefaults, DataPersisting)
@implementation NSUserDefaults (DataPersisting)

- (NSInteger)fb_integerForKey:(NSString *)key
{
  return [self integerForKey:key];
}

- (void)fb_setInteger:(NSInteger)integer
               forKey:(NSString *)key
{
  [self setInteger:integer forKey:key];
}

- (nullable id)fb_objectForKey:(NSString *)key
{
  return [self objectForKey:key];
}

- (void)fb_setObject:(id)object
              forKey:(NSString *)key
{
  [self setObject:object forKey:key];
}

- (nullable NSString *)fb_stringForKey:(NSString *)key
{
  return [self stringForKey:key];
}

- (nullable NSData *)fb_dataForKey:(NSString *)key
{
  return [self dataForKey:key];
}

- (void)fb_removeObjectForKey:(NSString *)key
{
  [self removeObjectForKey:key];
}

@end

NS_ASSUME_NONNULL_END
