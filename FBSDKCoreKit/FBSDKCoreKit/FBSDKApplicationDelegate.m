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
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKBridgeAPI+ApplicationObserving.h"
#import "FBSDKConstants.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKError.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKEventLogger.h"
#import "FBSDKFeatureManager+FeatureChecking.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestPiggybackManager+Internal.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger+Logging.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager+ServerConfigurationProviding.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKTokenCache.h"
#import "GraphAPI/FBSDKGraphRequest.h"
#import "NSBundle+InfoDictionaryProviding.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"

#if !TARGET_OS_TV
 #import "FBSDKAppLinkUtility+Internal.h"
 #import "FBSDKCodelessIndexer+Internal.h"
 #import "FBSDKContainerViewController.h"
 #import "FBSDKMeasurementEventListener.h"
 #import "FBSDKProfile+Internal.h"
 #import "FBSDKSKAdNetworkReporter+Internal.h"
 #import "FBSDKURLOpener.h"
 #import "FBSDKWebDialogView.h"
 #import "FBSDKWebViewFactory.h"
 #import "UIApplication+URLOpener.h"
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSNotificationName const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#else

NSString *const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#endif

static NSString *const FBSDKAppLinkInboundEvent = @"fb_al_inbound";
static NSString *const FBSDKKitsBitmaskKey = @"com.facebook.sdk.kits.bitmask";
static BOOL hasInitializeBeenCalled = NO;
static UIApplicationState _applicationState;

@implementation FBSDKApplicationDelegate
{
  NSHashTable<id<FBSDKApplicationObserving>> *_applicationObservers;
  BOOL _isAppLaunched;
  id<FBSDKNotificationObserving> _notificationObserver;
  Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> _tokenWallet;
  Class<FBSDKSettingsLogging> _settings;
}

#pragma mark - Class Methods

+ (void)initializeSDK:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  [self.sharedInstance initializeSDKWithLaunchOptions:launchOptions];
}

+ (FBSDKApplicationDelegate *)sharedInstance
{
  static FBSDKApplicationDelegate *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [self new];
  });
  return _sharedInstance;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  return [self initWithNotificationObserver:NSNotificationCenter.defaultCenter
                                tokenWallet:FBSDKAccessToken.class
                                   settings:FBSDKSettings.class];
}

- (instancetype)initWithNotificationObserver:(id<FBSDKNotificationObserving>)observer
                                 tokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                                    settings:(Class<FBSDKSettingsLogging>)settings
{
  if ((self = [super init]) != nil) {
    _applicationObservers = [[NSHashTable alloc] init];
    _notificationObserver = observer;
    _tokenWallet = tokenWallet;
    _settings = settings;
  }
  return self;
}

- (void)initializeSDKWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  if (hasInitializeBeenCalled) {
    // Do nothing if initialized already
    return;
  } else {
    hasInitializeBeenCalled = YES;
  }
  [self configureDependencies];

  Class<FBSDKSettingsLogging> const settingsLogger = self.settings;
  [settingsLogger logWarnings];
  [settingsLogger logIfSDKSettingsChanged];
  [settingsLogger recordInstall];

  [self addObservers];

  [[FBSDKAppEvents singleton] registerNotifications];

  [self application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];

  // In case of sdk autoInit enabled sdk expects one appDidBecomeActive notification after app launch and has some logic to ignore it.
  // if sdk autoInit disabled app won't receive appDidBecomeActive on app launch and will ignore the first one it gets instead of handling it.
  // Send first applicationDidBecomeActive notification manually
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    [self applicationDidBecomeActive:nil];
  }

  [FBSDKFeatureManager checkFeature:FBSDKFeatureInstrument completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKInstrumentManager enable];
    }
  }];

#if !TARGET_OS_TV
  // Register Listener for App Link measurement events
  [FBSDKMeasurementEventListener defaultListener];
  [self _logIfAutoAppLinkEnabled];
#endif
  // Set the SourceApplication for time spent data. This is not going to update the value if the app has already launched.
  [FBSDKTimeSpentData setSourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                                   openURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
  // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
  [FBSDKTimeSpentData registerAutoResetSourceApplication];

  [FBSDKInternalUtility validateFacebookReservedURLSchemes];
}

- (void)addObservers
{
  id<FBSDKNotificationObserving> const observer = self.notificationObserver;
  [observer addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
  [observer addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
  [observer addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
#if !TARGET_OS_TV
  [self addObserver:FBSDKBridgeAPI.sharedInstance];
#endif
}

- (void)dealloc
{
  [_notificationObserver removeObserver:self];
}

- (id<FBSDKNotificationObserving>)notificationObserver
{
  return _notificationObserver;
}

- (Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
{
  return _tokenWallet;
}

- (Class<FBSDKSettingsLogging>)settings
{
  return _settings;
}

#pragma mark - UIApplicationDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED> __IPHONE_9_0
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
  return [self application:application
                    openURL:url
          sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                 annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];

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

  [self _logIfAppLinkEvent:url];

  return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  if (_isAppLaunched) {
    return NO;
  }

  if (!hasInitializeBeenCalled) {
    [self initializeSDKWithLaunchOptions:launchOptions];
  }

  _isAppLaunched = YES;

  // Retrieve cached tokens
  FBSDKAccessToken *cachedToken = [[self.tokenWallet tokenCache] accessToken];
  [self.tokenWallet setCurrentAccessToken:cachedToken];

  // fetch app settings
  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:NULL];

  if (FBSDKSettings.isAutoLogAppEventsEnabled) {
    [self _logSDKInitialize];
  }
#if !TARGET_OS_TV
  FBSDKProfile *cachedProfile = [FBSDKProfile fetchCachedProfile];
  [FBSDKProfile setCurrentProfile:cachedProfile];

  FBSDKAuthenticationToken *cachedAuthToken = FBSDKAuthenticationToken.tokenCache.authenticationToken;
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:cachedAuthToken];
  [FBSDKAuthenticationStatusUtility checkAuthenticationStatus];
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
  [self setApplicationState:UIApplicationStateBackground];
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [observer applicationDidEnterBackground:notification.object];
    }
  }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  [self setApplicationState:UIApplicationStateActive];
  // Auto log basic events in case autoLogAppEventsEnabled is set
  if (FBSDKSettings.isAutoLogAppEventsEnabled) {
    [FBSDKAppEvents activateApp];
  }
#if !TARGET_OS_TV
  [FBSDKSKAdNetworkReporter checkAndRevokeTimer];
#endif

  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [observer applicationDidBecomeActive:notification.object];
    }
  }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
  [self setApplicationState:UIApplicationStateInactive];
  NSArray<id<FBSDKApplicationObserving>> *const observers = [_applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationWillResignActive:)]) {
      [observer applicationWillResignActive:notification.object];
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

- (void)setApplicationState:(UIApplicationState)state
{
  _applicationState = state;
  [FBSDKAppEvents setApplicationState:state];
}

#pragma mark - Helper Methods

- (void)_logIfAppLinkEvent:(NSURL *)url
{
  if (!url) {
    return;
  }
  NSDictionary<NSString *, NSString *> *params = [FBSDKBasicUtility dictionaryWithQueryString:url.query];
  NSString *applinkDataString = params[@"al_applink_data"];
  if (!applinkDataString) {
    return;
  }

  NSDictionary<id, id> *applinkData = [FBSDKTypeUtility dictionaryValue:[FBSDKBasicUtility objectForJSONString:applinkDataString error:NULL]];
  if (!applinkData) {
    return;
  }

  NSString *targetURLString = applinkData[@"target_url"];
  NSURL *targetURL = [targetURLString isKindOfClass:[NSString class]] ? [NSURL URLWithString:targetURLString] : nil;

  NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
  [FBSDKTypeUtility dictionary:logData setObject:targetURL.absoluteString forKey:@"targetURL"];
  [FBSDKTypeUtility dictionary:logData setObject:targetURL.host forKey:@"targetURLHost"];

  NSDictionary *refererData = applinkData[@"referer_data"];
  if (refererData) {
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"target_url"] forKey:@"referralTargetURL"];
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"url"] forKey:@"referralURL"];
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"app_name"] forKey:@"referralAppName"];
  }
  [FBSDKTypeUtility dictionary:logData setObject:url.absoluteString forKey:@"inputURL"];
  [FBSDKTypeUtility dictionary:logData setObject:url.scheme forKey:@"inputURLScheme"];

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
  [FBSDKTypeUtility dictionary:params setObject:@1 forKey:@"core_lib_included"];
  for (NSString *className in metaInfo.allKeys) {
    NSString *keyName = [FBSDKTypeUtility dictionary:metaInfo objectForKey:className ofType:NSObject.class];
    if (objc_lookUpClass([className UTF8String])) {
      [FBSDKTypeUtility dictionary:params setObject:@1 forKey:keyName];
      bitmask |= 1 << bit;
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

- (void)_logIfAutoAppLinkEnabled
{
#if !TARGET_OS_TV
  NSNumber *enabled = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FBSDKAutoAppLinkEnabled"];
  if (enabled.boolValue) {
    NSMutableDictionary<NSString *, NSString *> *params = [[NSMutableDictionary alloc] init];
    if (![FBSDKAppLinkUtility isMatchURLScheme:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]]) {
      NSString *warning = @"You haven't set the Auto App Link URL scheme: fb<YOUR APP ID>";
      [FBSDKTypeUtility dictionary:params setObject:warning forKey:@"SchemeWarning"];
      NSLog(@"%@", warning);
    }
    [FBSDKAppEvents logInternalEvent:@"fb_auto_applink" parameters:params isImplicitlyLogged:YES];
  }
#endif
}

+ (BOOL)isSDKInitialized
{
  return hasInitializeBeenCalled;
}

- (void)configureDependencies
{
  id<FBSDKGraphRequestProviding> graphRequestProvider = [FBSDKGraphRequestFactory new];
  id<FBSDKDataPersisting> store = NSUserDefaults.standardUserDefaults;
  [FBSDKGraphRequest setCurrentAccessTokenStringProvider:FBSDKAccessToken.class];
  [FBSDKGraphRequestConnection setCanMakeRequests];
  [FBSDKAppEvents configureWithGateKeeperManager:[FBSDKGateKeeperManager class]
                  appEventsConfigurationProvider:[FBSDKAppEventsConfigurationManager class]
                     serverConfigurationProvider:[FBSDKServerConfigurationManager class]
                            graphRequestProvider:graphRequestProvider
                                  featureChecker:[FBSDKFeatureManager class]
                                           store:store
                                          logger:[FBSDKLogger class]];
  [FBSDKGateKeeperManager configureWithSettings:FBSDKSettings.class
                                requestProvider:graphRequestProvider
                             connectionProvider:[FBSDKGraphRequestConnectionFactory new]
                                          store:store];
  FBSDKTokenCache *tokenCache = [FBSDKTokenCache new];
  [FBSDKAccessToken setTokenCache:tokenCache];
  [FBSDKAccessToken setConnectionFactory:[FBSDKGraphRequestConnectionFactory new]];
  [FBSDKAuthenticationToken setTokenCache:tokenCache];
  [FBSDKSettings configureWithStore:store
     appEventsConfigurationProvider:FBSDKAppEventsConfigurationManager.class
             infoDictionaryProvider:NSBundle.mainBundle
                        eventLogger:[FBSDKEventLogger new]];
  [FBSDKInternalUtility configureWithInfoDictionaryProvider:NSBundle.mainBundle];
  [FBSDKGraphRequestPiggybackManager configureWithTokenWallet:FBSDKAccessToken.class];
  [FBSDKAppEventsConfigurationManager configureWithStore:store];
#if !TARGET_OS_TV
  [FBSDKAppLinkUtility configureWithRequestProvider:[FBSDKGraphRequestFactory new]
                             infoDictionaryProvider:NSBundle.mainBundle];
  [FBSDKCodelessIndexer configureWithRequestProvider:[FBSDKGraphRequestFactory new]];
  if (@available(iOS 14.0, *)) {
    [FBSDKSKAdNetworkReporter configureWithRequestProvider:[FBSDKGraphRequestFactory new]
                                                     store:store];
  }
  [FBSDKProfile configureWithStore:store
               accessTokenProvider:FBSDKAccessToken.class];
  [FBSDKWebDialogView configureWithWebViewProvider:[FBSDKWebViewFactory new]
                                         urlOpener:UIApplication.sharedApplication];
#endif
}

// MARK: - Testability

#if DEBUG
 #if FBSDKTEST

+ (void)resetHasInitializeBeenCalled
{
  hasInitializeBeenCalled = NO;
}

- (BOOL)isAppLaunched
{
  return _isAppLaunched;
}

- (void)setIsAppLaunched:(BOOL)isLaunched
{
  _isAppLaunched = isLaunched;
}

- (NSHashTable<id<FBSDKApplicationObserving>> *)applicationObservers
{
  return _applicationObservers;
}

- (void)resetApplicationObserverCache
{
  _applicationObservers = [NSHashTable new];
}

 #endif
#endif

@end
