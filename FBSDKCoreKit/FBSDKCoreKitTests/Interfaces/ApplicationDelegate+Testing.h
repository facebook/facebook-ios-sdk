/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKApplicationDelegate.h"
#import "FBSDKCoreKitComponents.h"
#import "FBSDKCoreKitConfiguring.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKApplicationDelegate (Testing)

@property (nonnull, nonatomic) NSHashTable<id<FBSDKApplicationObserving>> *applicationObservers;
@property (nonatomic, readonly) FBSDKCoreKitComponents *components;
@property (nonatomic, readonly) id<FBSDKCoreKitConfiguring> configurator;

@property (nonatomic) BOOL isAppLaunched;

// UNCRUSTIFY_FORMAT_OFF
+ (void)resetHasInitializeBeenCalled
NS_SWIFT_NAME(reset());
// UNCRUSTIFY_FORMAT_ON

- (instancetype)initWithComponents:(FBSDKCoreKitComponents *)components
                      configurator:(id<FBSDKCoreKitConfiguring>)configurator;

- (void)initializeSDKWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
- (void)applicationDidEnterBackground:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)_logSDKInitialize;
- (void)resetApplicationObserverCache;
- (void)setApplicationState:(UIApplicationState)state;

@end

NS_ASSUME_NONNULL_END
