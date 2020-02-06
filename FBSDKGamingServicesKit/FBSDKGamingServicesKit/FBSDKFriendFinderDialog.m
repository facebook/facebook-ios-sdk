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

#import "FBSDKFriendFinderDialog.h"

#import "FBSDKCoreKit+Internal.h"

static NSString *const kFriendFinderUrlFormat = @"https://fb.gg/me/friendfinder/%@";

@interface FBSDKFriendFinderDialog () <FBSDKURLOpening>
@end

@implementation FBSDKFriendFinderDialog
{
  BOOL _isPerformingFriendFinding;
  FBSDKFriendFinderCompletionBlock _completionBlock;
}

+ (void)launchFriendFinderDialogWithCompletionBlock:(FBSDKFriendFinderCompletionBlock)completionBlock
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionBlock(nil, [FBSDKError
                          errorWithCode:FBSDKErrorAccessTokenRequired
                          message:@"A valid access token is required to launch the Friend Finder"]);

    return;
  }

  FBSDKFriendFinderDialog *const instance = [[self alloc] init];
  if (instance) {
    instance->_completionBlock = completionBlock;
    instance->_isPerformingFriendFinding = true;
  }

  NSURL *const url =
  [NSURL URLWithString:
   [NSString
    stringWithFormat:kFriendFinderUrlFormat, FBSDKAccessToken.currentAccessToken.appID]];

  __weak FBSDKFriendFinderDialog *weakSelf = instance;
  [[FBSDKBridgeAPI sharedInstance]
   openURL:url
   sender:weakSelf
   handler:^(BOOL success, NSError * _Nullable error) {
    if (!success) {
      [weakSelf handleBridgeAPIError:error];
    }
  }];

  return;
}

- (void)handleBridgeAPIError:(NSError *)error
{
  _isPerformingFriendFinding = false;
  if (error) {
    _completionBlock(false, [FBSDKError
                             errorWithCode:FBSDKErrorBridgeAPIInterruption
                             message:@"Error occured while launching Friend Finder"
                             underlyingError:error]);
  } else {
    _completionBlock(false, [FBSDKError
                             errorWithCode:FBSDKErrorBridgeAPIInterruption
                             message:@"An Unknown error occured while launching Friend Finder"]);
  }

  _completionBlock = nil;
}

- (void)completeSuccessfully
{
  _isPerformingFriendFinding = false;
  _completionBlock(true, nil);
  _completionBlock = nil;
}

#pragma mark - FBSDKURLOpeningma
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  const BOOL isFriendFinderURL =
  [self
   canOpenURL:url
   forApplication:application
   sourceApplication:sourceApplication
   annotation:annotation];

  if (isFriendFinderURL) {
    [self completeSuccessfully];
  }

  return isFriendFinderURL;
}

- (BOOL)canOpenURL:(NSURL *)url
    forApplication:(UIApplication *)application
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
  // verify the URL is intended as a callback for the SDK's friend finder
  return [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]] &&
  [url.host isEqualToString:@"friend-finder"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (_isPerformingFriendFinding) {
    [self completeSuccessfully];
  }
}

@end
