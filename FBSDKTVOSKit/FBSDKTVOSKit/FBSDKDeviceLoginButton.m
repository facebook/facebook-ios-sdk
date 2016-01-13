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

#import "FBSDKDeviceLoginButton.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDeviceLoginViewController.h"

#define FB_LOGO_SIZE 54.0
#define FB_LOGO_LEFT_MARGIN 36.0
#define RIGHT_MARGIN 12.0
#define PREFERRED_PADDING_BETWEEN_LOGO_TITLE 44.0

@interface FBSDKDeviceLoginButton() <FBSDKDeviceLoginViewControllerDelegate>

@end

@implementation FBSDKDeviceLoginButton
{
  NSString *_userID;
  NSString *_userName;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Layout

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
  [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];

  if (self == context.nextFocusedView) {
    [coordinator addCoordinatedAnimations:^{
      self.transform = CGAffineTransformMakeScale(1.05, 1.05);
      self.layer.shadowOpacity = 0.5;
    } completion:NULL];
  } else if (self == context.previouslyFocusedView) {
    [coordinator addCoordinatedAnimations:^{
      self.transform = CGAffineTransformInvert(CGAffineTransformMakeScale(1.05, 1.05));
      self.layer.shadowOpacity = 0;
    } completion:NULL];
  }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
  CGFloat centerY = CGRectGetMidY(contentRect);
  CGFloat y = centerY - (FB_LOGO_SIZE / 2.0);
  return CGRectMake(FB_LOGO_LEFT_MARGIN, y, FB_LOGO_SIZE, FB_LOGO_SIZE);
}

- (void)layoutSubviews
{
  NSAttributedString *title = [self _loginTitle];
  if (![title isEqualToAttributedString:[self attributedTitleForState:UIControlStateNormal]]) {
    [self setAttributedTitle:title forState:UIControlStateNormal];
  }

  [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  if (self.hidden) {
    return CGSizeZero;
  }
  CGSize selectedSize = [self sizeThatFits:size attributedTitle:[self _logOutTitle]];
  CGSize normalSize = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, size.height) attributedTitle:[self _longLogInTitle]];
  if (normalSize.width > size.width) {
    return normalSize = [self sizeThatFits:size attributedTitle:[self _shortLogInTitle]];
  }
  CGSize maxSize = CGSizeMake(MAX(normalSize.width, selectedSize.width),
                              MAX(normalSize.height, selectedSize.height));
  return CGSizeMake(maxSize.width, maxSize.height);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
  if (self.hidden || CGRectIsEmpty(self.bounds)) {
    return CGRectZero;
  }
  CGRect imageRect = [self imageRectForContentRect:contentRect];
  CGFloat titleX = CGRectGetMaxX(imageRect);
  CGRect rect = CGRectMake(titleX, 0, CGRectGetWidth(contentRect) - titleX - RIGHT_MARGIN, CGRectGetHeight(contentRect));

  if (!self.layer.needsLayout) {
    CGSize titleSize = [FBSDKMath ceilForSize:[self.titleLabel.attributedText boundingRectWithSize:contentRect.size
                                                                                           options:(NSStringDrawingUsesDeviceMetrics |
                                                                                                    NSStringDrawingUsesLineFragmentOrigin |
                                                                                                    NSStringDrawingUsesFontLeading)
                                                                                           context:NULL].size];
    CGFloat titlePadding = ( CGRectGetWidth(rect) - titleSize.width ) / 2;
    if (titlePadding > titleX) {
      // if there's room to re-center the text, do so.
      rect = CGRectMake(RIGHT_MARGIN, 0, CGRectGetWidth(contentRect) - RIGHT_MARGIN - RIGHT_MARGIN, CGRectGetHeight(contentRect));
    }
  }

  return rect;
}

- (void)updateConstraints
{
  // This is necessary to handle the correct title length for UIControlStateFocused
  // in case where the button is initialized with a wide frame, but then a smaller
  // constraint is applied at runtime.
  [self _updateContent];
  [super updateConstraints];
}

#pragma mark - FBSDKButton

- (void)configureButton
{
  NSAttributedString *logInTitle = [self _shortLogInTitle];
  NSAttributedString *logOutTitle = [self _logOutTitle];

  [self configureWithIcon:nil
                    title:nil
          backgroundColor:[super defaultBackgroundColor]
         highlightedColor:nil
            selectedTitle:nil
             selectedIcon:nil
            selectedColor:[super defaultBackgroundColor]
 selectedHighlightedColor:nil];
  [self setAttributedTitle:logInTitle forState:UIControlStateNormal];
  [self setAttributedTitle:logInTitle forState:UIControlStateFocused];
  [self setAttributedTitle:logOutTitle forState:UIControlStateSelected];
  [self setAttributedTitle:logOutTitle forState:UIControlStateSelected | UIControlStateHighlighted];
  [self setAttributedTitle:logOutTitle forState:UIControlStateSelected | UIControlStateFocused];

  [self _updateContent];

  [self addTarget:self action:@selector(_buttonPressed:) forControlEvents:UIControlEventPrimaryActionTriggered];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_acessTokenDidChangeNotification:)
                                               name:FBSDKAccessTokenDidChangeNotification
                                             object:nil];
}

- (UIFont *)defaultFont
{
  return [UIFont fontWithName:@"HelveticaNeue-Medium" size:38];
}

- (CGSize)sizeThatFits:(CGSize)size attributedTitle:(NSAttributedString *)title
{
  CGSize titleSize = [FBSDKMath ceilForSize:[title boundingRectWithSize:size
                                                                options:(NSStringDrawingUsesDeviceMetrics |
                                                                         NSStringDrawingUsesLineFragmentOrigin |
                                                                         NSStringDrawingUsesFontLeading)
                                                                context:NULL].size];
  CGFloat logoAndTitleWidth = FB_LOGO_SIZE + PREFERRED_PADDING_BETWEEN_LOGO_TITLE + titleSize.width + PREFERRED_PADDING_BETWEEN_LOGO_TITLE;
  CGFloat height = 108;
  CGSize contentSize = CGSizeMake(FB_LOGO_LEFT_MARGIN + logoAndTitleWidth + RIGHT_MARGIN,
                                  height);
  return contentSize;
}

#pragma mark - Helper Methods

- (void)_acessTokenDidChangeNotification:(NSNotification *)notification
{
  if (notification.userInfo[FBSDKAccessTokenDidChangeUserID]) {
    [self _updateContent];
  }
}

- (NSAttributedString *)_attributeTitleString:(NSString *)string
{
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  style.alignment = NSTextAlignmentCenter;
  style.lineBreakMode = NSLineBreakByClipping;
  NSMutableAttributedString *attributedString =
  [[NSMutableAttributedString alloc] initWithString:string
                                         attributes:@{
                                                      NSParagraphStyleAttributeName: style,
                                                      NSFontAttributeName: [self defaultFont],
                                                      NSForegroundColorAttributeName: [UIColor whiteColor]
                                                      }];
  // Now find all the spaces and widen their kerning.
  NSRange range = NSMakeRange(0, string.length);
  while (range.location != NSNotFound) {
    NSRange spaceRange = [string rangeOfString:@" " options:0 range:range];
    if (spaceRange.location == NSNotFound) {
      break;
    }
    [attributedString addAttribute:NSKernAttributeName
                             value:@(2.7)
                             range:spaceRange];
    range = NSMakeRange(spaceRange.location + 1, string.length - spaceRange.location - 1);
  }
  return attributedString;
}

- (void)_buttonPressed:(id)sender
{
  UIViewController *parentViewController = [FBSDKInternalUtility viewControllerforView:self];
  if ([FBSDKAccessToken currentAccessToken]) {
    NSString *title = nil;

    if (_userName) {
      NSString *localizedFormatString =
      NSLocalizedStringWithDefaultValue(@"LoginButton.LoggedInAs", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                        @"Logged in as %@",
                                        @"The format string for the FBSDKLoginButton label when the user is logged in");
      title = [NSString localizedStringWithFormat:localizedFormatString, _userName];
    } else {
      NSString *localizedLoggedIn =
      NSLocalizedStringWithDefaultValue(@"LoginButton.LoggedIn", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                        @"Logged in using Facebook",
                                        @"The fallback string for the FBSDKLoginButton label when the user name is not available yet");
      title = localizedLoggedIn;
    }
    NSString *cancelTitle =
    NSLocalizedStringWithDefaultValue(@"LoginButton.CancelLogout", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                      @"Cancel",
                                      @"The label for the FBSDKLoginButton action sheet to cancel logging out");
    NSString *logOutTitle =
    NSLocalizedStringWithDefaultValue(@"LoginButton.ConfirmLogOut", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                      @"Log Out",
                                      @"The label for the FBSDKLoginButton action sheet to confirm logging out");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:title preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:logOutTitle
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                       [FBSDKAccessToken setCurrentAccessToken:nil];
                                                       [self.delegate deviceLoginButtonDidLogOut:self];
                                                     }]];
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:NULL]];
    [parentViewController presentViewController:alertController animated:YES completion:NULL];
  } else {
    FBSDKDeviceLoginViewController *vc = [[FBSDKDeviceLoginViewController alloc] init];
    vc.delegate = self;
    vc.readPermissions = self.readPermissions;
    vc.publishPermissions = self.publishPermissions;
    [parentViewController presentViewController:vc animated:YES completion:NULL];
  }
}

- (NSAttributedString *)_loginTitle
{
  CGSize size = self.bounds.size;
  CGSize longTitleSize = [self sizeThatFits:size attributedTitle:[self _longLogInTitle]];
  NSAttributedString *title = (longTitleSize.width <= size.width ?
                               [self _longLogInTitle] :
                               [self _shortLogInTitle]);
  return title;
}

- (NSAttributedString *)_logOutTitle
{
  NSString *string = NSLocalizedStringWithDefaultValue(@"LoginButton.LogOut", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                                       @"Log out",
                                                       @"The label for the FBSDKLoginButton when the user is currently logged in");
  return [self _attributeTitleString:string];
}

- (NSAttributedString *)_longLogInTitle
{
  NSString *string = NSLocalizedStringWithDefaultValue(@"LoginButton.LogInLong", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                                       @"Log in with Facebook",
                                                       @"The long label for the FBSDKLoginButton when the user is currently logged out");
  return [self _attributeTitleString:string];
}

- (NSAttributedString *)_shortLogInTitle
{
  NSString *string = NSLocalizedStringWithDefaultValue(@"LoginButton.LogIn", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                                       @"Log in",
                                                       @"The short label for the FBSDKLoginButton when the user is currently logged out");
  return [self _attributeTitleString:string];
}

- (void)_updateContent
{
  self.selected = ([FBSDKAccessToken currentAccessToken] != nil);
  if ([FBSDKAccessToken currentAccessToken]) {
    [self setAttributedTitle:[self _logOutTitle] forState:UIControlStateFocused];
    if (![[FBSDKAccessToken currentAccessToken].userID isEqualToString:_userID]) {
      FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=id,name"
                                                                     parameters:nil
                                                                          flags:FBSDKGraphRequestFlagDisableErrorRecovery];
      [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        NSString *userID = [FBSDKTypeUtility stringValue:result[@"id"]];
        if (!error && [[FBSDKAccessToken currentAccessToken].userID isEqualToString:userID]) {
          _userName = [FBSDKTypeUtility stringValue:result[@"name"]];
          _userID = userID;
        }
      }];
    }
  } else {
    // Explicitly set title for focused (and similar line above) to work around an apparent tvOS bug
    // https://openradar.appspot.com/radar?id=5053414262177792
    [self setAttributedTitle:[self _loginTitle] forState:UIControlStateFocused];
  }
}

#pragma mark - FBSDKDeviceLoginViewControllerDelegate

- (void)deviceLoginViewControllerDidCancel:(FBSDKDeviceLoginViewController *)viewController
{
  [self.delegate deviceLoginButtonDidCancel:self];
}

- (void)deviceLoginViewControllerDidFinish:(FBSDKDeviceLoginViewController *)viewController
{
  [self.delegate deviceLoginButtonDidLogIn:self];
}

- (void)deviceLoginViewControllerDidFail:(FBSDKDeviceLoginViewController *)viewController error:(NSError *)error
{
  [self.delegate deviceLoginButtonDidFail:self error:error];
}

@end
