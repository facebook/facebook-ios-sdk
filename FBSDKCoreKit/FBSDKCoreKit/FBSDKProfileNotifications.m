/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKProfileNotifications.h>

NS_ASSUME_NONNULL_BEGIN

NSNotificationName const FBSDKProfileDidChangeNotification = @"com.facebook.sdk.FBSDKProfile.FBSDKProfileDidChangeNotification";

NSString *const FBSDKProfileChangeOldKey = @"FBSDKProfileOld";
NSString *const FBSDKProfileChangeNewKey = @"FBSDKProfileNew";

NS_ASSUME_NONNULL_END

#endif
