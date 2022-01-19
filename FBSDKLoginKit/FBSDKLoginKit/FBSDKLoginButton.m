/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginButton.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKLoginAppEventName.h"
#import "FBSDKLoginButtonDelegate.h"
#import "FBSDKLoginManager+Internal.h"
#import "FBSDKLoginTooltipView.h"
#import "FBSDKNonceUtility.h"

static const CGFloat kFBLogoSize = 16.0;
static const CGFloat kFBLogoLeftMargin = 6.0;
static const CGFloat kButtonHeight = 28.0;
static const CGFloat kRightMargin = 8.0;
static const CGFloat kPaddingBetweenLogoTitle = 8.0;

@interface FBSDKLoginButton ()

@property (nonatomic) BOOL hasShownTooltipBubble;
@property (nonatomic) id<FBSDKLoginProviding> loginProvider;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *userName;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

@end

@implementation FBSDKLoginButton

#pragma mark - Properties

- (FBSDKDefaultAudience)defaultAudience
{
  return _loginProvider.defaultAudience;
}

- (void)setDefaultAudience:(FBSDKDefaultAudience)defaultAudience
{
  _loginProvider.defaultAudience = defaultAudience;
}

- (void)setLoginTracking:(FBSDKLoginTracking)loginTracking
{
  _loginTracking = loginTracking;
  [self _updateNotificationObservers];
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

  CGSize selectedSize = [self textSizeForText:[self _logOutTitle] font:font constrainedSize:size lineBreakMode:self.titleLabel.lineBreakMode];
  CGSize normalSize = [self textSizeForText:[self _longLogInTitle] font:font constrainedSize:size lineBreakMode:self.titleLabel.lineBreakMode];

  if (normalSize.width > size.width) {
    normalSize = [self textSizeForText:[self _shortLogInTitle] font:font constrainedSize:size lineBreakMode:self.titleLabel.lineBreakMode];
  }

  CGFloat titleWidth = MAX(normalSize.width, selectedSize.width);
  CGFloat buttonWidth = kFBLogoLeftMargin + kFBLogoSize + kPaddingBetweenLogoTitle + titleWidth + kRightMargin;
  return CGSizeMake(buttonWidth, kButtonHeight);
}

#pragma mark - FBSDKButton

- (void)configureButton
{
  _loginProvider = [FBSDKLoginManager new];

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

  self.authType = FBSDKLoginAuthTypeRerequest;
  self.codeVerifier = [FBSDKCodeVerifier new];
}

- (void)_updateNotificationObservers
{
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(_profileDidChangeNotification:)
                                             name:FBSDKProfileDidChangeNotification
                                           object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
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
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Logged in as %@",
        @"The format string for the FBSDKLoginButton label when the user is logged in"
      );
      title = [NSString localizedStringWithFormat:localizedFormatString, _userName];
    } else {
      NSString *localizedLoggedIn =
      NSLocalizedStringWithDefaultValue(
        @"LoginButton.LoggedIn",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Logged in using Facebook",
        @"The fallback string for the FBSDKLoginButton label when the user name is not available yet"
      );
      title = localizedLoggedIn;
    }
    NSString *cancelTitle =
    NSLocalizedStringWithDefaultValue(
      @"LoginButton.CancelLogout",
      @"FacebookSDK",
      [FBSDKInternalUtility.sharedUtility bundleForStrings],
      @"Cancel",
      @"The label for the FBSDKLoginButton action sheet to cancel logging out"
    );
    NSString *logOutTitle =
    NSLocalizedStringWithDefaultValue(
      @"LoginButton.ConfirmLogOut",
      @"FacebookSDK",
      [FBSDKInternalUtility.sharedUtility bundleForStrings],
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
                                                     [self _logout];
                                                   }];
    [alertController addAction:cancel];
    [alertController addAction:logout];
    UIViewController *topMostViewController = [FBSDKInternalUtility.sharedUtility topMostViewController];
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

    [_loginProvider logInFromViewController:[FBSDKInternalUtility.sharedUtility viewControllerForView:self]
                              configuration:loginConfig
                                 completion:handler];
  }
}

- (FBSDKLoginConfiguration *)loginConfiguration
{
  NSString *nonce = self.nonce ?: NSUUID.UUID.UUIDString;
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.permissions
                                                     tracking:self.loginTracking
                                                        nonce:nonce
                                              messengerPageId:self.messengerPageId
                                                     authType:self.authType
                                                 codeVerifier:self.codeVerifier];
}

- (NSString *)_logOutTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogOut",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Log out",
    @"The label for the FBSDKLoginButton when the user is currently logged in"
  );
}

- (NSString *)_longLogInTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogInContinue",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Continue with Facebook",
    @"The long label for the FBSDKLoginButton when the user is currently logged out"
  );
}

- (NSString *)_shortLogInTitle
{
  return NSLocalizedStringWithDefaultValue(
    @"LoginButton.LogIn",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
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
  id<FBSDKGraphRequest> request = [[self graphRequestFactory] createGraphRequestWithGraphPath:@"me"
                                                                                   parameters:@{@"fields" : @"id,name"}
                                                                                        flags:FBSDKGraphRequestFlagDisableErrorRecovery];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    NSString *userID = [FBSDKTypeUtility dictionary:result objectForKey:@"id" ofType:NSString.class];
    if (!error && [FBSDKAccessToken.currentAccessToken.userID isEqualToString:userID]) {
      self->_userName = [FBSDKTypeUtility dictionary:result objectForKey:@"name" ofType:NSString.class];
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

- (void)_logout
{
  [self->_loginProvider logOut];
  [self.delegate loginButtonDidLogOut:self];
}

- (id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  if (!_graphRequestFactory) {
    _graphRequestFactory = [FBSDKGraphRequestFactory new];
  }
  return _graphRequestFactory;
}

@end

#endif
