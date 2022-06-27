/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a type that can post a notification
NS_SWIFT_NAME(NotificationPosting)
@protocol FBSDKNotificationPosting

// UNCRUSTIFY_FORMAT_OFF
- (void)fb_postNotificationName:(NSNotificationName)name
                         object:(nullable id)object
                       userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
NS_SWIFT_NAME(fb_post(name:object:userInfo:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
