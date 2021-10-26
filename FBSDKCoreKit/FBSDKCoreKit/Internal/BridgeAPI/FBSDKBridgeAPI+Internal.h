/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppURLSchemeProviding.h>
#import <FBSDKCoreKit/FBSDKLogger.h>

#import "FBSDKBridgeAPI.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKDynamicFrameworkResolving.h"
#import "FBSDKErrorCreating.h"
#import "FBSDKInternalURLOpener.h"
#import "FBSDKOperatingSystemVersionComparing.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPI (Internal)

@property (nonatomic, readonly) FBSDKAuthenticationCompletionHandler sessionCompletionHandler;

- (instancetype)initWithProcessInfo:(id<FBSDKOperatingSystemVersionComparing>)processInfo
                             logger:(FBSDKLogger *)logger
                          urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
           bridgeAPIResponseFactory:(id<FBSDKBridgeAPIResponseCreating>)bridgeAPIResponseFactory
                    frameworkLoader:(id<FBSDKDynamicFrameworkResolving>)frameworkLoader
               appURLSchemeProvider:(id<FBSDKAppURLSchemeProviding>)appURLSchemeProvider
                       errorFactory:(id<FBSDKErrorCreating>)errorFactory;

- (void)openURLWithAuthenticationSession:(NSURL *)url;

- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(nullable id<FBSDKURLOpening>)sender
                     fromViewController:(nullable UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler;

- (void)setSessionCompletionHandlerFromHandler:(void (^)(BOOL, NSError *))handler;

@end

NS_ASSUME_NONNULL_END
