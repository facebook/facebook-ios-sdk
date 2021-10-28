/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKErrorConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// Describes any type that can provide an error configuration
NS_SWIFT_NAME(ErrorConfigurationProviding)
@protocol FBSDKErrorConfigurationProviding

- (nullable id<FBSDKErrorConfiguration>)errorConfiguration;

@end

NS_ASSUME_NONNULL_END
