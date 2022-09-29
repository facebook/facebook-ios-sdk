/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(URLOpening)
@protocol FBSDKURLOpening <NSObject>

// Implementations should make sure they can handle nil parameters
// which is possible in SafariViewController.
// see canOpenURL below.
- (BOOL)application:(nullable UIApplication *)application
            openURL:(nullable NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

// create a different handler to return YES/NO if the receiver can process the above openURL:.
// This is separated so that we can process the openURL: in callbacks, while still returning
// the result of canOpenURL synchronously in FBSDKApplicationDelegate
- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(nullable UIApplication *)application
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

- (void)applicationDidBecomeActive:(UIApplication *)application;

- (BOOL)isAuthenticationURL:(NSURL *)url;

@optional

+ (instancetype)makeOpener;

- (BOOL)shouldStopPropagationOfURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

#endif
