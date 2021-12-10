/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Describes any type that can compare the current operating system version to a given version
NS_SWIFT_NAME(OperatingSystemVersionComparing)
@protocol FBSDKOperatingSystemVersionComparing

// UNCRUSTIFY_FORMAT_OFF
- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version
NS_SWIFT_NAME(isOperatingSystemAtLeast(_:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
