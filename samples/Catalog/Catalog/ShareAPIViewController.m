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

#import "ShareAPIViewController.h"

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "AlertControllerUtility.h"
#import "PermissionUtility.h"

@interface ShareAPIViewController () <FBSDKSharingDelegate>

@end

@implementation ShareAPIViewController

#pragma mark - FBSDKShareLinkContent

- (IBAction)shareLink:(id)sender
{
  void (^shareLinkBlock)(void) = ^{
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://newsroom.fb.com/"];
    content.contentTitle = @"Name: Facebook News Room";
    content.contentDescription = @"Description: The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.";
    [FBSDKShareAPI shareWithContent:content delegate:self];
  };
  EnsureWritePermission(self, @"publish_actions", shareLinkBlock);
}

#pragma mark - FBSDKSharePhotoContent

- (IBAction)sharePhoto:(id)sender
{
  void (^sharePhotoBlock)(void) = ^{
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[[FBSDKSharePhoto photoWithImage:[UIImage imageNamed:@"sky.jpg"] userGenerated:YES]];
    [FBSDKShareAPI shareWithContent:content delegate:self];
  };
  EnsureWritePermission(self, @"publish_actions", sharePhotoBlock);
}

#pragma mark - FBSDKShareVideoContent

- (IBAction)shareVideo:(id)sender
{
  void (^shareVideoBlock)(void) = ^{
    FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"sky" withExtension:@"mp4"];
    content.video = [FBSDKShareVideo videoWithVideoURL:bundleURL];
    [FBSDKShareAPI shareWithContent:content delegate:self];
  };
  EnsureWritePermission(self, @"publish_actions", shareVideoBlock);
}

#pragma mark - Helper Method

- (NSString *)_serializeJSONObject:(id)results
{
  UIAlertController *alertController;
  if (![NSJSONSerialization isValidJSONObject:results]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid JSON Object"
                                                               message:[NSString stringWithFormat:@"Invalid JSON object: %@", results]];
    [self presentViewController:alertController animated:YES completion:nil];
    return nil;
  }
  NSError *error;
  NSData *resultData = [NSJSONSerialization dataWithJSONObject:results options:0 error:&error];
  if (!resultData) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Serialize JSON Object Fail"
                                                               message:[NSString stringWithFormat:@"Error serializing result to JSON: %@", results]];
    [self presentViewController:alertController animated:YES completion:nil];
    return nil;
  }
  return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  NSString *resultString = [self _serializeJSONObject:results];
  UIAlertController *alertController;
  if (resultString) {
      alertController = [AlertControllerUtility alertControllerWithTitle:@"Share success"
                                                                 message:[NSString stringWithFormat:@"Content successfully shared: %@", resultString]];
  } else {
      alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid result"
                                                                 message:@"Return result is not valid JSON"];
  }
  [self presentViewController:alertController animated:YES completion:nil];
  sharer.delegate = nil;
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:@"Share fail"
                                                                                message:[NSString stringWithFormat:@"Error sharing content: %@", [self _serializeJSONObject: error]]];
  [self presentViewController:alertController animated:YES completion:nil];
  sharer.delegate = nil;
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:@"Share cancelled"
                                                                                message:@"Share cancelled by user"];
  [self presentViewController:alertController animated:YES completion:nil];
  sharer.delegate = nil;
}

@end
