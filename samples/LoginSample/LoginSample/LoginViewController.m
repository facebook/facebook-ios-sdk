// Copyright 2004-present Facebook. All Rights Reserved.
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

#import "LoginViewController.h"

#import <AccountKit/AccountKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "FBTweak/FBTweakInline.h"
#import "FBTweak/FBTweakStore.h"
#import "FBTweak/FBTweakViewController.h"

#import "LoggedInViewController.h"
#import "SettingsUtil.h"
#import "Theme.h"

@interface LoginViewController () <FBSDKLoginButtonDelegate, AKFViewControllerDelegate, FBTweakViewControllerDelegate>

@end

@implementation LoginViewController
{
  AKFResponseType _responseType;
  AKFAccountKit *_accountKit;
  FBSDKLoginManager *_fbLoginManager;
  UIViewController<AKFViewController> *_pendingLoginViewController;
  // Views
  FBSDKLoginButton *_fbButton;
  UIButton *_phoneButton;
  UIButton *_emailButton;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self configureSettings];

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];

  // initialize Account Kit
  if (_accountKit == nil) {
    _responseType = [SettingsUtil responseType];
    _accountKit = [[AKFAccountKit alloc] initWithResponseType:_responseType];
  }
  _pendingLoginViewController = [_accountKit viewControllerForLoginResume];

  [self prepareViews];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if ([self isUserLoggedIn]) {
    // if the user is already logged in, go to the main screen
    [self proceedToMainScreen:NO];
  } else if (_pendingLoginViewController != nil) {
    // resume pending login (if any)
    [self prepareAKLoginViewController:_pendingLoginViewController];
    [self presentViewController:_pendingLoginViewController
                       animated:animated
                     completion:NULL];
    _pendingLoginViewController = nil;
  }
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];

  float space = 30;
  float y = self.topLayoutGuide.length + space;
  _fbButton.center = CGPointMake(self.view.center.x, y + _fbButton.bounds.size.height/2);
  y = CGRectGetMaxY(_fbButton.frame) + space;
  _phoneButton.center = CGPointMake(self.view.center.x, y + _phoneButton.bounds.size.height/2);
  y = CGRectGetMaxY(_phoneButton.frame) + space;
  _emailButton.center = CGPointMake(self.view.center.x, y + _emailButton.bounds.size.height/2);
  y = CGRectGetMaxY(_emailButton.frame) + space;
}

- (BOOL)isUserLoggedIn
{
  return [FBSDKAccessToken currentAccessToken] != nil || [_accountKit currentAccessToken] != nil;
}

- (void)loginWithEmail
{
  UIViewController<AKFViewController> *vc = [_accountKit viewControllerForEmailLogin];
  [self prepareAKLoginViewController:vc];
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)loginWithPhone
{
  UIViewController<AKFViewController> *vc = [_accountKit viewControllerForPhoneLogin];
  [self prepareAKLoginViewController:vc];
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)openSettings
{
  FBTweakViewController *vc = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance] category:@"Settings"];
  vc.tweaksDelegate = self;
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)configureSettings
{
  _fbButton.publishPermissions = [SettingsUtil publishPermissions];
  _fbButton.readPermissions = [SettingsUtil readPermissions];
  AKFResponseType responseType = [SettingsUtil responseType];
  if (_responseType != responseType) {
    _responseType = responseType;
    _accountKit = [[AKFAccountKit alloc] initWithResponseType:_responseType];
  }
}

- (void)proceedToMainScreen:(BOOL)animated
{
  LoggedInViewController *loggedInVC = [[LoggedInViewController alloc] initWithAccountKit:_accountKit];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:loggedInVC];
  [self presentViewController:navVC animated:animated completion:nil];
}

- (void)prepareViews
{
  self.title = @"Login";
  self.view.backgroundColor = [UIColor whiteColor];

  _fbButton = [FBSDKLoginButton new];
  _fbButton.bounds = CGRectMake(0, 0, 200, 50);
  _fbButton.delegate = self;
  [self.view addSubview:_fbButton];

  _phoneButton = [self createButtonWithTitle:@"Log in with Phone" color:[UIColor colorWithRed: 77.0/255.0 green:194.0/255.0 blue:71.0/255.0 alpha:1]];
  [_phoneButton addTarget:self action:@selector(loginWithPhone) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_phoneButton];

  _emailButton = [self createButtonWithTitle:@"Log in with Email" color:[UIColor colorWithRed: 221.0/255.0 green:75.0/255.0 blue:57.0/255.0 alpha:1]];
  [_emailButton addTarget:self action:@selector(loginWithEmail) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_emailButton];
}

- (UIButton *)createButtonWithTitle:(NSString *)title color:(UIColor *)color
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.backgroundColor = color;
  button.bounds = CGRectMake(0, 0, 200, 50);
  button.titleLabel.font = [UIFont systemFontOfSize:14];
  [button setTitle:title forState:UIControlStateNormal];
  return button;
}

- (void)prepareAKLoginViewController:(UIViewController<AKFViewController> *)loginViewController
{
  loginViewController.delegate = self;
  loginViewController.theme = [SettingsUtil currentTheme];
  [SettingsUtil setAdvancedUIManagerForController:loginViewController];
}

#pragma mark - FBLoginButtonDelegate

- (void)  loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
                error:(NSError *)error
{
  if (error == nil && !result.isCancelled) {
    [self proceedToMainScreen:YES];
  }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
}

#pragma mark - AKFViewControllerDelegate

- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAccessToken:(id<AKFAccessToken>)accessToken state:(NSString *)state
{
  [self proceedToMainScreen:YES];
}

#pragma mark - FBTweakViewControllerDelegate
- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController
{
  [self configureSettings];
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
