/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKShareKit/FBSDKShareDialogMode.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A base interface for indicating a custom URL scheme
 */
DEPRECATED_MSG_ATTRIBUTE("`SharingScheme` is deprecated and will be removed in the next major release")
NS_SWIFT_NAME(SharingScheme)
@protocol FBSDKSharingScheme

/**
 Asks the receiver to provide a custom scheme.
 @param mode The intended dialog mode for sharing the content.
 @return A custom URL scheme to use for the specified mode, or nil.
 */
- (nullable NSString *)schemeForMode:(FBSDKShareDialogMode)mode
    DEPRECATED_MSG_ATTRIBUTE("`SharingScheme` is deprecated and will be removed in the next major release");

@end

NS_ASSUME_NONNULL_END

#endif
