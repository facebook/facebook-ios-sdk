/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKButton.h>
#import <FBSDKCoreKit/FBSDKButtonImpressionLogging.h>

#import "FBSDKEventLogging.h"
#import "FBSDKIcon+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKButton ()

@property (class, nullable, nonatomic, readonly) id applicationActivationNotifier;
@property (class, nullable, nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (class, nullable, nonatomic, readonly) Class<FBSDKAccessTokenProviding> accessTokenProvider;

#if DEBUG
+ (void)resetClassDependencies;
#endif

+ (void)configureWithApplicationActivationNotifier:(id)applicationActivationNotifier
                                       eventLogger:(id<FBSDKEventLogging>)eventLogger
                               accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider;

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
