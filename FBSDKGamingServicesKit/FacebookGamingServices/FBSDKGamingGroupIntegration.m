/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingGroupIntegration.h"

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

@interface FBSDKGamingGroupIntegration ()

@property (nonatomic) id<FBSDKGamingServiceControllerCreating> serviceControllerFactory;
@property (nonatomic) id<FBSDKSettings> settings;

@end

@implementation FBSDKGamingGroupIntegration

- (instancetype)init
{
  return [self initWithSettings:FBSDKSettings.sharedSettings
          serviceControllerFactory:[FBSDKGamingServiceControllerFactory new]];
}

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
        serviceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory
{
  if ((self = [super init])) {
    _settings = settings;
    _serviceControllerFactory = factory;
  }

  return self;
}

+ (void)openGroupPageWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  FBSDKGamingGroupIntegration *integration = [FBSDKGamingGroupIntegration new];
  [integration openGroupPageWithCompletionHandler:completionHandler];
}

- (void)openGroupPageWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  id<FBSDKGamingServiceController> const controller =
  [self.serviceControllerFactory
   createWithServiceType:FBSDKGamingServiceTypeCommunity
   pendingResult:nil
   completion:^(BOOL success, id _Nullable result, NSError *_Nullable error) {
     if (completionHandler) {
       completionHandler(success, error);
     }
   }];

  [controller callWithArgument:self.settings.appID];
}

@end
