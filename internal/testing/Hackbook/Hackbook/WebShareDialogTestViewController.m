// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "WebShareDialogTestViewController.h"

@import FBSDKShareKit;

@implementation WebShareDialogTestViewController
{
  FBSDKShareDialogMode _mode;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];
  _mode = FBSDKShareDialogModeWeb;
}

#pragma mark - SharingDialogViewController Methods

- (NSString *)appEventsPrefix
{
  return @"Share_Web";
}

- (id<FBSDKSharingDialog>)buildDialog
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:self
                                                                      content:nil
                                                                     delegate:nil];
  dialog.mode = _mode;
  return dialog;
}

@end
