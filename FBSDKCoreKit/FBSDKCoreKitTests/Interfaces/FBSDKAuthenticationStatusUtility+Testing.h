/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationStatusUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationStatusUtility (Testing)

+ (void)_handleResponse:(NSURLResponse *)response;
+ (NSURL *)_requestURL;
+ (void)checkAuthenticationStatus;

@end

NS_ASSUME_NONNULL_END
