/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

#import "FBSDKGamingGroupIntegration.h"

@protocol FBSDKGamingServiceControllerCreating;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGamingGroupIntegration (Testing)

@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKGamingServiceControllerCreating> serviceControllerFactory;

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
        serviceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory;

- (void)openGroupPageWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler;

@end

NS_ASSUME_NONNULL_END
