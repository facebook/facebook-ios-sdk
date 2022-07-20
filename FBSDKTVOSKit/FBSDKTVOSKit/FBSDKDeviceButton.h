/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKButton.h>

NS_ASSUME_NONNULL_BEGIN

/*
 An internal base class for device related flows.

 This is an internal API that should not be used directly and is subject to change.
 */
NS_SWIFT_NAME(FBDeviceButton)
@interface FBSDKDeviceButton : FBSDKButton
- (CGSize)sizeThatFits:(CGSize)size attributedTitle:(NSAttributedString *)title;
- (nullable NSAttributedString *)attributedTitleStringFromString:(NSString *)string;
@end

NS_ASSUME_NONNULL_END

#endif
