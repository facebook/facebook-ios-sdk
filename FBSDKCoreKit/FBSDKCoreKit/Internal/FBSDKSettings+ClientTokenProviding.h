/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKSettings.h"

@protocol FBSDKClientTokenProviding;

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the client token providing protocol
@interface FBSDKSettings (SettingsProtocol) <FBSDKClientTokenProviding>
@end

NS_ASSUME_NONNULL_END
