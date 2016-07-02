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

#import "FBSDKDeviceLoginViewController.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDeviceLoginManager.h"

@interface FBSDKDeviceLoginViewController() <
  FBSDKDeviceLoginManagerDelegate
>
@end

@implementation FBSDKDeviceLoginViewController {
  FBSDKDeviceLoginManager *_loginManager;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self _cancel];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSArray<NSString *> *permissions = nil;
  if ((self.readPermissions).count > 0) {
    NSSet<NSString *> *permissionSet = [NSSet setWithArray:self.readPermissions];
    if ((self.publishPermissions).count > 0 || ![FBSDKInternalUtility areAllPermissionsReadPermissions:permissionSet]) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Read permissions are not permitted to be requested with publish or manage permissions."
                             userInfo:nil]
       raise];
    } else {
      permissions = self.readPermissions;
    }
  } else {
    NSSet<NSString *> *permissionSet = [NSSet setWithArray:self.publishPermissions];
    if (![FBSDKInternalUtility areAllPermissionsPublishPermissions:permissionSet]) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Publish or manage permissions are not permitted to be requested with read permissions."
                             userInfo:nil]
       raise];
    } else {
      permissions = self.publishPermissions;
    }
  }
  _loginManager = [[FBSDKDeviceLoginManager alloc] initWithPermissions:permissions];
  _loginManager.delegate = self;
  _loginManager.redirectURL = self.redirectURL;
  [_loginManager start];
}

- (void)dealloc
{
  _loginManager.delegate = nil;
  _loginManager = nil;
}

#pragma mark - FBSDKDeviceLoginManagerDelegate

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  ((FBSDKDeviceDialogView *)self.view).confirmationCode = codeInfo.loginCode;
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager completedWithResult:(FBSDKDeviceLoginManagerResult *)result error:(NSError *)error
{
  // Go ahead and clear the delegate to avoid double messaging (i.e., since we're dismissing
  // ourselves we don't want a didCancel (from viewDidDisappear) then didFinish.
  id<FBSDKDeviceLoginViewControllerDelegate> delegate = self.delegate;
  self.delegate = nil;
  [self dismissViewControllerAnimated:YES completion:^{
    if (result.isCancelled) {
      [self _cancel];
    } else if (result.accessToken) {
      [FBSDKAccessToken setCurrentAccessToken:result.accessToken];
      [delegate deviceLoginViewControllerDidFinish:self];
    } else {
      [delegate deviceLoginViewControllerDidFail:self error:error];
    }
  }];
}

#pragma mark - Private impl

- (void)_cancel
{
  [_loginManager cancel];
  [self.delegate deviceLoginViewControllerDidCancel:self];
}

@end
