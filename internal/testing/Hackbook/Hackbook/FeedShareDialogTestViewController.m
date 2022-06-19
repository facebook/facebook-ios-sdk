// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FeedShareDialogTestViewController.h"

@import FBSDKShareKit;

@implementation FeedShareDialogTestViewController
{
  FBSDKShareDialogMode _mode;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];
  _mode = FBSDKShareDialogModeFeedWeb;
}

#pragma mark - SharingDialogViewController Methods

- (NSString *)appEventsPrefix
{
  return @"Share_Feed";
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
