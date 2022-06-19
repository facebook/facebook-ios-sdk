// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKLoginKit;

@interface MainViewController : UITableViewController
{
  UIBarButtonItem *versionButton;
  FBSDKLoginButton *loginButton;
}

- (IBAction)selectVersion:(id)sender;

@end
