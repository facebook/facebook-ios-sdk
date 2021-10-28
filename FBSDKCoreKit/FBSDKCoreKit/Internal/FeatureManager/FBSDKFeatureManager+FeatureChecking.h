/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureManager.h"

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the FBSDKFeatureChecking protocol
@interface FBSDKFeatureManager (FBSDKFeatureChecking) <FBSDKFeatureChecking>
@end

NS_ASSUME_NONNULL_END
