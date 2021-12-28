/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/FBSDKSharingContent.h>

NS_ASSUME_NONNULL_BEGIN

/**
  The common interface for sharing buttons.

 @see FBSDKSendButton

 @see FBSDKShareButton
 */
NS_SWIFT_NAME(SharingButton)
@protocol FBSDKSharingButton <NSObject>

/**
  The content to be shared.
 */
@property (nullable, nonatomic, copy) id<FBSDKSharingContent> shareContent;

@end

NS_ASSUME_NONNULL_END

#endif
