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

#import "LoginManagerViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "AlertControllerUtility.h"

@implementation LoginManagerViewController

- (IBAction)customLogin:(id)sender
{
  void(^loginHandler)(FBSDKLoginManagerLoginResult *result, NSError *error) = ^(FBSDKLoginManagerLoginResult *result, NSError *error){
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
  };
  FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
  if (![FBSDKAccessToken currentAccessToken]) {
    [loginManager logInWithReadPermissions: @[@"public_profile", @"user_friends"]
                        fromViewController:self
                                   handler:loginHandler];
  } else {
    [loginManager logOut];
    UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:@"Logout"
                                                                                  message:@"Logout"];
    [self presentViewController:alertController animated:YES completion:nil];
  }
}

@end
