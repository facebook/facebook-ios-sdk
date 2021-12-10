/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGamingServiceController (Testing)

- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletion)completion
                      pendingResult:(id)pendingResult
                          urlOpener:(id<FBSDKURLOpener>)urlOpener
                           settings:(id<FBSDKSettings>)settings;

- (id<FBSDKSettings>)settings;

- (void)callWithArgument:(nullable NSString *)argument;

- (void)applicationDidBecomeActive:(UIApplication *)application;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

- (BOOL)isValidCallbackURL:(NSURL *)url forService:(NSString *)service;

- (BOOL)isAuthenticationURL:(NSURL *)url;

- (void)handleBridgeAPIError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
