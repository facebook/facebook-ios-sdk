/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationTokenHeader.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKAuthenticationTokenHeader

- (instancetype)initWithAlg:(NSString *)alg
                        typ:(NSString *)typ
                        kid:(NSString *)kid
{
  if ((self = [super init])) {
    _alg = alg;
    _typ = typ;
    _kid = kid;
  }

  return self;
}

+ (nullable FBSDKAuthenticationTokenHeader *)headerFromEncodedString:(NSString *)encodedHeader
{
  NSError *error;
  NSData *headerData = [FBSDKBase64 decodeAsData:[FBSDKBase64 base64FromBase64Url:encodedHeader]];

  if (headerData) {
    NSDictionary<NSString *, id> *header = [FBSDKTypeUtility JSONObjectWithData:headerData options:0 error:&error];
    NSString *alg = [FBSDKTypeUtility dictionary:header objectForKey:@"alg" ofType:NSString.class];
    NSString *typ = [FBSDKTypeUtility dictionary:header objectForKey:@"typ" ofType:NSString.class];
    NSString *kid = [FBSDKTypeUtility dictionary:header objectForKey:@"kid" ofType:NSString.class];
    if (!error && [alg isEqualToString:@"RS256"] && [typ isEqualToString:@"JWT"] && kid.length > 0) {
      return [[FBSDKAuthenticationTokenHeader alloc] initWithAlg:alg typ:typ kid:kid];
    }
  }

  return nil;
}

- (BOOL)isEqualToHeader:(FBSDKAuthenticationTokenHeader *)header
{
  return [_alg isEqualToString:header.alg]
  && [_typ isEqualToString:header.typ]
  && [_kid isEqualToString:header.kid];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:FBSDKAuthenticationTokenHeader.class]) {
    return NO;
  }

  return [self isEqualToHeader:(FBSDKAuthenticationTokenHeader *)object];
}

@end
