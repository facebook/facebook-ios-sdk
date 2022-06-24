/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKInfoDictionaryProviding.h>
#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSBundle, InfoDictionaryProviding)
@implementation NSBundle (InfoDictionaryProviding)

- (nullable NSDictionary<NSString *, id> *)fb_infoDictionary
{
  return self.infoDictionary;
}

- (nullable NSString *)fb_bundleIdentifier
{
  return self.bundleIdentifier;
}

- (nullable id)fb_objectForInfoDictionaryKey:(nonnull NSString *)key
{
  return [self objectForInfoDictionaryKey:key];
}

@end

NS_ASSUME_NONNULL_END
