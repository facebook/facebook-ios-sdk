/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginRecoveryAttempter.h"

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKLoginManager+Internal.h"
#import "FBSDKLoginManagerLoginResult+Internal.h"

@implementation FBSDKLoginRecoveryAttempter

- (instancetype)init
{
  return [self initWithLoginManager:[FBSDKLoginManager new]
                accessTokenProvider:FBSDKAccessToken.class];
}

- (instancetype)initWithLoginManager:(id<FBSDKLoginProviding>)loginManager
                 accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  if ((self = [super init])) {
    _loginManager = loginManager;
    _accessTokenProvider = accessTokenProvider;
  }
  return self;
}

- (void)attemptRecoveryFromError:(NSError *)error
               completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  NSSet<NSString *> *currentPermissions = [[self.accessTokenProvider currentAccessToken] permissions];
  if (currentPermissions.count > 0) {
    [self.loginManager logInWithPermissions:currentPermissions.allObjects
                         fromViewController:nil
                                    handler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
                                      // we can only consider a recovery successful if there are no declines
                                      // (note this could still set an updated currentAccessToken).
                                      completionHandler(!loginError && !result.isCancelled && result.declinedPermissions.count == 0);
                                    }];
  } else {
    completionHandler(NO);
  }
}

@end

#endif
