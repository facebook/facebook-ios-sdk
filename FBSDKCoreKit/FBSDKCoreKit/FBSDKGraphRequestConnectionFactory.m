/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestConnectionFactory.h"

#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>

@implementation FBSDKGraphRequestConnectionFactory

- (nonnull id<FBSDKGraphRequestConnecting>)createGraphRequestConnection
{
  return [FBSDKGraphRequestConnection new];
}

@end
