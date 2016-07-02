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

#import "ShareDialogViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "AlertControllerUtility.h"

@interface ShareDialogViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ShareDialogViewController
{
  UIAlertController *_alertController;
}

#pragma mark - FBSDKShareDialog::FBSDKShareDialogModeAutomatic

- (IBAction)showShareDialogModeAutomatic:(id)sender
{
  [self showShareDialogWithMode:FBSDKShareDialogModeAutomatic];
}

#pragma mark - FBSDKShareDialog::FBSDKShareDialogModeWeb

- (IBAction)showShareDialogModeWeb:(id)sender
{
  [self showShareDialogWithMode:FBSDKShareDialogModeWeb];
}

#pragma mark - FBSDKShareDialog::FBSDKSharePhotoContent

- (IBAction)showShareDialogPhotoContent:(id)sender
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.photos = @[[FBSDKSharePhoto photoWithImage:[UIImage imageNamed:@"sky.jpg"] userGenerated:YES]];
  [self showShareDialogWithContent:content];
}

#pragma mark - FBSDKShareDialog::FBSDKShareVideoContent

- (IBAction)showShareDialogVideoContent:(id)sender
{
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
  [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  NSURL *videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
  [picker dismissViewControllerAnimated:YES completion:NULL];
  FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
  video.videoURL = videoURL;
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.video = video;
  [self showShareDialogWithContent:content];
}

#pragma mark - Helper Method

- (void)showShareDialogWithMode:(FBSDKShareDialogMode)mode
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = mode;
  dialog.fromViewController = self;
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [NSURL URLWithString:@"https://newsroom.fb.com/"];
  content.imageURL = [NSURL URLWithString:@"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"];
  content.contentTitle = @"Name: Facebook News Room";
  content.contentDescription = @"Description: The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.";
  // placeID is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search for building a place picker.
  content.placeID = @"166793820034304";
  dialog.shareContent = content;
  dialog.shouldFailOnDataError = YES;
  [self shareDialog:dialog];
}

- (void)showShareDialogWithContent:(id<FBSDKSharingContent>)content
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeAutomatic;
  dialog.fromViewController = self;
  dialog.shareContent = content;
  dialog.shouldFailOnDataError = YES;
  [self shareDialog:dialog];
}

- (void)shareDialog:(FBSDKShareDialog *)dialog
{
  NSError *error;
  if (![dialog validateWithError:&error]) {
    _alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid share content" message:@"Error validating share content"];
    [self presentViewController:_alertController animated:YES completion:nil];
    return;
  }
  if (![dialog show]) {
    _alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid share content" message:@"Error opening dialog"];
    [self presentViewController:_alertController animated:YES completion:nil];
  }
}

@end
