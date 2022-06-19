// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginManagerViewController.h"

@import FBSDKLoginKit;

@interface LoginManagerViewController ()

@property (nonatomic, strong) IBOutlet UIButton *stateAgnosticLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UISwitch *trackingLimitedSwitch;
@property (nonatomic, strong) IBOutlet UITextField *nonceTextField;

@end

@implementation LoginManagerViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [self updateLoginButton];
}

- (FBSDKLoginTracking)tracking
{
  return self.trackingLimitedSwitch.isOn ? FBSDKLoginTrackingLimited : FBSDKLoginTrackingEnabled;
}

- (NSString *)nonce
{
  return self.nonceTextField.text;
}

- (FBSDKLoginConfiguration *)configuration
{
  if (self.nonce && self.nonce.length > 0) {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.selectedPermissions
                                                       tracking:self.tracking
                                                          nonce:self.nonce];
  } else {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.selectedPermissions
                                                       tracking:self.tracking];
  }
}

- (IBAction)toggleLoginState:(id)sender
{
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];

  if ([self isLoggedIn]) {
    [loginManager logOut];
    [self updateLoginButton];
    return;
  }

  [loginManager logInFromViewController:self configuration:self.configuration completion:^(FBSDKLoginManagerLoginResult *_Nullable result, NSError *_Nullable error) {
    if (result && result.isCancelled) {
      return ConsoleLog(@"Login Cancelled");
    }
    if (error) {
      return ConsoleError(error, @"Login Error");
    }
    [self updateLoginButton];
    [self showLoginDetailsForResult:result
               requestedPermissions:self.selectedPermissions];
  }];
}

- (IBAction)stateAgnosticLogin
{
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];

  [loginManager logInFromViewController:self configuration:self.configuration completion:^(FBSDKLoginManagerLoginResult *_Nullable result, NSError *_Nullable error) {
    if (result && result.isCancelled) {
      return ConsoleLog(@"Login Cancelled");
    }
    if (error) {
      return ConsoleError(error, @"Login Error");
    }
    [self showLoginDetailsForResult:result
               requestedPermissions:self.selectedPermissions];
  }];
}

- (void)updateLoginButton
{
  NSString *title = self.isLoggedIn ? @"Log Out" : @"Log In With Facebook";
  [self.loginButton setTitle:title forState:UIControlStateNormal];
}

@end
