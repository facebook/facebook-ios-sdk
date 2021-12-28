/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSendButton.h"

#import "FBSDKMessageDialog.h"
#import "FBSDKMessengerIcon.h"
#import "FBSDKShareAppEventName.h"

@interface FBSDKSendButton () <FBSDKButtonImpressionLogging>
@property (nonatomic) FBSDKMessageDialog *dialog;
@end

@implementation FBSDKSendButton

#pragma mark - Properties

- (id<FBSDKSharingContent>)shareContent
{
  return _dialog.shareContent;
}

- (void)setShareContent:(id<FBSDKSharingContent>)shareContent
{
  _dialog.shareContent = shareContent;
  [self checkImplicitlyDisabled];
}

#pragma mark - FBSDKButtonImpressionTracking

- (nullable NSDictionary<NSString *, id> *)analyticsParameters
{
  return nil;
}

- (FBSDKAppEventName)impressionTrackingEventName
{
  return FBSDKAppEventNameSendButtonImpression;
}

- (NSString *)impressionTrackingIdentifier
{
  return @"send";
}

#pragma mark - FBSDKButton

- (void)configureButton
{
  NSString *title =
  NSLocalizedStringWithDefaultValue(
    @"SendButton.Send",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Send",
    @"The label for FBSDKSendButton"
  );

  UIColor *backgroundColor = [UIColor colorWithRed:0.0 green:132.0 / 255.0 blue:1.0 alpha:1.0];
  UIColor *highlightedColor = [UIColor colorWithRed:0.0 green:111.0 / 255.0 blue:1.0 alpha:1.0];

  [self configureWithIcon:[FBSDKMessengerIcon new]
                    title:title
          backgroundColor:backgroundColor
         highlightedColor:highlightedColor];

  [self addTarget:self action:@selector(_share:) forControlEvents:UIControlEventTouchUpInside];
  _dialog = [FBSDKMessageDialog new];
}

- (BOOL)isImplicitlyDisabled
{
  return !_dialog.canShow || ![_dialog validateWithError:NULL];
}

- (void)_share:(id)sender
{
  [self logTapEventWithEventName:FBSDKAppEventNameSendButtonDidTap parameters:self.analyticsParameters];
  [_dialog show];
}

@end

#endif
