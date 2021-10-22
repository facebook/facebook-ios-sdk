/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAccessToken.h>

#import "FBSDKAccessTokenProtocols.h"

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the AccessToken protocols
@interface FBSDKAccessToken (AccessTokenProviding) <FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>
@end

NS_ASSUME_NONNULL_END
