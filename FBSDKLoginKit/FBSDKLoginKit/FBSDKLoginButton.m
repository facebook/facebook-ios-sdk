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

#import "FBSDKLoginButton.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKLoginTooltipView.h"

@interface FBSDKLoginButton() <FBSDKButtonImpressionTracking, UIActionSheetDelegate>
@end

@implementation FBSDKLoginButton
{
  BOOL _hasShownTooltipBubble;
  FBSDKLoginManager *_loginManager;
  NSString *_userID;
  NSString *_userName;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (FBSDKDefaultAudience)defaultAudience
{
  return _loginManager.defaultAudience;
}

- (void)setDefaultAudience:(FBSDKDefaultAudience)defaultAudience
{
  _loginManager.defaultAudience = defaultAudience;
}

- (FBSDKLoginBehavior)loginBehavior
{
  return _loginManager.loginBehavior;
}

- (void)setLoginBehavior:(FBSDKLoginBehavior)loginBehavior
{
  _loginManager.loginBehavior = loginBehavior;
}

#pragma mark - UIView

- (void)didMoveToWindow
{
  [super didMoveToWindow];

  if (self.window &&
      ((self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorForceDisplay) || !_hasShownTooltipBubble)) {
    [self performSelector:@selector(_showTooltipIfNeeded) withObject:nil afterDelay:0];
    _hasShownTooltipBubble = YES;
  }
}

#pragma mark - Layout

- (void)layoutSubviews
{
  CGSize size = self.bounds.size;
  CGSize longTitleSize = [self sizeThatFits:size title:[self _longLogInTitle]];
  NSString *title = (longTitleSize.width <= size.width ?
                     [self _longLogInTitle] :
                     [self _shortLogInTitle]);
  if (![title isEqualToString:[self titleForState:UIControlStateNormal]]) {
    [self setTitle:title forState:UIControlStateNormal];
  }

  [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  if ([self isHidden]) {
    return CGSizeZero;
  }
  CGSize selectedSize = [self sizeThatFits:size title:[self _logOutTitle]];
  CGSize normalSize = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, size.height) title:[self _longLogInTitle]];
  if (normalSize.width > size.width) {
    return normalSize = [self sizeThatFits:size title:[self _shortLogInTitle]];
  }
  return CGSizeMake(MAX(normalSize.width, selectedSize.width), MAX(normalSize.height, selectedSize.height));
}

#pragma mark - UIActionSheetDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0) {
    [_loginManager logOut];
    [self.delegate loginButtonDidLogOut:self];
  }
}
#pragma clang diagnostic pop

#pragma mark - FBSDKButtonImpressionTracking

- (NSDictionary *)analyticsParameters
{
  return nil;
}

- (NSString *)impressionTrackingEventName
{
  return FBSDKAppEventNameFBSDKLoginButtonImpression;
}

- (NSString *)impressionTrackingIdentifier
{
  return @"login";
}

#pragma mark - FBSDKButton

- (void)configureButton
{
  _loginManager = [[FBSDKLoginManager alloc] init];

  NSString *logInTitle = [self _shortLogInTitle];
  NSString *logOutTitle = [self _logOutTitle];

  [self configureWithIcon:nil
                    title:logInTitle
          backgroundColor:[super defaultBackgroundColor]
         highlightedColor:nil
            selectedTitle:logOutTitle
             selectedIcon:nil
            selectedColor:[super defaultBackgroundColor]
 selectedHighlightedColor:nil];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;

  [self _updateContent];

  [self addTarget:self action:@selector(_buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_accessTokenDidChangeNotification:)
                                               name:FBSDKAccessTokenDidChangeNotification
                                             object:nil];
}

#pragma mark - Helper Methods

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification
{
  if (notification.userInfo[FBSDKAccessTokenDidChangeUserID]) {
    [self _updateContent];
  }
}

- (void)_buttonPressed:(id)sender
{
  [self logTapEventWithEventName:FBSDKAppEventNameFBSDKLoginButtonDidTap parameters:[self analyticsParameters]];
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
    if ([UIAlertController class]) {
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
      alertController.popoverPresentationController.sourceView = self;
      alertController.popoverPresentationController.sourceRect = self.bounds;
      UIAlertAction *cancel = [UIAlertAction actionWithTitle:cancelTitle
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
      UIAlertAction *logout = [UIAlertAction actionWithTitle:logOutTitle
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                       [_loginManager logOut];
                                                       [self.delegate loginButtonDidLogOut:self];
                                                     }];
      [alertController addAction:cancel];
      [alertController addAction:logout];
      UIViewController *topMostViewController = [FBSDKInternalUtility topMostViewController];
      [topMostViewController presentViewController:alertController
                                          animated:YES
                                        completion:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:title
                                                         delegate:self
                                                cancelButtonTitle:cancelTitle
                                           destructiveButtonTitle:logOutTitle
                                                otherButtonTitles:nil];
      [sheet showInView:self];
#pragma clang diagnostic pop
    }
  } else {
    if ([self.delegate respondsToSelector:@selector(loginButtonWillLogin:)]) {
      if (![self.delegate loginButtonWillLogin:self]) {
        return;
      }
    }

    FBSDKLoginManagerRequestTokenHandler handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
      if ([self.delegate respondsToSelector:@selector(loginButton:didCompleteWithResult:error:)]) {
        [self.delegate loginButton:self didCompleteWithResult:result error:error];
      }
    };

    if (self.publishPermissions.count > 0) {
      [_loginManager logInWithPublishPermissions:self.publishPermissions
                              fromViewController:[FBSDKInternalUtility viewControllerForView:self]
                                         handler:handler];
    } else {
      [_loginManager logInWithReadPermissions:self.readPermissions
                           fromViewController:[FBSDKInternalUtility viewControllerForView:self]
                                      handler:handler];
    }
  }
}

- (NSString *)_logOutTitle
{
  return NSLocalizedStringWithDefaultValue(@"LoginButton.LogOut", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                           @"Log out",
                                           @"The label for the FBSDKLoginButton when the user is currently logged in");
  ;
}

- (NSString *)_longLogInTitle
{
  return NSLocalizedStringWithDefaultValue(@"LoginButton.LogInLong", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                           @"Log in with Facebook",
                                           @"The long label for the FBSDKLoginButton when the user is currently logged out");
}

- (NSString *)_shortLogInTitle
{
  return NSLocalizedStringWithDefaultValue(@"LoginButton.LogIn", @"FacebookSDK", [FBSDKInternalUtility bundleForStrings],
                                           @"Log in",
                                           @"The short label for the FBSDKLoginButton when the user is currently logged out");
}

- (void)_showTooltipIfNeeded
{
  if ([FBSDKAccessToken currentAccessToken] || self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorDisable) {
    return;
  } else {
    FBSDKLoginTooltipView *tooltipView = [[FBSDKLoginTooltipView alloc] init];
    tooltipView.colorStyle = self.tooltipColorStyle;
    if (self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorForceDisplay) {
      tooltipView.forceDisplay = YES;
    }
    [tooltipView presentFromView:self];
  }
}

- (void)_updateContent
{
  self.selected = ([FBSDKAccessToken currentAccessToken] != nil);
  if ([FBSDKAccessToken currentAccessToken]) {
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
  }
}

@end
