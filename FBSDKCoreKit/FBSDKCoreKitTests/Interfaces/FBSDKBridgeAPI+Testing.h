/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <SafariServices/SafariServices.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKBridgeAPI+Internal.h"
#import "FBSDKContainerViewController.h"
#import "FBSDKOperatingSystemVersionComparing.h"
#import "NSProcessInfo+Protocols.h"

@protocol FBSDKLogging;
@protocol FBSDKBridgeAPIResponseCreating;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBSDKAuthenticationCompletionHandler)(NSURL *_Nullable callbackURL, NSError *_Nullable error);

NS_SWIFT_NAME(AuthenticationSessionHandling)
@protocol FBSDKAuthenticationSession <NSObject>

- (instancetype)initWithURL:(NSURL *)URL callbackURLScheme:(nullable NSString *)callbackURLScheme completionHandler:(FBSDKAuthenticationCompletionHandler)completionHandler;
- (BOOL)start;
- (void)cancel;
@optional
- (void)setPresentationContextProvider:(id)presentationContextProvider;

@end

/// Specifies state of FBSDKAuthenticationSession (SFAuthenticationSession (iOS 11) and ASWebAuthenticationSession (iOS 12+))
typedef NS_ENUM(NSUInteger, FBSDKAuthenticationSession) {
  /// There is no active authentication session
  FBSDKAuthenticationSessionNone,
  /// The authentication session has started
  FBSDKAuthenticationSessionStarted,
  /// System dialog ("app wants to use facebook.com  to sign in")  to access facebook.com was presented to the user
  FBSDKAuthenticationSessionShowAlert,
  /// Web browser with log in to authentication was presented to the user
  FBSDKAuthenticationSessionShowWebBrowser,
  /// Authentication session was canceled by system. It happens when app goes to background while alert requesting access to facebook.com is presented
  FBSDKAuthenticationSessionCanceledBySystem,
}
NS_SWIFT_NAME(AuthenticationSession);

@protocol FBSDKDynamicFrameworkResolving;

@interface FBSDKBridgeAPI (Testing)

@property (nonatomic, readonly, assign) id<FBSDKOperatingSystemVersionComparing> processInfo;
@property (nonatomic, readonly) id<FBSDKInternalURLOpener> urlOpener;
@property (nonatomic, readonly) id<FBSDKLogging> logger;
@property (nonatomic, readonly) id<FBSDKBridgeAPIResponseCreating> bridgeAPIResponseFactory;
@property (nonatomic, readonly) id<FBSDKDynamicFrameworkResolving> frameworkLoader;
@property (nonatomic, readonly) id<FBSDKAppURLSchemeProviding> appURLSchemeProvider;
@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nullable, nonatomic) NSObject<FBSDKBridgeAPIRequest> *pendingRequest;
@property (nullable, nonatomic) FBSDKBridgeAPIResponseBlock pendingRequestCompletionBlock;
@property (nullable, nonatomic) id<FBSDKURLOpening> pendingURLOpen;
@property (nullable, nonatomic) id<FBSDKAuthenticationSession> authenticationSession;
@property (nullable, nonatomic) FBSDKAuthenticationCompletionHandler authenticationSessionCompletionHandler;
@property (nonatomic) FBSDKAuthenticationSession authenticationSessionState;
@property (nonatomic) BOOL expectingBackground;
@property (nullable, nonatomic) SFSafariViewController *safariViewController;
@property (nonatomic) BOOL isDismissingSafariViewController;

- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

- (void)setActive:(BOOL)isActive;

- (BOOL)_handleBridgeAPIResponseURL:(NSURL *)responseURL sourceApplication:(NSString *)sourceApplication;
- (FBSDKSuccessBlock)_bridgeAPIRequestCompletionBlockWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                      completion:(FBSDKBridgeAPIResponseBlock)completionBlock;
- (void)_cancelBridgeRequest;

- (void)safariViewControllerDidFinish:(UIViewController *)safariViewController;
- (void)viewControllerDidDisappear:(FBSDKContainerViewController *)viewController animated:(BOOL)animated;
- (void)setSessionCompletionHandlerFromHandler:(void (^)(BOOL, NSError *))handler;

@end

@interface FBSDKBridgeAPIResponse (Testing)

+ (nullable instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                          responseURL:(NSURL *)responseURL
                                    sourceApplication:(NSString *)sourceApplication
                                    osVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)comparer
                                                error:(NSError *__autoreleasing *)errorRef;

- (instancetype)initWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
             responseParameters:(NSDictionary<NSString *, id> *)responseParameters
                      cancelled:(BOOL)cancelled
                          error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
