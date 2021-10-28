/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKButton.h>
#import <FBSDKCoreKit/FBSDKButtonImpressionTracking.h>

#import "FBSDKIcon+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKButton ()

+ (void)setApplicationActivationNotifier:(id)notifier;
- (void)logTapEventWithEventName:(NSString *)eventName
                      parameters:(nullable NSDictionary<NSString *, id> *)parameters;
- (void)configureButton;
- (void) configureWithIcon:(FBSDKIcon *)icon
                     title:(NSString *)title
           backgroundColor:(UIColor *)backgroundColor
          highlightedColor:(UIColor *)highlightedColor
             selectedTitle:(NSString *)selectedTitle
              selectedIcon:(FBSDKIcon *)selectedIcon
             selectedColor:(UIColor *)selectedColor
  selectedHighlightedColor:(UIColor *)selectedHighlightedColor;
- (UIColor *)defaultBackgroundColor;
- (UIColor *)defaultDisabledColor;
- (UIFont *)defaultFont;
- (UIColor *)defaultHighlightedColor;
- (FBSDKIcon *)defaultIcon;
- (UIColor *)defaultSelectedColor;

@end

NS_ASSUME_NONNULL_END
