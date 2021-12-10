/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKRandom.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKDynamicFrameworkLoader.h"

NSString *fb_randomString(NSUInteger numberOfBytes)
{
  uint8_t *buffer = malloc(numberOfBytes);
  int result = fbsdkdfl_SecRandomCopyBytes([FBSDKDynamicFrameworkLoader loadkSecRandomDefault], numberOfBytes, buffer);
  if (result != 0) {
    free(buffer);
    return nil;
  }
  NSData *randomStringData = [NSData dataWithBytesNoCopy:buffer
                                                  length:numberOfBytes];
  if (!randomStringData) {
    return nil;
  }
  NSString *randomString = [FBSDKBase64 encodeData:randomStringData];
  // FBSDKCryptoBlankData(randomStringData);
  if (!randomStringData) {
    return nil;
  }
  bzero((void *) [randomStringData bytes], [randomStringData length]);

  return randomString;
}
