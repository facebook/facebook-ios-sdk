/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Describes any types that optionally responds to various lifecycle events
 received by the system and propagated by `ApplicationDelegate`.
 */
@protocol FBSDKApplicationObserving <NSObject>

@optional
- (void)applicationDidBecomeActive:(nullable UIApplication *)application;
- (void)applicationWillResignActive:(nullable UIApplication *)application;
- (void)applicationDidEnterBackground:(nullable UIApplication *)application;
- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

@end

NS_ASSUME_NONNULL_END
