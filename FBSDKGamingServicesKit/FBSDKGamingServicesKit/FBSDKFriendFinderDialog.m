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

#import "FBSDKCoreKitInternalImport.h"
#import "FBSDKGamingServiceController.h"

@interface FBSDKFriendFinderDialog ()
@end

@implementation FBSDKFriendFinderDialog

- (instancetype)init
{
  return [super init];
}

+ (void)launchFriendFinderDialogWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionHandler(
      false,
      [FBSDKError
       errorWithCode:FBSDKErrorAccessTokenRequired
       message:@"A valid access token is required to launch the Friend Finder"]
    );

    return;
  }

  FBSDKGamingServiceController *const controller =
  [[FBSDKGamingServiceController alloc]
   initWithServiceType:FBSDKGamingServiceTypeFriendFinder
   completionHandler:^(BOOL success, id _Nullable result, NSError *_Nullable error) {
     if (completionHandler) {
       completionHandler(success, error);
     }
   }
   pendingResult:nil];

  [controller callWithArgument:FBSDKAccessToken.currentAccessToken.appID];
}

@end
