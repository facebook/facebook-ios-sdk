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

#import "FBSDKDeviceShareViewController.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKShareLinkContent.h"
#import "FBSDKShareOpenGraphContent.h"
#import "FBSDKShareUtility.h"

@implementation FBSDKDeviceShareViewController

- (instancetype)initWithShareContent:(id<FBSDKSharingContent>)shareContent
{
  if ((self = [super initWithNibName:nil bundle:nil]))
  {
    _shareContent = shareContent;
  }
  return self;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self.delegate deviceShareViewControllerDidComplete:self error:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [FBSDKInternalUtility validateRequiredClientAccessToken];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  NSError *error;
  NSDictionary *params = [self _graphRequestParametersForContent:_shareContent error:&error];
  if (!params) {
    [self _dismissWithError:error];
    return;
  }
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                initWithGraphPath:@"device/share"
                                parameters:params
                                tokenString:[FBSDKInternalUtility validateRequiredClientAccessToken]
                                HTTPMethod:@"POST"
                                flags:FBSDKGraphRequestFlagNone];
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *requestError) {
    if (requestError) {
      [self _dismissWithError:error];
      return;
    }
    NSString *code = result[@"user_code"];
    NSUInteger expires = [result[@"expires_in"] unsignedIntegerValue];
    if (!code || !expires) {
      [self _dismissWithError:[FBSDKError unknownErrorWithMessage:@"Malformed response from server"]];
      return;
    }
    self.deviceDialogView.confirmationCode = code;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(expires * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakSelf _dismissWithError:nil];
    });
  }];
}

#pragma mark - Private impl

- (void)_dismissWithError:(NSError *)error
{
  id<FBSDKDeviceShareViewControllerDelegate> delegate = self.delegate;
  // clear delegate to avoid double messaging after viewDidDisappear
  self.delegate = nil;
  [self dismissViewControllerAnimated:YES
                           completion:^{
                             [delegate deviceShareViewControllerDidComplete:self
                                                                      error:error];
                           }];
}

- (NSDictionary *)_graphRequestParametersForContent:(id<FBSDKSharingContent>)shareContent error:(NSError **)error
{
  if (error != NULL) {
    *error = nil;
  }
  if (!_shareContent) {
    if (error != NULL) {
      *error = [FBSDKError requiredArgumentErrorWithName:@"shareContent" message:nil];
    }
    return nil;
  }
  if ([_shareContent isKindOfClass:[FBSDKShareLinkContent class]] ||
      [_shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    NSString *unused;
    NSDictionary *params;
    [FBSDKShareUtility buildWebShareContent:_shareContent
                                 methodName:&unused
                                 parameters:&params
                                      error:error];
    return params;
  }
  if (error != NULL) {
    *error = [FBSDKError
              invalidArgumentErrorWithName:@"shareContent"
              value:shareContent
              message:[NSString stringWithFormat:@"%@ is not a supported content type", [shareContent class]]];
  }
  return nil;
}
@end
