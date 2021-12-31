/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPI+Internal.h"

#import <SafariServices/SafariServices.h>

#import <AuthenticationServices/AuthenticationServices.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKBridgeAPIResponseCreating.h"
#import "FBSDKBridgeAPIResponseFactory.h"
#import "FBSDKContainerViewController.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger+Internal.h"
#import "FBSDKOperatingSystemVersionComparing.h"
#import "FBSDKURLScheme.h"
#import "NSProcessInfo+Protocols.h"
#import "UIApplication+URLOpener.h"

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

@protocol FBSDKAuthenticationSession <NSObject>

- (instancetype)initWithURL:(NSURL *)URL callbackURLScheme:(nullable NSString *)callbackURLScheme completionHandler:(FBSDKAuthenticationCompletionHandler)completionHandler;
- (BOOL)start;
- (void)cancel;
@optional
- (void)setPresentationContextProvider:(id)presentationContextProvider;

@end

@interface FBSDKBridgeAPI () <FBSDKContainerViewControllerDelegate, ASWebAuthenticationPresentationContextProviding>

@property (nonnull, nonatomic) FBSDKLogger *logger;
@property (nonatomic, readonly) id<FBSDKInternalURLOpener> urlOpener;
@property (nonatomic, readonly) id<FBSDKBridgeAPIResponseCreating> bridgeAPIResponseFactory;
@property (nonatomic, readonly) id<FBSDKDynamicFrameworkResolving> frameworkLoader;
@property (nonatomic, readonly) id<FBSDKAppURLSchemeProviding> appURLSchemeProvider;
@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic) NSObject<FBSDKBridgeAPIRequest> *pendingRequest;
@property (nonatomic) FBSDKBridgeAPIResponseBlock pendingRequestCompletionBlock;
@property (nonatomic) id<FBSDKURLOpening> pendingURLOpen;
@property (nonatomic) id<FBSDKAuthenticationSession> authenticationSession NS_AVAILABLE_IOS(11_0);
@property (nonatomic) FBSDKAuthenticationCompletionHandler authenticationSessionCompletionHandler NS_AVAILABLE_IOS(11_0);
@property (nonatomic) FBSDKAuthenticationSession authenticationSessionState;
@property (nonatomic) BOOL expectingBackground;
@property (nullable, nonatomic) SFSafariViewController *safariViewController;
@property (nonatomic) BOOL isDismissingSafariViewController;
@property (nonatomic) id<FBSDKOperatingSystemVersionComparing> processInfo;
@property (nonatomic) BOOL isAppLaunched;

@end

@implementation FBSDKBridgeAPI

+ (FBSDKBridgeAPI *)sharedInstance
{
  static FBSDKBridgeAPI *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    FBSDKErrorFactory *errorFactory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
    _sharedInstance = [[self alloc] initWithProcessInfo:NSProcessInfo.processInfo
                                                 logger:[[FBSDKLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors]
                                              urlOpener:UIApplication.sharedApplication
                               bridgeAPIResponseFactory:[FBSDKBridgeAPIResponseFactory new]
                                        frameworkLoader:FBSDKDynamicFrameworkLoader.shared
                                   appURLSchemeProvider:FBSDKInternalUtility.sharedUtility
                                           errorFactory:errorFactory];
  });
  return _sharedInstance;
}

- (instancetype)initWithProcessInfo:(id<FBSDKOperatingSystemVersionComparing>)processInfo
                             logger:(FBSDKLogger *)logger
                          urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
           bridgeAPIResponseFactory:(id<FBSDKBridgeAPIResponseCreating>)bridgeAPIResponseFactory
                    frameworkLoader:(id<FBSDKDynamicFrameworkResolving>)frameworkLoader
               appURLSchemeProvider:(nonnull id<FBSDKAppURLSchemeProviding>)appURLSchemeProvider
                       errorFactory:(nonnull id<FBSDKErrorCreating>)errorFactory;
{
  if ((self = [super init])) {
    _processInfo = processInfo;
    _logger = logger;
    _urlOpener = urlOpener;
    _bridgeAPIResponseFactory = bridgeAPIResponseFactory;
    _frameworkLoader = frameworkLoader;
    _appURLSchemeProvider = appURLSchemeProvider;
    _errorFactory = errorFactory;
  }
  return self;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  [self _updateAuthStateIfSystemAlertToUseWebAuthFlowPresented];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  BOOL isRequestingWebAuthenticationSession = NO;
  if (@available(iOS 11.0, *)) {
    if (_authenticationSession && _authenticationSessionState == FBSDKAuthenticationSessionShowAlert) {
      _authenticationSessionState = FBSDKAuthenticationSessionShowWebBrowser;
    } else if (_authenticationSession && _authenticationSessionState == FBSDKAuthenticationSessionCanceledBySystem) {
      [_authenticationSession cancel];
      _authenticationSession = nil;
      NSString *errorDomain;
      if (@available(iOS 12.0, *)) {
        errorDomain = @"com.apple.AuthenticationServices.WebAuthenticationSession";
      } else {
        errorDomain = @"com.apple.SafariServices.Authentication";
      }

      NSError *error = [self.errorFactory errorWithDomain:errorDomain
                                                     code:1
                                                 userInfo:nil
                                                  message:nil
                                          underlyingError:nil];
      if (_authenticationSessionCompletionHandler) {
        _authenticationSessionCompletionHandler(nil, error);
      }
      isRequestingWebAuthenticationSession = [self _isRequestingWebAuthenticationSession];
    }
  }
  // _expectingBackground can be YES if the caller started doing work (like login)
  // within the app delegate's lifecycle like openURL, in which case there
  // might have been a "didBecomeActive" event pending that we want to ignore.
  BOOL notExpectingBackground = !_expectingBackground && !_safariViewController && !_isDismissingSafariViewController && !isRequestingWebAuthenticationSession;
  if (notExpectingBackground) {
    _active = YES;

    [_pendingURLOpen applicationDidBecomeActive:application];
    [self _cancelBridgeRequest];

    [NSNotificationCenter.defaultCenter postNotificationName:FBSDKApplicationDidBecomeActiveNotification object:self];
  }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  _active = NO;
  _expectingBackground = NO;
  [self _updateAuthStateIfSystemCancelAuthSession];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  id<FBSDKURLOpening> pendingURLOpen = _pendingURLOpen;

  if ([pendingURLOpen respondsToSelector:@selector(shouldStopPropagationOfURL:)]
      && [pendingURLOpen shouldStopPropagationOfURL:url]) {
    return YES;
  }

  BOOL canOpenURL = [pendingURLOpen canOpenURL:url
                                forApplication:application
                             sourceApplication:sourceApplication
                                    annotation:annotation];

  void (^completePendingOpenURLBlock)(void) = ^{
    self->_pendingURLOpen = nil;
    [pendingURLOpen application:application
                        openURL:url
              sourceApplication:sourceApplication
                     annotation:annotation];
    self->_isDismissingSafariViewController = NO;
  };
  // if they completed a SFVC flow, dismiss it.
  if (_safariViewController) {
    _isDismissingSafariViewController = YES;
    [_safariViewController.presentingViewController dismissViewControllerAnimated:YES
                                                                       completion:completePendingOpenURLBlock];
    _safariViewController = nil;
  } else {
    if (@available(iOS 11.0, *)) {
      if (_authenticationSession != nil) {
        [_authenticationSession cancel];
        _authenticationSession = nil;

        // This check is needed in case another sdk / message / ad etc... tries to open the app
        // during the login flow.
        // This dismisses the authentication browser without triggering any login callbacks.
        // Hence we need to explicitly call the authentication session's completion handler.
        if (!canOpenURL) {
          NSString *errorMessage = [[NSString alloc]
                                    initWithFormat:@"Login attempt cancelled by alternate call to openURL from: %@",
                                    url];
          NSError *loginError = [self.errorFactory errorWithCode:FBSDKErrorBridgeAPIInterruption
                                                        userInfo:@{FBSDKErrorLocalizedDescriptionKey : errorMessage}
                                                         message:errorMessage
                                                 underlyingError:nil];
          if (_authenticationSessionCompletionHandler) {
            _authenticationSessionCompletionHandler(url, loginError);
            _authenticationSessionCompletionHandler = nil;
          }
        }
      }
    }
    completePendingOpenURLBlock();
  }

  if (canOpenURL) {
    return YES;
  }

  if ([self _handleBridgeAPIResponseURL:url sourceApplication:sourceApplication]) {
    return YES;
  }

  return NO;
}

- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  NSURL *launchedURL = launchOptions[UIApplicationLaunchOptionsURLKey];
  NSString *sourceApplication = launchOptions[UIApplicationLaunchOptionsSourceApplicationKey];

  if (launchedURL
      && sourceApplication) {
    Class loginManagerClass = NSClassFromString(@"FBSDKLoginManager");
    if (loginManagerClass) {
      id annotation = launchOptions[UIApplicationLaunchOptionsAnnotationKey];
      id<FBSDKURLOpening> loginManager = [loginManagerClass new];
      return [loginManager application:application
                               openURL:launchedURL
                     sourceApplication:sourceApplication
                            annotation:annotation];
    }
  }

  return NO;
}

- (void)_updateAuthStateIfSystemAlertToUseWebAuthFlowPresented
{
  if (@available(iOS 11.0, *)) {
    if (_authenticationSession && _authenticationSessionState == FBSDKAuthenticationSessionStarted) {
      _authenticationSessionState = FBSDKAuthenticationSessionShowAlert;
    }
  }
}

- (void)_updateAuthStateIfSystemCancelAuthSession
{
  if (@available(iOS 11.0, *)) {
    if (_authenticationSession && _authenticationSessionState == FBSDKAuthenticationSessionShowAlert) {
      _authenticationSessionState = FBSDKAuthenticationSessionCanceledBySystem;
    }
  }
}

- (BOOL)_isRequestingWebAuthenticationSession
{
  return !(_authenticationSessionState == FBSDKAuthenticationSessionNone
    || _authenticationSessionState == FBSDKAuthenticationSessionCanceledBySystem);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)openURL:(NSURL *)url
         sender:(nullable id<FBSDKURLOpening>)sender
        handler:(FBSDKSuccessBlock)handler
{
  _expectingBackground = YES;
  _pendingURLOpen = sender;
  __block id<FBSDKOperatingSystemVersionComparing> weakProcessInfo = _processInfo;
  dispatch_block_t block = ^{
    // Dispatch openURL calls to prevent hangs if we're inside the current app delegate's openURL flow already
    NSOperatingSystemVersion iOS10Version = { .majorVersion = 10, .minorVersion = 0, .patchVersion = 0 };
    if ([weakProcessInfo isOperatingSystemAtLeastVersion:iOS10Version]) {
      if (self.urlOpener) {
        if (@available(iOS 10.0, *)) {
          [self.urlOpener openURL:url options:@{} completionHandler:^(BOOL success) {
            handler(success, nil);
          }];
        }
      } else {
      #if FBTEST
        // self.urlOpener should only be nil in test
        NSString *message = @"Cannot login due to urlOpener being nil";
        NSDictionary *userInfo = @{FBSDKErrorLocalizedDescriptionKey : message};
        NSError *loginError = [self.errorFactory unknownErrorWithMessage:message
                                                                userInfo:userInfo];
        handler(false, loginError);
      #endif
      }
    } else if (handler) {
      BOOL opened = [self.urlOpener openURL:url];
      handler(opened, nil);
    }
  };
#if FBTEST
  block();
#else
  dispatch_async(dispatch_get_main_queue(), block);
#endif
}

#pragma clang diagnostic pop

- (void)openBridgeAPIRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
     useSafariViewController:(BOOL)useSafariViewController
          fromViewController:(UIViewController *)fromViewController
             completionBlock:(FBSDKBridgeAPIResponseBlock)completionBlock
{
  if (!request) {
    return;
  }
  NSError *error;
  NSURL *requestURL = [request requestURL:&error];
  if (!requestURL) {
    FBSDKBridgeAPIResponse *response = [self.bridgeAPIResponseFactory createResponseWithRequest:request error:error];
    completionBlock(response);
    return;
  }
  _pendingRequest = request;
  _pendingRequestCompletionBlock = [completionBlock copy];
  FBSDKSuccessBlock handler = [self _bridgeAPIRequestCompletionBlockWithRequest:request
                                                                     completion:completionBlock];

  if (useSafariViewController) {
    [self openURLWithSafariViewController:requestURL sender:nil fromViewController:fromViewController handler:handler];
  } else {
    [self openURL:requestURL sender:nil handler:handler];
  }
}

- (FBSDKSuccessBlock)_bridgeAPIRequestCompletionBlockWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                      completion:(FBSDKBridgeAPIResponseBlock)completionBlock
{
  return ^(BOOL openedURL, NSError *anError) {
    if (!openedURL) {
      self->_pendingRequest = nil;
      self->_pendingRequestCompletionBlock = nil;
      NSError *openedURLError;
      if ([request.scheme hasPrefix:FBSDKURLSchemeHTTP]) {
        openedURLError = [self.errorFactory errorWithCode:FBSDKErrorBrowserUnavailable
                                                 userInfo:nil
                                                  message:@"the app switch failed because the browser is unavailable"
                                          underlyingError:nil];
      } else {
        openedURLError = [self.errorFactory errorWithCode:FBSDKErrorAppVersionUnsupported
                                                 userInfo:nil
                                                  message:@"the app switch failed because the destination app is out of date"
                                          underlyingError:nil];
      }
      FBSDKBridgeAPIResponse *response = [self.bridgeAPIResponseFactory createResponseWithRequest:request
                                                                                            error:openedURLError];
      completionBlock(response);
      return;
    }
  };
}

- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(nullable id<FBSDKURLOpening>)sender
                     fromViewController:(nullable UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler
{
  if (![url.scheme hasPrefix:FBSDKURLSchemeHTTP]) {
    [self openURL:url sender:sender handler:handler];
    return;
  }

  _expectingBackground = NO;
  _pendingURLOpen = sender;
  if (@available(iOS 11.0, *)) {
    if ([sender isAuthenticationURL:url]) {
      self.sessionCompletionHandlerFromHandler = handler;
      [self openURLWithAuthenticationSession:url];
      return;
    }
  }

  // trying to dynamically load SFSafariViewController class
  // so for the cases when it is available we can send users through Safari View Controller flow
  // in cases it is not available regular flow will be selected
  Class SFSafariViewControllerClass = self.frameworkLoader.safariViewControllerClass;

  if (SFSafariViewControllerClass) {
    UIViewController *parent = fromViewController ?: [FBSDKInternalUtility.sharedUtility topMostViewController];
    if (parent == nil) {
      [self.logger logEntry:@"There are no valid ViewController to present SafariViewController with"];
      return;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSURLQueryItem *sfvcQueryItem = [[NSURLQueryItem alloc] initWithName:@"sfvc" value:@"1"];
    components.queryItems = [components.queryItems arrayByAddingObject:sfvcQueryItem];
    url = components.URL;
    FBSDKContainerViewController *container = [FBSDKContainerViewController new];
    container.delegate = self;
    if (parent.transitionCoordinator != nil) {
      // Wait until the transition is finished before presenting SafariVC to avoid a blank screen.
      [parent.transitionCoordinator animateAlongsideTransition:NULL completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Note SFVC init must occur inside block to avoid blank screen.
        self->_safariViewController = [[SFSafariViewControllerClass alloc] initWithURL:url];
        // Disable dismissing with edge pan gesture
        self->_safariViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self->_safariViewController performSelector:@selector(setDelegate:) withObject:self];
        [container displayChildController:self->_safariViewController];
        [parent presentViewController:container animated:YES completion:nil];
      }];
    } else {
      _safariViewController = [[SFSafariViewControllerClass alloc] initWithURL:url];
      // Disable dismissing with edge pan gesture
      _safariViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
      [_safariViewController performSelector:@selector(setDelegate:) withObject:self];
      [container displayChildController:_safariViewController];
      [parent presentViewController:container animated:YES completion:nil];
    }

    // Assuming Safari View Controller always opens
    if (handler) {
      handler(YES, nil);
    }
  } else {
    [self openURL:url sender:sender handler:handler];
  }
}

- (void)openURLWithAuthenticationSession:(NSURL *)url
{
  Class AuthenticationSessionClass = fbsdkdfl_ASWebAuthenticationSessionClass();

  if (!AuthenticationSessionClass) {
    AuthenticationSessionClass = fbsdkdfl_SFAuthenticationSessionClass();
  }

  if (AuthenticationSessionClass != nil) {
    if (_authenticationSession != nil) {
      [self.logger logEntry:@"There is already a request for authenticated session. Cancelling active SFAuthenticationSession before starting the new one."];
      [_authenticationSession cancel];
    }
    _authenticationSession = [[AuthenticationSessionClass alloc] initWithURL:url
                                                           callbackURLScheme:self.appURLSchemeProvider.appURLScheme
                                                           completionHandler:_authenticationSessionCompletionHandler];
    if (@available(iOS 13.0, *)) {
      if ([_authenticationSession respondsToSelector:@selector(setPresentationContextProvider:)]) {
        [_authenticationSession setPresentationContextProvider:self];
      }
    }
    _authenticationSessionState = FBSDKAuthenticationSessionStarted;
    [_authenticationSession start];
  }
}

- (void)setSessionCompletionHandlerFromHandler:(FBSDKSuccessBlock)handler
{
  __weak FBSDKBridgeAPI *weakSelf = self;
  _authenticationSessionCompletionHandler = ^(NSURL *aURL, NSError *error) {
    FBSDKBridgeAPI *strongSelf = weakSelf;
    BOOL didSucceed = (error == nil && aURL != nil);
    handler(didSucceed, error);
    if (didSucceed) {
      [strongSelf application:UIApplication.sharedApplication openURL:aURL sourceApplication:@"com.apple" annotation:nil];
    }
    strongSelf->_authenticationSession = nil;
    strongSelf->_authenticationSessionCompletionHandler = nil;
    strongSelf->_authenticationSessionState = FBSDKAuthenticationSessionNone;
  };
}

- (FBSDKAuthenticationCompletionHandler)sessionCompletionHandler
{
  return _authenticationSessionCompletionHandler;
}

#pragma mark -- SFSafariViewControllerDelegate

// This means the user tapped "Done" which we should treat as a cancellation.
- (void)safariViewControllerDidFinish:(UIViewController *)safariViewController
{
  if (_pendingURLOpen) {
    id<FBSDKURLOpening> pendingURLOpen = _pendingURLOpen;

    _pendingURLOpen = nil;

    [pendingURLOpen application:nil
                        openURL:nil
              sourceApplication:nil
                     annotation:nil];
  }
  [self _cancelBridgeRequest];
  _safariViewController = nil;
}

#pragma mark -- FBSDKContainerViewControllerDelegate

- (void)viewControllerDidDisappear:(FBSDKContainerViewController *)viewController animated:(BOOL)animated
{
  if (_safariViewController) {
    [self.logger logEntry:@"**ERROR**:\n The SFSafariViewController's parent view controller was dismissed.\n"
     "This can happen if you are triggering login from a UIAlertController. Instead, make sure your top most view "
     "controller will not be prematurely dismissed."];
    [self safariViewControllerDidFinish:_safariViewController];
  }
}

- (BOOL)_handleBridgeAPIResponseURL:(NSURL *)responseURL sourceApplication:(NSString *)sourceApplication
{
  NSObject<FBSDKBridgeAPIRequest> *request = _pendingRequest;
  FBSDKBridgeAPIResponseBlock completionBlock = _pendingRequestCompletionBlock;
  _pendingRequest = nil;
  _pendingRequestCompletionBlock = NULL;
  if (![responseURL.scheme isEqualToString:[self.appURLSchemeProvider appURLScheme]]) {
    return NO;
  }
  if (![responseURL.host isEqualToString:@"bridge"]) {
    return NO;
  }
  if (!request) {
    return NO;
  }
  if (!completionBlock) {
    return YES;
  }
  NSError *error;
  FBSDKBridgeAPIResponse *response = [self.bridgeAPIResponseFactory createResponseWithRequest:request
                                                                                  responseURL:responseURL
                                                                            sourceApplication:sourceApplication
                                                                                        error:&error];
  if (response) {
    completionBlock(response);
    return YES;
  } else if (error) {
    if (error.code == FBSDKErrorBridgeAPIResponse) {
      return NO;
    } else {
      completionBlock([self.bridgeAPIResponseFactory createResponseWithRequest:request error:error]);
      return YES;
    }
  } else {
    // This should not be reachable anymore.
    return NO;
  }
}

- (void)_cancelBridgeRequest
{
  if (_pendingRequest && _pendingRequestCompletionBlock) {
    _pendingRequestCompletionBlock([FBSDKBridgeAPIResponse bridgeAPIResponseCancelledWithRequest:_pendingRequest]);
  }
  _pendingRequest = nil;
  _pendingRequestCompletionBlock = NULL;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma mark - ASWebAuthenticationPresentationContextProviding
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0))
{
  return UIApplication.sharedApplication.keyWindow;
}
#pragma clang diagnostic pop

#pragma mark - Testability

#if DEBUG && FBTEST

- (void)setActive:(BOOL)isActive
{
  _active = isActive;
}

#endif

@end

#endif
