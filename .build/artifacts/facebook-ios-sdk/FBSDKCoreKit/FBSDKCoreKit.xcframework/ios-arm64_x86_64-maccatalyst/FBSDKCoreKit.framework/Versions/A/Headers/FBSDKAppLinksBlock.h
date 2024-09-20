/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

@class FBSDKAppLink;

NS_ASSUME_NONNULL_BEGIN

/**
 Describes the callback for appLinkFromURLInBackground.
 @param appLinks the FBSDKAppLinks representing the deferred App Links
 @param error the error during the request, if any
 */
typedef void (^ FBSDKAppLinksBlock)(NSDictionary<NSURL *, FBSDKAppLink *> *appLinks,
  NSError *_Nullable error)
NS_SWIFT_NAME(AppLinksBlock);

NS_ASSUME_NONNULL_END

#endif
