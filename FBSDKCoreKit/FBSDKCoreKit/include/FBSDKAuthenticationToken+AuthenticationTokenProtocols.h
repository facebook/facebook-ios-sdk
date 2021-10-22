/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAuthenticationToken.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenProtocols.h>

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the AuthenticationToken protocols
@interface FBSDKAuthenticationToken (AuthenticationTokenProviding) <FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>
@end

NS_ASSUME_NONNULL_END
