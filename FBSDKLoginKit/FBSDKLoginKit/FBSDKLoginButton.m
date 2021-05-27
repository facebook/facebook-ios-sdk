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

#if !TARGET_OS_TV

 #import "FBSDKLoginButton.h"

 #ifdef FBSDKCOCOAPODS
  #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
 #else
  #import "FBSDKCoreKit+Internal.h"
 #endif

 #import "FBSDKCoreKitBasicsImportForLoginKit.h"
 #import "FBSDKLoginTooltipView.h"
 #import "FBSDKNonceUtility.h"

static const CGFloat kFBLogoSize = 16.0;
static const CGFloat kFBLogoLeftMargin = 6.0;
static const CGFloat kButtonHeight = 28.0;
static const CGFloat kRightMargin = 8.0;
static const CGFloat kPaddingBetweenLogoTitle = 8.0;

FBSDKAppEventName const FBSDKAppEventNameFBSDKLoginButtonDidTap = @"fb_login_button_did_tap";

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
  [self _unsubscribeFromNotifications];
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

- (void)setLoginTracking:(FBSDKLoginTracking)loginTracking
{
  _loginTracking = loginTracking;
  [self _updateNotificationObservers];
}

- (UIFont *)defaultFont
{
  CGFloat size = 15;

  if (@available(iOS 8.2, *)) {
    return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
  } else {
    return [UIFont boldSystemFontOfSize:size];
  }
}

- (void)setNonce:(NSString *)nonce
{
  if ([FBSDKNonceUtility isValidNonce:nonce]) {
    _nonce = [nonce copy];
  } else {
    _nonce = nil;
    NSString *msg = [NSString stringWithFormat:@"Unable to set invalid nonce: %@ on FBSDKLoginButton", nonce];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:msg];
  }
}

 #pragma mark - UIView

- (void)didMoveToWindow
{
  [super didMoveToWindow];

  if (self.window
      && ((self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorForceDisplay) || !_hasShownTooltipBubble)) {
    [self performSelector:@selector(_showTooltipIfNeeded) withObject:nil afterDelay:0];
    _hasShownTooltipBubble = YES;
  }
}

 #pragma mark - Layout

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
  CGFloat centerY = CGRectGetMidY(contentRect);
  CGFloat y = centerY - (kFBLogoSize / 2.0);
  return CGRectMake(kFBLogoLeftMargin, y, kFBLogoSize, kFBLogoSize);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
  if (self.hidden || CGRectIsEmpty(self.bounds)) {
    return CGRectZero;
  }
  CGRect imageRect = [self imageRectForContentRect:contentRect];
  CGFloat titleX = CGRectGetMaxX(imageRect) + kPaddingBetweenLogoTitle;
  CGRect titleRect = CGRectMake(titleX, 0, CGRectGetWidth(contentRect) - titleX - kRightMargin, CGRectGetHeight(contentRect));

  return titleRect;
}

- (void)layoutSubviews
{
  CGSize size = self.bounds.size;
  CGSize longTitleSize = [self sizeThatFits:size title:[self _longLogInTitle]];
  NSString *title = (longTitleSize.width <= size.width
    ? [self _longLogInTitle]
    : [self _shortLogInTitle]);
  if (![title isEqualToString:[self titleForState:UIControlStateNormal]]) {
    [self setTitle:title forState:UIControlStateNormal];
  }

  [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  if (self.hidden) {
    return CGSizeZero;
  }
  UIFont *font = self.titleLabel.font;

  CGSize selectedSize = FBSDKTextSize([self _logOutTitle], font, size, self.titleLabel.lineBreakMode);
  CGSize normalSize = FBSDKTextSize([self _longLogInTitle], font, size, self.titleLabel.lineBreakMode);
  if (normalSize.width > size.width) {
    normalSize = FBSDKTextSize([self _shortLogInTitle], font, size, self.titleLabel.lineBreakMode);
  }

  CGFloat titleWidth = MAX(normalSize.width, selectedSize.width);
  CGFloat buttonWidth = kFBLogoLeftMargin + kFBLogoSize + kPaddingBetweenLogoTitle + titleWidth + kRightMargin;
  return CGSizeMake(buttonWidth, kButtonHeight);
}

 #pragma mark - FBSDKButton

- (void)configureButton
{
  _loginManager = [FBSDKLoginManager new];

  NSString *logInTitle = [self _shortLogInTitle];
  NSString *logOutTitle = [self _logOutTitle];

  [self configureWithIcon:nil
                      title:logInTitle
            backgroundColor:self.backgroundColor
           highlightedColor:nil
              selectedTitle:logOutTitle
               selectedIcon:nil
              selectedColor:self.backgroundColor
   selectedHighlightedColor:nil];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1
                                                    constant:kButtonHeight]];
  [self _initializeContent];

  [self addTarget:self action:@selector(_buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

  [self _updateNotificationObservers];
}

 #pragma mark - Helper Methods

- (void)_unsubscribeFromNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updateNotificationObservers
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_profileDidChangeNotification:)
                                               name:FBSDKProfileDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_accessTokenDidChangeNotification:)
                                               name:FBSDKAccessTokenDidChangeNotification
                                             object:nil];
}

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification
{
  if (notification.userInfo[FBSDKAccessTokenDidChangeUserIDKey] || notification.userInfo[FBSDKAccessTokenDidExpireKey]) {
    [self _updateContentForAccessToken];
  }
}

- (void)_profileDidChangeNotification:(NSNotification *)notification
{
  [self _updateContentForUserProfile:FBSDKProfile.currentProfile];
}

- (void)_buttonPressed:(id)sender
{
  if (self._isAuthenticated) {
    if (self.loginTracking != FBSDKLoginTrackingLimited) {
      [self logTapEventWithEventName:FBSDKAppEventNameFBSDKLoginButtonDidTap parameters:nil];
    }

    NSString *title = nil;

    if (_userName) {
      NSString *localizedFormatString =
      NSLocalizedStringWithDefaultValue(
        @"LoginButton.LoggedInAs",
        @"FacebookSDK",
        [FBSDKInternalUtility bundleForStrings],
        @"Logged in as %@",
        @"The format string for the FBSDKLoginButton label when the user is logged in"
      );
      title = [NSString localizedStringWithFormat:localizedFormatString, _userName];
    } else {
      NSString *localizedLoggedIn =
      NSLocalizedStringWithDefaultValue(
        @"LoginButton.LoggedIn",
        @"FacebookSDK",
        [FBSDKInternalUtility bundleForStrings],
        @"Logged in using Facebook",
        @"The fallback string for the FBSDKLoginButton label when the user name is not available yet"
      );
      title = localizedLoggedIn;
    }
    NSString *cancelTitle =
    NSLocalizedStringWithDefaultValue(
      @"LoginButton.CancelLogout",
      @"FacebookSDK",
      [FBSDKInternalUtility bundleForStrings],
      @"Cancel",
      @"The label for the FBSDKLoginButton action sheet to cancel logging out"
    );
    NSString *logOutTitle =
    NSLocalizedStringWithDefaultValue(
      @"LoginButton.ConfirmLogOut",
      @"FacebookSDK",
      [FBSDKInternalUtility bundleForStrings],
      @"Log Out",
      @"The label for the FBSDKLoginButton action sheet to confirm logging out"
    );
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
                                                   handler:^(UIAlertAction *_Nonnull action) {
                                                     [self->_loginManager logOut];
                                                     [self.delegate loginButtonDidLogOut:self];
                                                   }];
    [alertController addAction:cancel];
    [alertController addAction:logout];
    UIViewController *topMostViewController = [FBSDKInternalUtility topMostViewController];
    [topMostViewController presentViewController:alertController
                                        animated:YES
                                      completion:nil];
  } else {
    if ([self.delegate respondsToSelector:@selector(loginButtonWillLogin:)]) {
      if (![self.delegate loginButtonWillLogin:self]) {
        return;
      }
    }

    FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
      if ([self.delegate respondsToSelector:@selector(loginButton:didCompleteWithResult:error:)]) {
        [self.delegate loginButton:self didCompleteWithResult:result error:error];
      }
    };

    FBSDKLoginConfiguration *loginConfig = [self loginConfiguration];

    if (self.loginTracking == FBSDKLoginTrackingEnabled) {
      [self logTapEventWithEventName:FBSDKAppEventNameFBSDKLoginButtonDidTap parameters:nil];
    }

    [_loginManager logInFromViewController:[FBSDKInternalUtility viewControllerForView:self]
                             configuration:loginConfig
                                completion:handler];
  }
}

- (FBSDKLoginConfiguration *)loginConfiguration
{
  if (self.nonce) {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.permissions
                                                       tracking:self.loginTracking
                                                          nonce:self.nonce
                                                messengerPageId:self.messengerPageId
                                                       authType:self.authType];
  } else {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.permissions
                                                       tracking:self.loginTracking
                                                messengerPageId:self.messengerPageId
                                                       authType:self.authType];
  }
}

- (NSString *)_logOutTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogOut",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Log out",
    @"The label for the FBSDKLoginButton when the user is currently logged in"
  );
}

- (NSString *)_longLogInTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogInContinue",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Continue with Facebook",
    @"The long label for the FBSDKLoginButton when the user is currently logged out"
  );
}

- (NSString *)_shortLogInTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogIn",
    @"FacebookSDK",
    [FBSDKInternalUtility bundleForStrings],
    @"Log in",
    @"The short label for the FBSDKLoginButton when the user is currently logged out"
  );
}

- (void)_showTooltipIfNeeded
{
  if (self._isAuthenticated || self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorDisable) {
    return;
  } else {
    FBSDKLoginTooltipView *tooltipView = [FBSDKLoginTooltipView new];
    tooltipView.colorStyle = self.tooltipColorStyle;
    if (self.tooltipBehavior == FBSDKLoginButtonTooltipBehaviorForceDisplay) {
      tooltipView.forceDisplay = YES;
    }
    [tooltipView presentFromView:self];
  }
}

// On initial setting of button state. We want to update the button's user
// information using the most comprehensive available.
// If access token is available use that.
// If only profile is available, use that.
- (void)_initializeContent
{
  FBSDKAccessToken *accessToken = FBSDKAccessToken.currentAccessToken;
  FBSDKProfile *profile = FBSDKProfile.currentProfile;

  if (accessToken) {
    [self _updateContentForAccessToken];
  } else if (profile) {
    [self _updateContentForUserProfile:profile];
  } else {
    self.selected = NO;
  }
}

- (void)_updateContentForAccessToken
{
  BOOL accessTokenIsValid = FBSDKAccessToken.isCurrentAccessTokenActive;
  self.selected = accessTokenIsValid;
  if (accessTokenIsValid) {
    if (![FBSDKAccessToken.currentAccessToken.userID isEqualToString:_userID]) {
      [self _fetchAndSetContent];
    }
  }
}

- (void)_fetchAndSetContent
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=id,name"
                                                                 parameters:nil
                                                                      flags:FBSDKGraphRequestFlagDisableErrorRecovery];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    NSString *userID = [FBSDKTypeUtility coercedToStringValue:result[@"id"]];
    if (!error && [FBSDKAccessToken.currentAccessToken.userID isEqualToString:userID]) {
      self->_userName = [FBSDKTypeUtility coercedToStringValue:result[@"name"]];
      self->_userID = userID;
    }
  }];
}

- (void)_updateContentForUserProfile:(nullable FBSDKProfile *)profile
{
  self.selected = profile != nil;

  if (profile && [self _userInformationDoesNotMatchProfile:profile]) {
    _userName = profile.name;
    _userID = profile.userID;
  }
}

- (BOOL)_userInformationDoesNotMatchProfile:(FBSDKProfile *)profile
{
  return (profile.userID != _userID) || (profile.name != _userName);
}

- (BOOL)_isAuthenticated
{
  return (FBSDKAccessToken.currentAccessToken || FBSDKAuthenticationToken.currentAuthenticationToken);
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.authType = FBSDKLoginAuthTypeRerequest;
  }

  return self;
}

// MARK: - Testability

 #if DEBUG
  #if FBSDKTEST

- (NSString *)userName
{
  return _userName;
}

- (NSString *)userID
{
  return _userID;
}

  #endif
 #endif

@end

#endif
