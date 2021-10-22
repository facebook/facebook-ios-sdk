/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

#import "FBSDKInternalURLOpener.h"

NS_ASSUME_NONNULL_BEGIN

// Default conformance to the URL opener protocol
@interface UIApplication (URLOpener) <FBSDKInternalURLOpener>
@end

NS_ASSUME_NONNULL_END

#endif
