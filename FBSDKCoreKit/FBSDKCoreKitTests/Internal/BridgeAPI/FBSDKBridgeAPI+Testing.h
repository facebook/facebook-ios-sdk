// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "FBSDKBridgeAPI.h"
#import "FBSDKContainerViewController.h"

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

/**
 Specifies state of FBSDKAuthenticationSession (SFAuthenticationSession (iOS 11) and ASWebAuthenticationSession (iOS 12+))
 */
typedef NS_ENUM(NSUInteger, FBSDKAuthenticationSession) {
  /** There is no active authentication session*/
  FBSDKAuthenticationSessionNone,
  /** The authentication session has started*/
  FBSDKAuthenticationSessionStarted,
  /** System dialog ("app wants to use facebook.com  to sign in")  to access facebook.com was presented to the user*/
  FBSDKAuthenticationSessionShowAlert,
  /** Web browser with log in to authentication was presented to the user*/
  FBSDKAuthenticationSessionShowWebBrowser,
  /** Authentication session was canceled by system. It happens when app goes to background while alert requesting access to facebook.com is presented*/
  FBSDKAuthenticationSessionCanceledBySystem,
};

@interface FBSDKBridgeAPI (Testing)

- (id<FBSDKAuthenticationSession>)authenticationSession;
- (FBSDKAuthenticationSession)authenticationSessionState;
- (FBSDKAuthenticationCompletionHandler)authenticationSessionCompletionHandler;
- (BOOL)expectingBackground;
- (id<FBSDKURLOpening>)pendingUrlOpen;
- (UIViewController *)safariViewController;
- (BOOL)isDismissingSafariViewController;
- (NSObject<FBSDKBridgeAPIRequestProtocol> *)pendingRequest;
- (FBSDKBridgeAPIResponseBlock)pendingRequestCompletionBlock;

- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

- (void)setAuthenticationSession:(id<FBSDKAuthenticationSession>)session;
- (void)setAuthenticationSessionState:(FBSDKAuthenticationSession)state;
- (void)setAuthenticationSessionCompletionHandler:(nullable FBSDKAuthenticationCompletionHandler)handler;
- (void)setActive:(BOOL)isActive;
- (void)setExpectingBackground:(BOOL)isExpectingBackground;
- (void)setPendingUrlOpen:(id<FBSDKURLOpening>)opening;
- (void)setSafariViewController:(nullable UIViewController *)controller;
- (void)setIsDismissingSafariViewController:(BOOL)isDismissing;
- (void)setPendingRequest:(NSObject<FBSDKBridgeAPIRequestProtocol> *)newValue;
- (void)setPendingRequestCompletionBlock:(FBSDKBridgeAPIResponseBlock)newValue;

- (BOOL)_handleBridgeAPIResponseURL:(NSURL *)responseURL sourceApplication:(NSString *)sourceApplication;
- (FBSDKSuccessBlock)_bridgeAPIRequestCompletionBlockWithRequest:(NSObject<FBSDKBridgeAPIRequestProtocol> *)request
                                                                               completion:(FBSDKBridgeAPIResponseBlock)completionBlock;
- (void)_cancelBridgeRequest;

- (void)safariViewControllerDidFinish:(UIViewController *)safariViewController;
- (void)viewControllerDidDisappear:(FBSDKContainerViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
