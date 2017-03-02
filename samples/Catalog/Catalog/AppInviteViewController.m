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

#import "AppInviteViewController.h"

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "AlertControllerUtility.h"

@interface AppInviteViewController() <FBSDKAppInviteDialogDelegate>

@end

@implementation AppInviteViewController

#pragma mark - Default Image

- (IBAction)appInvitesWithDefaultImage:(id)sender
{
  FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
  // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
  content.appLinkURL = [NSURL URLWithString:@"https://fb.me/1539184863038815"];
  [FBSDKAppInviteDialog showFromViewController:self withContent:content delegate:self];
}

#pragma mark - Custom Image

- (IBAction)appInvitesWithCustomImage:(id)sender
{
  FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
  // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
  content.appLinkURL = [NSURL URLWithString:@"https://fb.me/1539184863038815"];
  content.appInvitePreviewImageURL = [NSURL URLWithString:@"https://d3uu10x6fsg06w.cloudfront.net/catalogapp/FacebookDeveloper.png"];
  [FBSDKAppInviteDialog showFromViewController:self withContent:content delegate:self];
}

#pragma mark - FBSDKAppInviteDialogDelegate

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
  UIAlertController *alertController;
  if (!results || [results[@"completionGesture"] isEqualToString:@"cancel"]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"App Invite" message:@"App invites cancelled."];
  } else {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"App Invite" message:@"App invites sent."];
  }
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
  UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:@"App Invite"
                                                                                message:[NSString stringWithFormat:@"App invites fail with error: %@", error]];
  [self presentViewController:alertController animated:YES completion:nil];
}

@end
