/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import <FBSDKLoginKit/FBSDKTooltipView.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKLoginTooltipViewDelegate;

/**

  Represents a tooltip to be displayed next to a Facebook login button
  to highlight features for new users.


 The `FBSDKLoginButton` may display this view automatically. If you do
  not use the `FBSDKLoginButton`, you can manually call one of the `present*` methods
  as appropriate and customize behavior via `FBSDKLoginTooltipViewDelegate` delegate.

  By default, the `FBSDKLoginTooltipView` is not added to the superview until it is
  determined the app has migrated to the new login experience. You can override this
  (e.g., to test the UI layout) by implementing the delegate or setting `forceDisplay` to YES.

 */
NS_SWIFT_NAME(FBLoginTooltipView)
@interface FBSDKLoginTooltipView : FBSDKTooltipView

/**  the delegate */
@property (nonatomic, weak) id<FBSDKLoginTooltipViewDelegate> delegate;

/**  if set to YES, the view will always be displayed and the delegate's
  `loginTooltipView:shouldAppear:` will NOT be called. */
@property (nonatomic, getter = shouldForceDisplay, assign) BOOL forceDisplay;

@end

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

#endif
