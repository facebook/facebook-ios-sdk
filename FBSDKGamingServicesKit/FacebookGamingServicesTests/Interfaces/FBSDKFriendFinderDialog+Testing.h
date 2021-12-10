/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

@protocol FBSDKGamingServiceControllerCreating;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKFriendFinderDialog (Testing)

@property (class, nonnull, nonatomic, readonly) FBSDKFriendFinderDialog *shared;
@property (nonnull, nonatomic) id<FBSDKGamingServiceControllerCreating> factory;

- (instancetype)initWithGamingServiceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory;

- (void)launchFriendFinderDialogWithCompletionHandler:(FBSDKGamingServiceCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
