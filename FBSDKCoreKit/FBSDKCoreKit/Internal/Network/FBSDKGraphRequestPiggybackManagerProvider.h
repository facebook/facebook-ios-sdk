/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKGraphRequestPiggybackManagerProviding.h"

NS_ASSUME_NONNULL_BEGIN

/// A concrete class for providing types that conform to `GraphRequestPiggybackManaging`
NS_SWIFT_NAME(GraphRequestPiggybackManagerProvider)
@interface FBSDKGraphRequestPiggybackManagerProvider : NSObject <FBSDKGraphRequestPiggybackManagerProviding>
@end

NS_ASSUME_NONNULL_END
