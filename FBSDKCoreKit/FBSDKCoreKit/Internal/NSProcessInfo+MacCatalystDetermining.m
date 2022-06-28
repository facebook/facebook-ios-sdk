/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "NSProcessInfo+MacCatalystDetermining.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSProcessInfo, MacCatalystDetermining)
@implementation NSProcessInfo (MacCatalystDetermining)

- (BOOL)fb_isMacCatalystApp
{
  if (@available(iOS 13, tvOS 13, *)) {
    return self.isMacCatalystApp;
  } else {
    return NO;
  }
}

@end

NS_ASSUME_NONNULL_END
