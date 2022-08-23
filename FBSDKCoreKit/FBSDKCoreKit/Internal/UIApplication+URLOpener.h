/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the URL opener protocol
@interface UIApplication (URLOpener) <FBSDKInternalURLOpener>
@end

NS_ASSUME_NONNULL_END

#endif
