/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>
#import <FBSDKCoreKit_Basics/NSNotificationCenter+NotificationDelivering.h>

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

- (id<NSObject>)fb_addObserverForName:(nullable NSNotificationName)name
                               object:(nullable id)object
                                queue:(nullable NSOperationQueue *)queue
                           usingBlock:(void (^)(NSNotification * _Nonnull))block
{
  return [self addObserverForName:name object:object queue:queue usingBlock:block];
}

- (void)fb_removeObserver:(id)observer
{
  [self removeObserver:observer];
}

@end

NS_ASSUME_NONNULL_END
