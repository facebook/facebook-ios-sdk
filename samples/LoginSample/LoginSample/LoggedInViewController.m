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

#import "LoggedInViewController.h"

#import <AccountKit/AccountKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface LoggedInViewController ()

@end

@implementation LoggedInViewController
{
  AKFAccountKit *_accountKit;
  FBSDKLoginManager *_loginManager;
}

- (instancetype)initWithAccountKit:(AKFAccountKit *)accountKit
{
  if (self = [super init]) {
    _accountKit = accountKit;
    _loginManager = [FBSDKLoginManager new];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Home";
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Deauthorize" style:UIBarButtonItemStylePlain target:self action:@selector(deauthorize)];

  self.view.backgroundColor = [UIColor whiteColor];

  UILabel *label = [UILabel new];
  label.font = [UIFont systemFontOfSize:20];
  label.numberOfLines = 2;
  label.textAlignment = NSTextAlignmentCenter;
  label.text = @"You are logged in.\nCongrats!";
  [label sizeToFit];
  label.center = self.view.center;
  [self.view addSubview:label];
}

- (void)logout
{
  [_accountKit logOut];
  [_loginManager logOut];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)deauthorize
{
  if ([FBSDKAccessToken currentAccessToken] != nil) {
    FBSDKGraphRequestHandler completionHandler = ^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      if (error == nil) {
        [FBSDKAccessToken setCurrentAccessToken:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
      }
    };
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/permissions"
                                       parameters:nil
                                      tokenString:[FBSDKAccessToken currentAccessToken].tokenString
                                          version:nil
                                       HTTPMethod:@"DELETE"] startWithCompletionHandler:completionHandler];
  } else {
    [_accountKit logOut];
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}


@end
