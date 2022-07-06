/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a type that can deliver a notification
NS_SWIFT_NAME(NotificationDelivering)
@protocol FBSDKNotificationDelivering

- (void)fb_addObserver:(id)observer
              selector:(SEL)selector
                  name:(nullable NSNotificationName)name
                object:(nullable id)object;

- (void)fb_removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
