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

#import "LoginButtonViewController.h"

#import "AlertControllerUtility.h"

@interface LoginButtonViewController () <FBSDKLoginButtonDelegate>

@end

@implementation LoginButtonViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
  loginButton.center = self.view.center;
  loginButton.delegate = self;
  loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
  [self.view addSubview:loginButton];
}

#pragma mark - FBSDKLoginButtonDelegate

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
  UIAlertController *alertController;
  if (error) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Login Fail"
                                                               message:[NSString stringWithFormat:@"Login fail with error: %@", error]];
  } else if (!result || result.isCancelled) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Login Cancelled"
                                                               message:@"User cancelled login"];
  } else {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Login Success"
                                                               message:[NSString stringWithFormat:@"Login success with granted permission: %@", [[result.grantedPermissions allObjects] componentsJoinedByString:@" "]] ];
  }
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
  UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:@"Log out" message:@"Log out success"];
  [self presentViewController:alertController animated:YES completion:nil];
}

@end
