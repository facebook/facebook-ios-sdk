/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginRecoveryAttempter.h"

#import "FBSDKLoginKit+Internal.h"
#import "FBSDKLoginManagerLoginResult+Internal.h"

@implementation FBSDKLoginRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error
               completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  NSSet<NSString *> *currentPermissions = FBSDKAccessToken.currentAccessToken.permissions;
  if (currentPermissions.count > 0) {
    FBSDKLoginManager *login = [FBSDKLoginManager new];
    [login logInWithPermissions:currentPermissions.allObjects fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *loginError) {
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
