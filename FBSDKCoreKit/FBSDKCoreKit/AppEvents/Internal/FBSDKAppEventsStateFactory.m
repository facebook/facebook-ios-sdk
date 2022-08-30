/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Foundation/Foundation.h>

@implementation FBSDKAppEventsStateFactory

- (FBSDKAppEventsState *)createStateWithToken:(NSString *)tokenString appID:(NSString *)appID
{
  return [[FBSDKAppEventsState alloc] initWithToken:tokenString appID:appID];
}

@end
