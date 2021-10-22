/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
NS_SWIFT_NAME(SharingScheme)
@protocol FBSDKSharingScheme

/**
 Asks the receiver to provide a custom scheme.
 @param mode The intended dialog mode for sharing the content.
 @return A custom URL scheme to use for the specified mode, or nil.
 */
- (nullable NSString *)schemeForMode:(FBSDKShareDialogMode)mode;

@end

NS_ASSUME_NONNULL_END

#endif
