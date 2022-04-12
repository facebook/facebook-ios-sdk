/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginTooltipView.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKLoginTooltipViewDelegate.h"

@interface FBSDKLoginTooltipView ()

@property (nonatomic) id<_FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic) id<_FBSDKUserInterfaceStringProviding> stringProvider;

@end

@implementation FBSDKLoginTooltipView

- (instancetype)init
{
  return [self initWithServerConfigurationProvider:[FBSDKServerConfigurationProvider new]
                                    stringProvider:FBSDKInternalUtility.sharedUtility];
}

// MARK: - Instance Dependencies

- (instancetype)initWithServerConfigurationProvider:(nonnull id<_FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                     stringProvider:(nonnull id<_FBSDKUserInterfaceStringProviding>)stringProvider
{
  NSString *tooltipMessage =
  NSLocalizedStringWithDefaultValue(
    @"LoginTooltip.Message",
    @"FacebookSDK",
    [stringProvider bundleForStrings],
    @"You're in control - choose what info you want to share with apps.",
    @"The message of the FBSDKLoginTooltipView"
  );

  if ((self = [super initWithTagline:nil message:tooltipMessage colorStyle:FBSDKTooltipColorStyleFriendlyBlue])) {
    _serverConfigurationProvider = serverConfigurationProvider;
    _stringProvider = stringProvider;
  }

  return self;
}

- (void)presentInView:(UIView *)view withArrowPosition:(CGPoint)arrowPosition direction:(FBSDKTooltipViewArrowDirection)arrowDirection
{
  if (self.forceDisplay) {
    [super presentInView:view withArrowPosition:arrowPosition direction:arrowDirection];
  } else {
    [self fetchTooltipConfigurationWithView:view arrowPosition:arrowPosition direction:arrowDirection];
  }
}

- (void)fetchTooltipConfigurationWithView:(UIView *)view arrowPosition:(CGPoint)arrowPosition direction:(FBSDKTooltipViewArrowDirection)arrowDirection
{
  [self.serverConfigurationProvider loadServerConfigurationWithCompletionBlock:^(FBSDKLoginTooltip *_Nullable loginTooltip, NSError *_Nullable error) {
    self.message = loginTooltip.text;
    BOOL shouldDisplay = loginTooltip.isEnabled;
    if ([self.delegate respondsToSelector:@selector(loginTooltipView:shouldAppear:)]) {
      shouldDisplay = [self.delegate loginTooltipView:self shouldAppear:shouldDisplay];
    }
    if (shouldDisplay) {
      [super presentInView:view withArrowPosition:arrowPosition direction:arrowDirection];
      if ([self.delegate respondsToSelector:@selector(loginTooltipViewWillAppear:)]) {
        [self.delegate loginTooltipViewWillAppear:self];
      }
    } else {
      if ([self.delegate respondsToSelector:@selector(loginTooltipViewWillNotAppear:)]) {
        [self.delegate loginTooltipViewWillNotAppear:self];
      }
    }
  }];
}

@end

#endif
