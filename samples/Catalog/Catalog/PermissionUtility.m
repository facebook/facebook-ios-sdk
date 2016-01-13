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

#import "PermissionUtility.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "AlertControllerUtility.h"

#pragma mark - Helper Method

static void ensurePermission(UIViewController* viewController, NSString* permission, BOOL isPublishPermission, dispatch_block_t block)
{
  if ([[FBSDKAccessToken currentAccessToken].permissions containsObject:permission] && block != NULL) {
    block();
  } else {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    FBSDKLoginManagerRequestTokenHandler logInHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
      NSString *title = nil;
      NSString *message = nil;
      if (error) {
        title = @"Authorization fail";
        message = [NSString stringWithFormat: @"Error authorizing user for %@ permission.", permission];
      } else if (!result || result.isCancelled) {
        title = @"Authorization cancelled";
        message = @"User cancelled permissions dialog.";
      } else if ([result.declinedPermissions containsObject:permission]) {
        title = @"Authorization fail";
        message = [NSString stringWithFormat:@"User declined %@ permission.", permission];
      } else if (![result.grantedPermissions containsObject:permission]) {
        title = @"Authorization fail";
        message = [NSString stringWithFormat:@"Expected to find %@ permission granted, but only found %@",
                   permission,
                   [[result.grantedPermissions allObjects] componentsJoinedByString:@", "]];
      }
      if (title != nil && message != nil) {
        UIAlertController *alertController = [AlertControllerUtility alertControllerWithTitle:title
                                                                                      message:message];
        [viewController presentViewController:alertController animated:YES completion:nil];
        return;
      }
      if (block != NULL) {
        block();
      }
    };
    if (isPublishPermission) {
      [loginManager logInWithPublishPermissions:@[permission] fromViewController:viewController handler:logInHandler];
    } else {
      [loginManager logInWithReadPermissions:@[permission] fromViewController:viewController handler:logInHandler];
    }
  }
}

#pragma mark - Public Method

void EnsureReadPermission(UIViewController *viewController, NSString *permission, dispatch_block_t block)
{
  ensurePermission(viewController, permission, NO, block);
}

void EnsureWritePermission(UIViewController *viewController, NSString *permission, dispatch_block_t block)
{
  ensurePermission(viewController, permission, YES, block);
}
