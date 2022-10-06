/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/**
 The `LoginTooltipViewDelegate` protocol defines the methods used to receive event
 notifications from `FBLoginTooltipView` objects.
 */
@objc(FBSDKLoginTooltipViewDelegate)
public protocol LoginTooltipViewDelegate {

  /**
   Asks the delegate if the tooltip view should appear

   @param view The tooltip view.
   @param appIsEligible The value fetched from the server identifying if the app
   is eligible for the new login experience.

   Use this method to customize display behavior.
   */
  @objc(loginTooltipView:shouldAppear:)
  optional func loginTooltipView(_ view: FBLoginTooltipView, shouldAppear appIsEligible: Bool) -> Bool

  /**
   Tells the delegate the tooltip view will appear, specifically after it's been
   added to the super view but before the fade in animation.

   @param view The tooltip view.
   */
  @objc(loginTooltipViewWillAppear:)
  optional func loginTooltipViewWillAppear(_ view: FBLoginTooltipView)

  /**
   Tells the delegate the tooltip view will not appear (i.e., was not
   added to the super view).

   @param view The tooltip view.
   */
  @objc(loginTooltipViewWillNotAppear:)
  optional func loginTooltipViewWillNotAppear(_ view: FBLoginTooltipView)
}

#endif
