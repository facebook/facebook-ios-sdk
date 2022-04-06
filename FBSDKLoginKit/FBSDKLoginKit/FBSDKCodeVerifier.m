/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKCodeVerifier.h"

#import <CommonCrypto/CommonDigest.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

@implementation FBSDKCodeVerifier

// Number of random bytes generated for the codeVerifier.
static NSUInteger const CODE_VERIFIER_BYTES = 72;

- (instancetype)init
{
  NSMutableData *randomData = [NSMutableData dataWithLength:CODE_VERIFIER_BYTES];
  int __unused result = SecRandomCopyBytes(kSecRandomDefault, randomData.length, randomData.mutableBytes);

  NSString *codeVerifier = [[self class] base64URLEncodeDataWithNoPadding:randomData];

  return [self initWithString:codeVerifier];
}

- (nullable instancetype)initWithString:(NSString *)string
{
  NSString *codeVerifier = [FBSDKTypeUtility coercedToStringValue:string];
  if (codeVerifier.length < 43 || codeVerifier.length > 128) {
    return nil;
  }

  NSCharacterSet *allowedSet = [[self class] allowedCharacterSet];
  if ([codeVerifier rangeOfCharacterFromSet:allowedSet.invertedSet].length) {
    return nil;
  }

  if ((self = [super init])) {
    _value = codeVerifier;
  }
  return self;
}

- (NSString *)challenge
{
  NSData *data = [self.value dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableData *sha256Data = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, (CC_LONG)data.length, sha256Data.mutableBytes);
  return [[self class] base64URLEncodeDataWithNoPadding:sha256Data];
}

// MARK: Helper
+ (NSCharacterSet *)allowedCharacterSet
{
  NSMutableCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"-._~"].mutableCopy;
  [allowedSet formUnionWithCharacterSet:NSCharacterSet.alphanumericCharacterSet];
  return allowedSet;
}

+ (NSString *)base64URLEncodeDataWithNoPadding:(NSData *)data
{
  NSString *base64 = [data base64EncodedStringWithOptions:0];
  NSString *base64Url = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64Url = [base64Url stringByReplacingOccurrencesOfString:@"/" withString:@"_"];

  // remove padding "="
  return [base64Url stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@end

#endif
