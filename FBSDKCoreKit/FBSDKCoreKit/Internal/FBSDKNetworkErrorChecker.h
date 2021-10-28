/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKNetworkErrorChecking.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Concrete type providing functionality that checks whether an error represents a
 network error.
 */
NS_SWIFT_NAME(NetworkErrorChecker)
@interface FBSDKNetworkErrorChecker : NSObject <FBSDKNetworkErrorChecking>

@end

NS_ASSUME_NONNULL_END
