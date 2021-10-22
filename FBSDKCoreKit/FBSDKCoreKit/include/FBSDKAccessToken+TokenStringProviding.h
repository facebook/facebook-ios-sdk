/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>

NS_ASSUME_NONNULL_BEGIN

/**

  Internal Type exposed to facilitate transition to Swift.
  API Subject to change or removal without warning. Do not use.

  @warning UNSAFE - DO NOT USE
*/

@interface FBSDKAccessToken (TokenStringProviding) <FBSDKTokenStringProviding>
@end

NS_ASSUME_NONNULL_END
