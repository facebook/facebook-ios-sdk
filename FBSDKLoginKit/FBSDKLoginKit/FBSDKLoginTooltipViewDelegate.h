/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 @protocol

 The `FBSDKLoginTooltipViewDelegate` protocol defines the methods used to receive event
 notifications from `FBSDKLoginTooltipView` objects.
 */
NS_SWIFT_NAME(LoginTooltipViewDelegate)
@protocol FBSDKLoginTooltipViewDelegate <NSObject>

@optional

/**
 Asks the delegate if the tooltip view should appear

 @param view The tooltip view.
 @param appIsEligible The value fetched from the server identifying if the app
 is eligible for the new login experience.

 Use this method to customize display behavior.
 */
- (BOOL)loginTooltipView:(FBSDKLoginTooltipView *)view shouldAppear:(BOOL)appIsEligible;

/**
 Tells the delegate the tooltip view will appear, specifically after it's been
 added to the super view but before the fade in animation.

 @param view The tooltip view.
 */
- (void)loginTooltipViewWillAppear:(FBSDKLoginTooltipView *)view;

/**
 Tells the delegate the tooltip view will not appear (i.e., was not
 added to the super view).

 @param view The tooltip view.
 */
- (void)loginTooltipViewWillNotAppear:(FBSDKLoginTooltipView *)view;

@end

NS_ASSUME_NONNULL_END
