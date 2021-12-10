/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsStateFactory.h"

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsState.h"

@implementation FBSDKAppEventsStateFactory

- (FBSDKAppEventsState *)createStateWithToken:(NSString *)tokenString appID:(NSString *)appID
{
  return [[FBSDKAppEventsState alloc] initWithToken:tokenString appID:appID];
}

@end
