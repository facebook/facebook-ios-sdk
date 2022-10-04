/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

/**
 Notification name indicating that the current profile has changed.

 The user info dictionary of the notification may contain values for the keys
 `ProfileChangeOldKey` and `ProfileChangeNewKey`.
 */
FOUNDATION_EXPORT NSNotificationName const FBSDKProfileDidChangeNotification
NS_SWIFT_NAME(ProfileDidChange);

/**
 Key in notification's user info object for storing the old profile.

 If there was no old profile, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKProfileChangeOldKey
NS_SWIFT_NAME(ProfileChangeOldKey);

/**
 Key in notification's user info object for storing the new profile.

 If there is no new profile, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKProfileChangeNewKey
NS_SWIFT_NAME(ProfileChangeNewKey);

NS_ASSUME_NONNULL_END

#endif
