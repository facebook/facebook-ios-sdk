/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginCodeInfo+Internal.h"

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

@implementation FBSDKDeviceLoginCodeInfo

static int const FBDeviceLoginMinPollingInterval = 5;

- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger)pollingInterval
{
  if ((self = [super init])) {
    _identifier = [identifier copy];
    _loginCode = [loginCode copy];
    _verificationURL = [verificationURL copy];
    _expirationDate = [expirationDate copy];
    _pollingInterval = pollingInterval < FBDeviceLoginMinPollingInterval
    ? FBDeviceLoginMinPollingInterval
    : pollingInterval;
  }
  return self;
}

@end
