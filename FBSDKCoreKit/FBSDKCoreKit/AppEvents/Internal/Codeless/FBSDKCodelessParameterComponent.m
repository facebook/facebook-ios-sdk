/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKCodelessParameterComponent.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKCodelessPathComponent.h"
#import "FBSDKViewHierarchyMacros.h"

@implementation FBSDKCodelessParameterComponent

- (instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    _name = [dict[CODELESS_MAPPING_PARAMETER_NAME_KEY] copy];
    _value = [dict[CODELESS_MAPPING_PARAMETER_VALUE_KEY] copy];
    _pathType = [dict[CODELESS_MAPPING_PATH_TYPE_KEY] copy];

    NSArray *ary = dict[CODELESS_MAPPING_PATH_KEY];
    NSMutableArray *mut = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *info in ary) {
      FBSDKCodelessPathComponent *component = [[FBSDKCodelessPathComponent alloc] initWithJSON:info];
      [FBSDKTypeUtility array:mut addObject:component];
    }
    _path = [mut copy];
  }

  return self;
}

- (BOOL)isEqualToParameter:(FBSDKCodelessParameterComponent *)parameter
{
  if (_path.count != parameter.path.count) {
    return NO;
  }

  NSString *current = [NSString stringWithFormat:@"%@|%@|%@",
                       _name ?: @"",
                       _value ?: @"",
                       _pathType ?: @""];
  NSString *compared = [NSString stringWithFormat:@"%@|%@|%@",
                        parameter.name ?: @"",
                        parameter.value ?: @"",
                        parameter.pathType ?: @""];

  if (![current isEqualToString:compared]) {
    return NO;
  }

  for (int i = 0; i < _path.count; i++) {
    if (![[FBSDKTypeUtility array:_path objectAtIndex:i] isEqualToPath:[FBSDKTypeUtility array:parameter.path objectAtIndex:i]]) {
      return NO;
    }
  }

  return YES;
}

@end

#endif
