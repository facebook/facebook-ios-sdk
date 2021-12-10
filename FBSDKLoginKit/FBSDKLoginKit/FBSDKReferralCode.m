/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKReferralCode.h"

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation FBSDKReferralCode

+ (nullable instancetype)initWithString:(NSString *)string
{
  if (string.length == 0) {
    return nil;
  }

  NSCharacterSet *alphanumericSet = NSCharacterSet.alphanumericCharacterSet;
  if (![[string stringByTrimmingCharactersInSet:alphanumericSet] isEqualToString:@""]) {
    return nil;
  }

  FBSDKReferralCode *instance;
  if ((instance = [super new])) {
    instance.value = string;
  }
  return instance;
}

- (BOOL)isEqual:(id)obj
{
  if (![obj isKindOfClass:FBSDKReferralCode.class]) {
    return NO;
  }

  FBSDKReferralCode *other = (FBSDKReferralCode *)obj;
  return [self.value isEqual:other.value];
}

- (NSString *)description
{
  return self.value;
}

@end
#pragma clang diagnostic pop

#endif
