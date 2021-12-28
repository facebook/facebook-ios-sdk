/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Custom UIPresentationController that is similar to
// UIModalPresentationFormSheet style (which is not available
// on tvOS).
NS_SWIFT_NAME(FBModalFormPresentationController)
@interface FBSDKModalFormPresentationController : UIPresentationController

@end

NS_ASSUME_NONNULL_END

#endif
