/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingPayload.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NSString *const kGamingPayload = @"payload";
NSString *const kGamingPayloadGameRequestID = @"game_request_id";
NSString *const kGamingPayloadContextTokenID = @"context_token_id";

@implementation FBSDKGamingPayload : NSObject

- (instancetype)initWithURL:(FBSDKURL *_Nonnull)url
{
  if ((self = [super init])) {
    _URL = url;
  }
  return self;
}

- (NSString *)gameRequestID
{
  if (self.URL) {
    return self.URL.appLinkExtras[kGamingPayloadGameRequestID];
  }
  return @"";
}

- (NSString *)payload
{
  if (self.URL) {
    return self.URL.appLinkExtras[kGamingPayload];
  }
  return @"";
}

@end
