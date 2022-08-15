/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/_FBSDKNotificationPosting.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_INTERFACE(NSNotificationCenter, NotificationPosting)
@interface NSNotificationCenter (NotificationPosting) <_FBSDKNotificationPosting>

@end

NS_ASSUME_NONNULL_END
