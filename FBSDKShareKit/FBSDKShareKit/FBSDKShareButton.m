/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareButton.h"

#import "FBSDKShareAppEventName.h"
#import "FBSDKShareDialog.h"

@interface FBSDKShareButton ()
@property (nonatomic) FBSDKShareDialog *dialog;
@end

@implementation FBSDKShareButton

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
  return FBSDKAppEventNameShareButtonImpression;
}

- (NSString *)impressionTrackingIdentifier
{
  return @"share";
}

#pragma mark - FBSDKButton

- (void)configureButton
{
  NSString *title =
  NSLocalizedStringWithDefaultValue(
    @"ShareButton.Share",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Share",
    @"The label for FBSDKShareButton"
  );

  [self configureWithIcon:nil
                    title:title
          backgroundColor:nil
         highlightedColor:nil];

  [self addTarget:self action:@selector(_share:) forControlEvents:UIControlEventTouchUpInside];
  _dialog = [[FBSDKShareDialog alloc] initWithViewController:nil
                                                     content:nil
                                                    delegate:nil];
}

- (BOOL)isImplicitlyDisabled
{
  return ![_dialog canShow] || ![_dialog validateWithError:NULL];
}

- (void)_share:(id)sender
{
  [self logTapEventWithEventName:FBSDKAppEventNameShareButtonDidTap parameters:[self analyticsParameters]];
  [_dialog show];
}

@end

#endif
