/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPI.h"
#import "FBSDKBridgeAPIResponseCreating.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIResponse () <FBSDKBridgeAPIResponseCreating>
@end

NS_ASSUME_NONNULL_END

#endif
