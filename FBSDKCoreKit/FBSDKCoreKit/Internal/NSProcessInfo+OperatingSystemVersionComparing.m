/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "NSProcessInfo+OperatingSystemVersionComparing.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSProcessInfo, OperatingSystemVersionComparing)
@implementation NSProcessInfo (OperatingSystemVersionComparing)

- (BOOL)fb_isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version
{
  return [self isOperatingSystemAtLeastVersion:version];
}

@end

NS_ASSUME_NONNULL_END
