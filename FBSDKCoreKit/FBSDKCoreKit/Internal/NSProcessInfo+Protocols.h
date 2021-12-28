/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKMacCatalystDetermining.h"
#import "FBSDKOperatingSystemVersionComparing.h"

NS_ASSUME_NONNULL_BEGIN

/// Default conformance to the `OperatingSystemVersionComparing` protocol
@interface NSProcessInfo (OperatingSystemVersionComparing) <FBSDKOperatingSystemVersionComparing>
@end

@interface NSProcessInfo (MacCatalystDetermining) <FBSDKMacCatalystDetermining>
@end

NS_ASSUME_NONNULL_END
