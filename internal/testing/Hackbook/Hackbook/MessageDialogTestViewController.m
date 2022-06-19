// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "MessageDialogTestViewController.h"

@import FBSDKShareKit;

static NSString *const kFacebookURL = @"https://www.facebook.com";

static void SetSharingContentPageID(id<FBSDKSharingContent> sharingContent)
{
  sharingContent.pageID = @"725494494218706"; // use Messenger Rocks test page since the extension url is only whitelisted for that page.
}

@interface MessageDialogTestViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *photoCounter;

@end

@implementation MessageDialogTestViewController

#pragma mark - SharingDialogViewController Methods

- (NSString *)appEventsPrefix
{
  return @"Message_Dialog";
}

- (id<FBSDKSharingDialog>)buildDialog
{
  return [[FBSDKMessageDialog alloc] initWithContent:nil delegate:nil];
}

- (NSUInteger)photosToShare
{
  return [self.photoCounter selectedSegmentIndex] + 1;
}

#pragma mark - Link share

- (IBAction)shareLinkWithAttribution:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetSharingContentPageID(linkContent);
    return linkContent;
  }];
}

@end
