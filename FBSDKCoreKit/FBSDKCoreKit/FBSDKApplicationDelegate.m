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

#import "FBSDKApplicationDelegate.h"
#import "FBSDKApplicationDelegate+Internal.h"

#import <objc/runtime.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKConstants.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKError.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKTimeSpentData.h"

#if !TARGET_OS_TV
#import "FBSDKMeasurementEventListener.h"
#import "FBSDKContainerViewController.h"
#import "FBSDKProfile+Internal.h"
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSNotificationName const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#else

NSString *const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#endif

static NSString *const FBSDKAppLinkInboundEvent = @"fb_al_inbound";
static NSString *const FBSDKKitsBitmaskKey  = @"com.facebook.sdk.kits.bitmask";
static BOOL g_isSDKInitialized = NO;
static UIApplicationState _applicationState;

@implementation FBSDKApplicationDelegate
{
#if !TARGET_OS_TV
  FBSDKBridgeAPIRequest *_pendingRequest;
  FBSDKBridgeAPIResponseBlock _pendingRequestCompletionBlock;
  id<FBSDKURLOpening> _pendingURLOpen;
  id<FBSDKAuthenticationSession> _authenticationSession NS_AVAILABLE_IOS(11_0);
  FBSDKAuthenticationCompletionHandler _authenticationSessionCompletionHandler NS_AVAILABLE_IOS(11_0);
#endif
  NSHashTable<id<FBSDKApplicationObserving>> *_applicationObservers;
  BOOL _expectingBackground;
  BOOL _isRequestingSFAuthenticationSession;
  UIViewController *_safariViewController;
  BOOL _isDismissingSafariViewController;
  BOOL _isAppLaunched;
}

#pragma mark - Class Methods

+ (void)load
{
  if ([FBSDKSettings isAutoInitEnabled]) {
    // when the app becomes active by any means,  kick off the initialization.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initializeWithLaunchData:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
  }
}

// Initialize SDK listeners
// Don't call this function in any place else. It should only be called when the class is loaded.
+ (void)initializeWithLaunchData:(NSNotification *)note
{
  [self initializeSDK:note.userInfo];
  // Remove the observer
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidFinishLaunchingNotification
                                                object:nil];
}

+ (void)initializeSDK:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
  if (g_isSDKInitialized) {
    //  Do nothing if initialized already
    return;
  }

  g_isSDKInitialized = YES;

  FBSDKApplicationDelegate *delegate = [self sharedInstance];

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:delegate selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [defaultCenter addObserver:delegate selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

  [[FBSDKAppEvents singleton] registerNotifications];

  [delegate application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];

#if !TARGET_OS_TV
  // Register Listener for App Link measurement events
  [FBSDKMeasurementEventListener defaultListener];
#endif
  // Set the SourceApplication for time spent data. This is not going to update the value if the app has already launched.
  [FBSDKTimeSpentData setSourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                                   openURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
  // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
  [FBSDKTimeSpentData registerAutoResetSourceApplication];

  [FBSDKInternalUtility validateFacebookReservedURLSchemes];
}

+ (FBSDKApplicationDelegate *)sharedInstance
{
  static FBSDKApplicationDelegate *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[self alloc] init];
  });
  return _sharedInstance;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init]) != nil) {
    _applicationObservers = [[NSHashTable alloc] init];
  }
  return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIApplicationDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_0
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if (@available(iOS 9.0, *)) {
        return [self application:application
                         openURL:url
               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }

    return NO;
}
#endif

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if (sourceApplication != nil && ![sourceApplication isKindOfClass:[NSString class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Expected 'sourceApplication' to be NSString. Please verify you are passing in 'sourceApplication' from your app delegate (not the UIApplication* parameter). If your app delegate implements iOS 9's application:openURL:options:, you should pass in options[UIApplicationOpenURLOptionsSourceApplicationKey]. "
                                     userInfo:nil];
    }
    [FBSDKTimeSpentData setSourceApplication:sourceApplication openURL:url];

#if !TARGET_OS_TV
    id<FBSDKURLOpening> pendingURLOpen = _pendingURLOpen;

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
            }
        }
        completePendingOpenURLBlock();
    }

    if ([pendingURLOpen canOpenURL:url
                    forApplication:application
                 sourceApplication:sourceApplication
                        annotation:annotation]) {
        return YES;
    }
    if ([self _handleBridgeAPIResponseURL:url sourceApplication:sourceApplication]) {
        return YES;
    }

  BOOL handled = NO;
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
      if ([observer application:application
                        openURL:url
              sourceApplication:sourceApplication
                     annotation:annotation]) {
        handled = YES;
      }
    }
  }

  if (handled) {
    return YES;
  }
#endif
    [self _logIfAppLinkEvent:url];

    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([self isAppLaunched]) {
        return NO;
    }

    _isAppLaunched = YES;
    FBSDKAccessToken *cachedToken = [FBSDKSettings accessTokenCache].accessToken;
    [FBSDKAccessToken setCurrentAccessToken:cachedToken];
    // fetch app settings
    [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:NULL];
    // fetch gate keepers
    [FBSDKGateKeeperManager loadGateKeepers];

    if (FBSDKSettings.isAutoLogAppEventsEnabled) {
        [self _logSDKInitialize];
    }
#if !TARGET_OS_TV
    FBSDKProfile *cachedProfile = [FBSDKProfile fetchCachedProfile];
    [FBSDKProfile setCurrentProfile:cachedProfile];
#endif
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  BOOL handled = NO;
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
      if ([observer application:application didFinishLaunchingWithOptions:launchOptions]) {
        handled = YES;
      }
    }
  }

  return handled;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
  _isRequestingSFAuthenticationSession = NO;
  _active = NO;
  _expectingBackground = NO;

  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [observer applicationDidEnterBackground:notification.object];
    }
  }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Auto log basic events in case autoLogAppEventsEnabled is set
    if (FBSDKSettings.isAutoLogAppEventsEnabled) {
      [FBSDKAppEvents activateApp];
    }
    //  _expectingBackground can be YES if the caller started doing work (like login)
    // within the app delegate's lifecycle like openURL, in which case there
    // might have been a "didBecomeActive" event pending that we want to ignore.
    BOOL notExpectingBackground = !_expectingBackground && !_safariViewController && !_isDismissingSafariViewController && !_isRequestingSFAuthenticationSession;
    if (notExpectingBackground) {
        _active = YES;
#if !TARGET_OS_TV
        [_pendingURLOpen applicationDidBecomeActive:notification.object];
        [self _cancelBridgeRequest];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:FBSDKApplicationDidBecomeActiveNotification object:self];
    }

  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [observer applicationDidBecomeActive:notification.object];
    }
  }
}

#pragma mark - Internal Methods

#pragma mark -- (non-tvos)

#if !TARGET_OS_TV

- (void)openURL:(NSURL *)url sender:(id<FBSDKURLOpening>)sender handler:(FBSDKSuccessBlock)handler
{
    _expectingBackground = YES;
    _pendingURLOpen = sender;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Dispatch openURL calls to prevent hangs if we're inside the current app delegate's openURL flow already
        NSOperatingSystemVersion iOS10Version = { .majorVersion = 10, .minorVersion = 0, .patchVersion = 0 };
        if ([FBSDKInternalUtility isOSRunTimeVersionAtLeast:iOS10Version]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    handler(success, nil);
                }];
            }
        } else {
            BOOL opened = [[UIApplication sharedApplication] openURL:url];

            if ([url.scheme hasPrefix:@"http"] && !opened) {
                NSOperatingSystemVersion iOS8Version = { .majorVersion = 8, .minorVersion = 0, .patchVersion = 0 };
                if (![FBSDKInternalUtility isOSRunTimeVersionAtLeast:iOS8Version]) {
                    // Safari openURL calls can wrongly return NO on iOS 7 so manually overwrite that case to YES.
                    // Otherwise we would rather trust in the actual result of openURL
                    opened = YES;
                }
            }
            if (handler) {
                handler(opened, nil);
            }
        }
    });
}

  return handled;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [observer applicationDidEnterBackground:notification.object];
    }
  }
}

- (void)addObserver:(id<FBSDKApplicationObserving>)observer
{
  if (![_applicationObservers containsObject:observer]) {
    [_applicationObservers addObject:observer];
  }
}

- (void)removeObserver:(id<FBSDKApplicationObserving>)observer
{
  if ([_applicationObservers containsObject:observer]) {
    [_applicationObservers removeObject:observer];
  }
}

- (void)_openURLWithAuthenticationSession:(NSURL *)url
{
  // Auto log basic events in case autoLogAppEventsEnabled is set
  if (FBSDKSettings.isAutoLogAppEventsEnabled) {
    [FBSDKAppEvents activateApp];
  }

  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [observer applicationDidBecomeActive:notification.object];
    }
  }
}

#pragma mark - Internal Methods

#pragma mark - FBSDKApplicationObserving

- (void)addObserver:(id<FBSDKApplicationObserving>)observer
{
  if (![_applicationObservers containsObject:observer]) {
    [_applicationObservers addObject:observer];
  }
}

- (void)removeObserver:(id<FBSDKApplicationObserving>)observer
{
  if ([_applicationObservers containsObject:observer]) {
    [_applicationObservers removeObject:observer];
  }
}

+ (UIApplicationState)applicationState
{
  return _applicationState;
}

#pragma mark - Helper Methods

- (void)_logIfAppLinkEvent:(NSURL *)url
{
  if (!url) {
    return;
  }
  NSDictionary<NSString *, NSString *> *params = [FBSDKInternalUtility dictionaryWithQueryString:url.query];
  NSString *applinkDataString = params[@"al_applink_data"];
  if (!applinkDataString) {
    return;
  }

  NSDictionary *applinkData = [FBSDKInternalUtility objectForJSONString:applinkDataString error:NULL];
  if (!applinkData) {
    return;
  }

  NSString *targetURLString = applinkData[@"target_url"];
  NSURL *targetURL = [targetURLString isKindOfClass:[NSString class]] ? [NSURL URLWithString:targetURLString] : nil;

  NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
  [FBSDKInternalUtility dictionary:logData setObject:targetURL.absoluteString forKey:@"targetURL"];
  [FBSDKInternalUtility dictionary:logData setObject:targetURL.host forKey:@"targetURLHost"];

  NSDictionary *refererData = applinkData[@"referer_data"];
  if (refererData) {
    [FBSDKInternalUtility dictionary:logData setObject:refererData[@"target_url"] forKey:@"referralTargetURL"];
    [FBSDKInternalUtility dictionary:logData setObject:refererData[@"url"] forKey:@"referralURL"];
    [FBSDKInternalUtility dictionary:logData setObject:refererData[@"app_name"] forKey:@"referralAppName"];
  }
  [FBSDKInternalUtility dictionary:logData setObject:url.absoluteString forKey:@"inputURL"];
  [FBSDKInternalUtility dictionary:logData setObject:url.scheme forKey:@"inputURLScheme"];

  [FBSDKAppEvents logInternalEvent:FBSDKAppLinkInboundEvent
                        parameters:logData
                isImplicitlyLogged:YES];
}

- (void)_logSDKInitialize
{
  NSDictionary *metaInfo = [NSDictionary dictionaryWithObjects:@[@"login_lib_included",
                                                                 @"marketing_lib_included",
                                                                 @"messenger_lib_included",
                                                                 @"places_lib_included",
                                                                 @"share_lib_included",
                                                                 @"tv_lib_included"]
                                                       forKeys:@[@"FBSDKLoginManager",
                                                                 @"FBSDKAutoLog",
                                                                 @"FBSDKMessengerButton",
                                                                 @"FBSDKPlacesManager",
                                                                 @"FBSDKShareDialog",
                                                                 @"FBSDKTVInterfaceFactory"]];

  NSInteger bitmask = 0;
  NSInteger bit = 0;
  NSMutableDictionary<NSString *, NSNumber *> *params = NSMutableDictionary.new;
  params[@"core_lib_included"] = @1;
  for (NSString *className in metaInfo.allKeys) {
    NSString *keyName = [metaInfo objectForKey:className];
    if (objc_lookUpClass([className UTF8String])) {
      params[keyName] = @1;
      bitmask |=  1 << bit;
    }
    bit++;
  }

  NSInteger existingBitmask = [[NSUserDefaults standardUserDefaults] integerForKey:FBSDKKitsBitmaskKey];
  if (existingBitmask != bitmask) {
    [[NSUserDefaults standardUserDefaults] setInteger:bitmask forKey:FBSDKKitsBitmaskKey];
    [FBSDKAppEvents logInternalEvent:@"fb_sdk_initialize"
                          parameters:params
                  isImplicitlyLogged:NO];
  }
}

+ (BOOL)isSDKInitialized
{
  return g_isSDKInitialized;
}

// Wrapping this makes it mockable and enables testability
- (BOOL)isAppLaunched {
  return _isAppLaunched;
}

@end
