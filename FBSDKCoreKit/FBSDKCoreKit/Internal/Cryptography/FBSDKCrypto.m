/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrypto.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKDynamicFrameworkLoader.h"

NS_ASSUME_NONNULL_BEGIN

static inline void FBSDKCryptoBlankData(NSData *data)
{
  if (!data) {
    return;
  }
  bzero((void *) [data bytes], [data length]);
}

@implementation FBSDKCrypto

+ (nullable NSData *)randomBytes:(NSUInteger)numOfBytes
{
  uint8_t *buffer = malloc(numOfBytes);
  int result = fbsdkdfl_SecRandomCopyBytes([FBSDKDynamicFrameworkLoader loadkSecRandomDefault], numOfBytes, buffer);
  if (result != 0) {
    free(buffer);
    return nil;
  }
  return [NSData dataWithBytesNoCopy:buffer length:numOfBytes];
}

+ (nullable NSString *)randomString:(NSUInteger)numOfBytes
{
  NSData *randomStringData = [FBSDKCrypto randomBytes:numOfBytes];
  if (!randomStringData) {
    return nil;
  }
  NSString *randomString = [FBSDKBase64 encodeData:randomStringData];
  FBSDKCryptoBlankData(randomStringData);
  return randomString;
}

@end

NS_ASSUME_NONNULL_END
