/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppLinkEventPosting)
@protocol FBSDKAppLinkEventPosting

// UNCRUSTIFY_FORMAT_OFF
- (void)postNotificationForEventName:(NSString *)name
                                args:(NSDictionary<NSString *, id> *)args
NS_SWIFT_NAME(postNotification(eventName:arguments:));

// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
