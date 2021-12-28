/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginManagerResult+Internal.h"

@implementation FBSDKDeviceLoginManagerResult

- (instancetype)initWithToken:(FBSDKAccessToken *)token
                  isCancelled:(BOOL)cancelled
{
  if ((self = [super init])) {
    _accessToken = token;
    _cancelled = cancelled;
  }
  return self;
}

@end
