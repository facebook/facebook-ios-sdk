/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "NSNotificationCenter+NotificationPosting.h"

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSNotificationCenter, NotificationPosting)
@implementation NSNotificationCenter (NotificationPosting)

- (void)fb_postNotificationName:(NSNotificationName)name
                         object:(nullable id)object
                       userInfo:(nullable NSDictionary<NSString *,id> *)userInfo
{
  [self postNotificationName:name object:object userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
