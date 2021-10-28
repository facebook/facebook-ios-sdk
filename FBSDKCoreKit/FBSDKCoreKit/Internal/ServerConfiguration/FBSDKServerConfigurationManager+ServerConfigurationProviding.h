/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationProviding.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKServerConfigurationManager (ServerConfigurationProviding) <FBSDKServerConfigurationProviding>
@end

NS_ASSUME_NONNULL_END
