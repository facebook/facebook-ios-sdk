/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKMeasurementEvent.h"

@protocol FBSDKAppLinkEventPosting;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKMeasurementEvent (AppLinkEventPosting) <FBSDKAppLinkEventPosting>
@end

NS_ASSUME_NONNULL_END

#endif
