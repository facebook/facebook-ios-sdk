// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if TARGET_OS_TV

#import "FBSDKDeviceShareButton.h"
#import "FBSDKDeviceShareViewController.h"

#if defined BUCK || defined FBSDKCOCOAPODS || defined __cplusplus
#import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
#import "FBSDKCoreKit+Internal.h"
#endif

@implementation FBSDKDeviceShareButton

- (void)configureButton
{
  [self configureWithIcon:nil
                    title:nil
          backgroundColor:nil
         highlightedColor:nil];

  NSString *title =
  NSLocalizedStringWithDefaultValue(@"ShareButton.Share", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                    @"Share",
                                    @"The label for FBSDKShareButton");
  NSAttributedString *attributedTitle = [self attributedTitleStringFromString:title];
  [self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
  [self setAttributedTitle:attributedTitle forState:UIControlStateFocused];
  [self setAttributedTitle:attributedTitle forState:UIControlStateSelected];
  [self setAttributedTitle:attributedTitle forState:UIControlStateSelected | UIControlStateHighlighted];
  [self setAttributedTitle:attributedTitle forState:UIControlStateSelected | UIControlStateFocused];

  self.enabled = NO;
  [self addTarget:self action:@selector(_buttonPressed:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

#pragma mark - Properties

- (void)setShareContent:(id<FBSDKSharingContent>)shareContent
{
  if (_shareContent != shareContent) {
    _shareContent = shareContent;
    self.enabled = (shareContent != nil);
  }
}

#pragma mark - Implementation

- (void)_buttonPressed:(id)sender
{
  UIViewController *parentViewController = [FBSDKInternalUtility viewControllerForView:self];
  if (_shareContent) {
    FBSDKDeviceShareViewController *vc = [[FBSDKDeviceShareViewController alloc] initWithShareContent:_shareContent];
    [parentViewController presentViewController:vc animated:YES completion:NULL];
  }
}

@end

#endif
