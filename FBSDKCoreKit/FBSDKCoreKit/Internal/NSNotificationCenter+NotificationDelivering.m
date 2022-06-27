/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "NSNotificationCenter+NotificationDelivering.h"

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSNotificationCenter, NotificationDelivering)
@implementation NSNotificationCenter (NotificationDelivering)

- (void)fb_addObserver:(id)observer
              selector:(SEL)selector
                  name:(nullable NSNotificationName)name
                object:(nullable id)object
{
  [self addObserver:observer selector:selector name:name object:object];
}

- (void)fb_removeObserver:(id)observer
{
  [self removeObserver:observer];
}

@end

NS_ASSUME_NONNULL_END
