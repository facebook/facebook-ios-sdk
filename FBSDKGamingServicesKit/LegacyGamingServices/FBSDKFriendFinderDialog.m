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

#import "FBSDKGamingServiceControllerCreating.h"
#import "FBSDKGamingServiceControllerFactory.h"
#import "FBSDKGamingServicesCoreKitImport.h"

@interface FBSDKFriendFinderDialog ()

@property (nonnull, nonatomic) id<FBSDKGamingServiceControllerCreating> factory;

@end

@implementation FBSDKFriendFinderDialog

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
+ (FBSDKFriendFinderDialog *)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

- (instancetype)init
{
  return [self initWithGamingServiceControllerFactory:[FBSDKGamingServiceControllerFactory new]];
}

- (instancetype)initWithGamingServiceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory
{
  if ((self = [super init])) {
    _factory = factory;
  }
  return self;
}

+ (void)launchFriendFinderDialogWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  [self.shared launchFriendFinderDialogWithCompletionHandler:completionHandler];
}

- (void)launchFriendFinderDialogWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  if (![FBSDKSettings appID] && ![FBSDKAccessToken currentAccessToken]) {
    completionHandler(
      false,
      [FBSDKError
       errorWithCode:FBSDKErrorAccessTokenRequired
       message:@"A valid access token is required to launch the Friend Finder"]
    );

    return;
  }
  NSString *appID = [FBSDKSettings appID] ? [FBSDKSettings appID] : [FBSDKAccessToken currentAccessToken] ? FBSDKAccessToken.currentAccessToken.appID : @"";

  id<FBSDKGamingServiceController> const controller =
  [self.factory
   createWithServiceType:FBSDKGamingServiceTypeFriendFinder
   completion:^(BOOL success, id _Nullable result, NSError *_Nullable error) {
     if (completionHandler) {
       completionHandler(success, error);
     }
   }
   pendingResult:nil];

  [controller callWithArgument:appID];
}

@end
