/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKNonceUtility.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

@implementation FBSDKNonceUtility

+ (BOOL)isValidNonce:(NSString *)nonce
{
  NSString *string = [FBSDKTypeUtility coercedToStringValue:nonce];
  NSRange whiteSpaceRange = [string rangeOfCharacterFromSet:NSCharacterSet.whitespaceCharacterSet];
  BOOL containsWhitespace = (whiteSpaceRange.location != NSNotFound);

  return ((string.length > 0) && !containsWhitespace);
}

@end
