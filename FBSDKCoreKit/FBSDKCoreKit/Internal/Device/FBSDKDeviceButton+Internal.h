/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKDeviceButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceButton ()

- (nullable NSAttributedString *)attributedTitleStringFromString:(NSString *)string;
- (CGSize)sizeThatFits:(CGSize)size title:(NSString *)title;
- (CGSize)sizeThatFits:(CGSize)size attributedTitle:(NSAttributedString *)title;

@end

NS_ASSUME_NONNULL_END

#endif
