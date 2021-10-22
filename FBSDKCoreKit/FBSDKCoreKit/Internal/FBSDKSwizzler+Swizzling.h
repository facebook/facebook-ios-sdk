/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKSwizzler.h"
#import "FBSDKSwizzling.h"

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the Swizzling interface
@interface FBSDKSwizzler (Swizzling) <FBSDKSwizzling>
@end

NS_ASSUME_NONNULL_END
