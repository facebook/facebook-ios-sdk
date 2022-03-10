/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

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

/// the delegate
@property (nonatomic, weak) id<FBSDKLoginTooltipViewDelegate> delegate;

/**  if set to YES, the view will always be displayed and the delegate's
  `loginTooltipView:shouldAppear:` will NOT be called. */
@property (nonatomic, getter = shouldForceDisplay, assign) BOOL forceDisplay;

@end

NS_ASSUME_NONNULL_END

#endif
