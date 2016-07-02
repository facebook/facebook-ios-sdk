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

#import "GraphAPIPostViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "AlertControllerUtility.h"
#import "PermissionUtility.h"

@implementation GraphAPIPostViewController

#pragma mark - Post Checkin

- (IBAction)postCheckin:(id)sender
{
  void(^postCheckinCompletion)(void) = ^(void) {
    // See https://developers.facebook.com/docs/graph-api/reference/user/feed for details.
    // place is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search for building a place picker.
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me/feed"
                                  parameters:@{
                                               @"message" : @"Here I am!",
                                               @"place" : @"141887372509674", }
                                  HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      [self handleRequestCompletionWithResult:request error:error];
    }];
  };
  EnsureWritePermission(self, @"publish_actions", postCheckinCompletion);
}

#pragma mark - Helper Method

- (void)handleRequestCompletionWithResult:(id)result error:(NSError *)error
{
  NSString *title = nil;
  NSString *message = nil;
  if (error) {
    title = @"Graph Request Fail";
    message = [NSString stringWithFormat:@"Post failed with error:\n %@", error];
  } else {
    title = @"Graph Request Success";
    message = [NSString stringWithFormat:@"Post success with result:\n %@", result];
  }
  UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:title message:message];
  [self presentViewController:alertController animated:YES completion:nil];
}

@end
