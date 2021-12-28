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
- (void)postNotificationName:(NSNotificationName)aName
                      object:(nullable id)anObject
                    userInfo:(nullable NSDictionary<NSString *, id> *)aUserInfo
NS_SWIFT_NAME(post(name:object:userInfo:));
// UNCRUSTIFY_FORMAT_ON

@end

/// An internal protocol used to describe a type that can observe a notification
NS_SWIFT_NAME(NotificationObserving)
@protocol FBSDKNotificationObserving

- (void)addObserver:(id)observer
           selector:(SEL)aSelector
               name:(nullable NSNotificationName)aName
             object:(nullable id)anObject;

- (void)removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
