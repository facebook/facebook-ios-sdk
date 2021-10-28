/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/* FBSDKAuthenticationTokenStatusChecker_h */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AuthenticationStatusUtility)
@interface FBSDKAuthenticationStatusUtility : NSObject

/**
  Fetches the latest authentication status from server. This will invalidate
  the current user session if the returned status is not authorized.
 */
+ (void)checkAuthenticationStatus;

@end

NS_ASSUME_NONNULL_END
