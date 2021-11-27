/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKFriendFinderDialog.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

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
  if (!FBSDKSettings.sharedSettings.appID && !FBSDKAccessToken.currentAccessToken) {
    completionHandler(
      false,
      [FBSDKError
       errorWithCode:FBSDKErrorAccessTokenRequired
       message:@"A valid access token is required to launch the Friend Finder"]
    );

    return;
  }
  NSString *appID = FBSDKSettings.sharedSettings.appID ? FBSDKSettings.sharedSettings.appID : FBSDKAccessToken.currentAccessToken ? FBSDKAccessToken.currentAccessToken.appID : @"";

  id<FBSDKGamingServiceController> const controller =
  [self.factory
   createWithServiceType:FBSDKGamingServiceTypeFriendFinder
   pendingResult:nil
   completion:^(BOOL success, id _Nullable result, NSError *_Nullable error) {
     if (completionHandler) {
       completionHandler(success, error);
     }
   }];

  [controller callWithArgument:appID];
}

@end
