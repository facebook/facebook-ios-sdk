/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDialogConfigurationMapBuilder.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKDialogConfigurationMapBuilder

- (nonnull NSDictionary<NSString *, FBSDKDialogConfiguration *> *)buildDialogConfigurationMapWithRawConfigurations:(NSArray<NSDictionary<NSString *, id> *> *)rawConfigurations
{
  NSMutableDictionary<NSString *, id> *dialogConfigurations = [NSMutableDictionary new];
  for (id configuration in rawConfigurations) {
    NSDictionary<NSString *, id> *dialogConfigurationDictionary = [FBSDKTypeUtility dictionaryValue:configuration];
    if (dialogConfigurationDictionary) {
      NSString *name = [FBSDKTypeUtility coercedToStringValue:dialogConfigurationDictionary[@"name"]];
      NSURL *URL = [FBSDKTypeUtility coercedToURLValue:dialogConfigurationDictionary[@"url"]];
      NSArray *appVersions = [FBSDKTypeUtility arrayValue:dialogConfigurationDictionary[@"versions"]];
      if (name.length && URL && appVersions.count) {
        [FBSDKTypeUtility dictionary:dialogConfigurations setObject:[[FBSDKDialogConfiguration alloc] initWithName:name
                                                                                                               URL:URL
                                                                                                       appVersions:appVersions] forKey:name];
      }
    }
  }
  return dialogConfigurations;
}

@end
