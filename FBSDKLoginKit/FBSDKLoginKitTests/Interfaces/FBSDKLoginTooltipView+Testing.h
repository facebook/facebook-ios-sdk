/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginTooltipView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginTooltipView (Testing)

- (void)presentInView:(UIView *)view withArrowPosition:(CGPoint)arrowPosition direction:(FBSDKTooltipViewArrowDirection)arrowDirection;
- (instancetype)initWithServerConfigurationProvider:(nonnull id<_FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                     stringProvider:(nonnull id<_FBSDKUserInterfaceStringProviding>)stringProvider;

@end

NS_ASSUME_NONNULL_END
