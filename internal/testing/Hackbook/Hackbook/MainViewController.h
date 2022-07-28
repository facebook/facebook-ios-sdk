// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKLoginKit;

@interface MainViewController : UITableViewController
{
  UIBarButtonItem *versionButton;
  FBSDKLoginButton *loginButton;
  UILabel *deepLinkURLLabel;
}

- (IBAction)selectVersion:(id)sender;
- (void)updateDeepLinkLabel:(NSURL *)url;

@end
