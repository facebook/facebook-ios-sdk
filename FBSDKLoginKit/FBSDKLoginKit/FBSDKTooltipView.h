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

NS_ASSUME_NONNULL_BEGIN

/**
 FBSDKTooltipViewArrowDirection enum

  Passed on construction to determine arrow orientation.
 */
typedef NS_ENUM(NSUInteger, FBSDKTooltipViewArrowDirection) {
  /// View is located above given point, arrow is pointing down.
  FBSDKTooltipViewArrowDirectionDown = 0,
  /// View is located below given point, arrow is pointing up.
  FBSDKTooltipViewArrowDirectionUp = 1,
} NS_SWIFT_NAME(FBTooltipView.ArrowDirection);

/**
 FBSDKTooltipColorStyle enum

  Passed on construction to determine color styling.
 */
typedef NS_ENUM(NSUInteger, FBSDKTooltipColorStyle) {
  /// Light blue background, white text, faded blue close button.
  FBSDKTooltipColorStyleFriendlyBlue = 0,
  /// Dark gray background, white text, light gray close button.
  FBSDKTooltipColorStyleNeutralGray = 1,
} NS_SWIFT_NAME(FBTooltipView.ColorStyle);

/**
 Tooltip bubble with text in it used to display tips for UI elements,
 with a pointed arrow (to refer to the UI element).

 The tooltip fades in and will automatically fade out. See `displayDuration`.
 */
NS_SWIFT_NAME(FBTooltipView)
@interface FBSDKTooltipView : UIView

/**
 Gets or sets the amount of time in seconds the tooltip should be displayed.
 Set this to zero to make the display permanent until explicitly dismissed.
 Defaults to six seconds.
 */
@property (nonatomic, assign) CFTimeInterval displayDuration;

/**
 Gets or sets the color style after initialization.
 Defaults to value passed to -initWithTagline:message:colorStyle:.
 */
@property (nonatomic, assign) FBSDKTooltipColorStyle colorStyle;

/// Gets or sets the message.
@property (nullable, nonatomic, copy) NSString *message;

/// Gets or sets the optional phrase that comprises the first part of the label (and is highlighted differently).
@property (nullable, nonatomic, copy) NSString *tagline;

/**
 Designated initializer.

 @param tagline First part of the label, that will be highlighted with different color. Can be nil.

 @param message Main message to display.

 @param colorStyle Color style to use for tooltip.

 If you need to show a tooltip for login, consider using the `FBSDKLoginTooltipView` view.

 See FBSDKLoginTooltipView
 */
- (instancetype)initWithTagline:(nullable NSString *)tagline
                        message:(nullable NSString *)message
                     colorStyle:(FBSDKTooltipColorStyle)colorStyle;

/**
 Show tooltip at the top or at the bottom of given view.
 Tooltip will be added to anchorView.window.rootViewController.view

 @param anchorView view to show at, must be already added to window view hierarchy, in order to decide
 where tooltip will be shown. (If there's not enough space at the top of the anchorView in window bounds -
 tooltip will be shown at the bottom of it)

 Use this method to present the tooltip with automatic positioning or
 use -presentInView:withArrowPosition:direction: for manual positioning
 If anchorView is nil or has no window - this method does nothing.
 */
- (void)presentFromView:(UIView *)anchorView;

/**
 Adds tooltip to given view, with given position and arrow direction.

 @param view View to be used as superview.

 @param arrowPosition Point in view's cordinates, where arrow will be pointing

 @param arrowDirection whenever arrow should be pointing up (message bubble is below the arrow) or
 down (message bubble is above the arrow).
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)presentInView:(UIView *)view
    withArrowPosition:(CGPoint)arrowPosition
            direction:(FBSDKTooltipViewArrowDirection)arrowDirection
NS_SWIFT_NAME(present(in:arrowPosition:direction:));
// UNCRUSTIFY_FORMAT_ON

/**
 Remove tooltip manually.

 Calling this method isn't necessary - tooltip will dismiss itself automatically after the `displayDuration`.
 */
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

#endif
