// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginTableViewController.h"

#import "LoginViewController.h"

@interface LoginTableViewController ()

@end

@implementation LoginTableViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  LoginViewController *controller = segue.destinationViewController;
  if (controller) {
    controller.selectedPermissions = _selectedPermissions;
  }
}

@end
