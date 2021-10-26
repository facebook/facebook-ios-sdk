/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocol.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequest.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequestOpening.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIResponse.h>
 #import <FBSDKCoreKit/FBSDKConstants.h>
 #import <FBSDKCoreKit/FBSDKURLOpening.h>

@class FBSDKLogger;
@protocol FBSDKOperatingSystemVersionComparing;
@protocol FBSDKInternalURLOpener;
@protocol FBSDKBridgeAPIResponseCreating;
@protocol FBSDKDynamicFrameworkResolving;
@protocol FBSDKAppURLSchemeProviding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
typedef void (^FBSDKAuthenticationCompletionHandler)(NSURL *_Nullable callbackURL, NSError *_Nullable error);

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPI)
@interface FBSDKBridgeAPI : NSObject <FBSDKBridgeAPIRequestOpening>

@property (class, nonatomic, readonly, strong) FBSDKBridgeAPI *sharedInstance
NS_SWIFT_NAME(shared);
@property (nonatomic, readonly, getter = isActive) BOOL active;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithProcessInfo:(id<FBSDKOperatingSystemVersionComparing>)processInfo
                             logger:(FBSDKLogger *)logger
                          urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
           bridgeAPIResponseFactory:(id<FBSDKBridgeAPIResponseCreating>)bridgeAPIResponseFactory
                    frameworkLoader:(id<FBSDKDynamicFrameworkResolving>)frameworkLoader
               appURLSchemeProvider:(id<FBSDKAppURLSchemeProviding>)appURLSchemeProvider
  NS_DESIGNATED_INITIALIZER;

- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(nullable id<FBSDKURLOpening>)sender
                     fromViewController:(nullable UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler;

- (void)openURL:(NSURL *)url
         sender:(nullable id<FBSDKURLOpening>)sender
        handler:(FBSDKSuccessBlock)handler;

- (FBSDKAuthenticationCompletionHandler)sessionCompletionHandler;

@end

NS_ASSUME_NONNULL_END

#endif
