/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKModelUtility.h"

#import <Foundation/Foundation.h>

@implementation FBSDKModelUtility : NSObject

+ (NSString *)normalizedText:(NSString *)text
{
  NSMutableArray *tokens = [[text componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] mutableCopy];
  [tokens removeObject:@""];
  return [tokens componentsJoinedByString:@" "];
}

@end

#endif
