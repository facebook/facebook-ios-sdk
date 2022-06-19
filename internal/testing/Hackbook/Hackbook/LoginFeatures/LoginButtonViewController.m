// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginButtonViewController.h"

@import FBSDKLoginKit;

@interface LoginButtonViewController () <FBSDKLoginButtonDelegate>

@property (nonatomic, strong) IBOutlet FBSDKLoginButton *loginButton;
@property (nonatomic, strong) IBOutlet UISwitch *trackingLimitedSwitch;
@property (nonatomic, strong) IBOutlet UITextField *nonceTextField;

@end

@implementation LoginButtonViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.loginButton.delegate = self;
}

- (BOOL)loginButtonWillLogin:(FBSDKLoginButton *)loginButton
{
  self.loginButton.permissions = self.selectedPermissions;
  self.loginButton.loginTracking = self.trackingLimitedSwitch.isOn ? FBSDKLoginTrackingLimited : FBSDKLoginTrackingEnabled;

  NSString *nonce = self.nonceTextField.text;

  if (nonce && nonce.length > 0) {
    self.loginButton.nonce = nonce;
  }

  return YES;
}

- (void)    loginButton:(FBSDKLoginButton *)loginButton
  didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
                  error:(NSError *)error
{
  if (error) {
    ConsoleError(error, @"Login Error");
    return;
  }

  if (result && result.isCancelled) {
    ConsoleLog(@"Login Cancelled");
    return;
  }

  [self showLoginDetailsForResult:result
             requestedPermissions:self.selectedPermissions];
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
  ConsoleLog(@"Logged out");
}

@end
