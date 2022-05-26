/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKApplicationDelegate.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>

#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKBridgeAPI+Internal.h"
#import "FBSDKCoreKitComponents.h"
#import "FBSDKCoreKitConfigurator.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKMeasurementEventListener.h"

static NSString *const FBSDKAppLinkInboundEvent = @"fb_al_inbound";
static NSString *const FBSDKKitsBitmaskKey = @"com.facebook.sdk.kits.bitmask";
static BOOL hasInitializeBeenCalled = NO;
static UIApplicationState _applicationState;

@interface FBSDKApplicationDelegate ()

@property (nonnull, nonatomic, readwrite) FBSDKCoreKitComponents *components;
@property (nonnull, nonatomic, readwrite) id<FBSDKCoreKitConfiguring> configurator;
@property (nonnull, nonatomic, readwrite) NSHashTable<id<FBSDKApplicationObserving>> *applicationObservers;
@property (nonatomic) BOOL isAppLaunched;

@end

@implementation FBSDKApplicationDelegate

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
  FBSDKCoreKitComponents *components = FBSDKCoreKitComponents.defaultComponents;
  return [self initWithComponents:components
                     configurator:[[FBSDKCoreKitConfigurator alloc] initWithComponents:components]];
}

- (instancetype)initWithComponents:(FBSDKCoreKitComponents *)components
                      configurator:(id<FBSDKCoreKitConfiguring>)configurator
{
  if ((self = [super init])) {
    _components = components;
    _configurator = configurator;
    _applicationObservers = [NSHashTable new];
  }

  return self;
}

- (void)initializeSDK
{
  [self initializeSDKWithLaunchOptions:@{}];
}

- (void)initializeSDKWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  if (hasInitializeBeenCalled) {
    return;
  } else {
    hasInitializeBeenCalled = YES;
  }

  //
  // DO NOT MOVE THIS CALL
  // Dependencies MUST be configured before they are invoked
  //
  [self.configurator performConfiguration];

  [self logInitialization];
  [self addObservers];
  [self.components.appEvents startObservingApplicationLifecycleNotifications];
  [self application:UIApplication.sharedApplication didFinishLaunchingWithOptions:launchOptions];
  [self handleDeferredActivationIfNeeded];
  [self enableInstrumentation];

#if !TARGET_OS_TV
  [self logBackgroundRefreshStatus];
  [self initializeAppLink];
#endif

  [self configureSourceApplicationWithLaunchOptions:launchOptions];
}

#if !TARGET_OS_TV
- (void)initializeAppLink
{
  [self initializeMeasurementListener];
  [self _logIfAutoAppLinkEnabled];
}

#endif

- (void)handleDeferredActivationIfNeeded
{
  // If sdk initialization is deferred until after the applicationDidBecomeActive notification is received, then we need to manually perform this work in case it hasn't happened at all.
  if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
    [self applicationDidBecomeActive:nil];
  }
}

- (void)configureSourceApplicationWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
  // Set the SourceApplication for time spent data. This is not going to update the value if the app has already launched.
  [self.components.appEvents setSourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                                          openURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
  // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
  [self.components.appEvents registerAutoResetSourceApplication];
  [self.components.internalUtility validateFacebookReservedURLSchemes];
}

#if !TARGET_OS_TV
- (void)initializeMeasurementListener
{
  // Register Listener for App Link measurement events
  FBSDKMeasurementEventListener *listener = [[FBSDKMeasurementEventListener alloc] initWithEventLogger:self.components.appEvents
                                                                              sourceApplicationTracker:self.components.appEvents];
  [listener registerForAppLinkMeasurementEvents];
}

#endif

#if !TARGET_OS_TV
- (void)logBackgroundRefreshStatus
{
  [self.components.backgroundEventLogger logBackgroundRefreshStatus:[UIApplication.sharedApplication backgroundRefreshStatus]];
}

#endif

- (void)logInitialization
{
  [self.components.settings logWarnings];
  [self.components.settings logIfSDKSettingsChanged];
  [self.components.settings recordInstall];
}

- (void)enableInstrumentation
{
  [self.components.featureChecker checkFeature:FBSDKFeatureInstrument completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKInstrumentManager.shared enable];
    }
  }];
}

- (void)addObservers
{
  [self.components.notificationCenter addObserver:self
                                         selector:@selector(applicationDidEnterBackground:)
                                             name:UIApplicationDidEnterBackgroundNotification
                                           object:nil];
  [self.components.notificationCenter addObserver:self
                                         selector:@selector(applicationDidBecomeActive:)
                                             name:UIApplicationDidBecomeActiveNotification
                                           object:nil];
  [self.components.notificationCenter addObserver:self
                                         selector:@selector(applicationWillResignActive:)
                                             name:UIApplicationWillResignActiveNotification
                                           object:nil];
#if !TARGET_OS_TV
  [self addObserver:FBSDKBridgeAPI.sharedInstance];
#endif
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
{
  if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    return NO;
  }
  return [self application:application openURL:userActivity.webpageURL options:@{}];
}

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

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation
{
  if (sourceApplication != nil && ![sourceApplication isKindOfClass:NSString.class]) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Expected 'sourceApplication' to be NSString. Please verify you are passing in 'sourceApplication' from your app delegate (not the UIApplication* parameter). If your app delegate implements iOS 9's application:openURL:options:, you should pass in options[UIApplicationOpenURLOptionsSourceApplicationKey]. "
                                 userInfo:nil];
  }
  [self.components.appEvents setSourceApplication:sourceApplication openURL:url];

#if !TARGET_OS_TV
  [self.components.featureChecker checkFeature:FBSDKFeatureAEM completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBAEMReporter setCatalogMatchingEnabled:[self.components.featureChecker isEnabled:FBSDKFeatureAEMCatalogMatching]];
      [FBAEMReporter setConversionFilteringEnabled:[self.components.featureChecker isEnabled:FBSDKFeatureAEMConversionFiltering]];
      [FBAEMReporter enable];
      [FBAEMReporter handleURL:url];
    }
  }];
#endif

  BOOL handled = NO;
  NSArray<id<FBSDKApplicationObserving>> *observers = [self.applicationObservers allObjects];
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

// MARK: Finish Launching

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<NSString *, id> *)launchOptions
{
  if (self.isAppLaunched) {
    return NO;
  }

  if (!hasInitializeBeenCalled) {
    [self initializeSDKWithLaunchOptions:launchOptions];

    self.isAppLaunched = YES;

    [self initializeTokenCache];
    [self fetchServerConfiguration];

    if (self.components.settings.isAutoLogAppEventsEnabled) {
      [self _logSDKInitialize];
    }

  #if !TARGET_OS_TV
    [self initializeProfile];
    [self checkAuthentication];
  #endif

    return [self notifyLaunchObserversWithApplication:application
                                        launchOptions:launchOptions];
  } else {
    return NO;
  }
}

- (void)initializeTokenCache
{
  FBSDKAccessToken *cachedToken = [[self.components.accessTokenWallet tokenCache] accessToken];
  [self.components.accessTokenWallet setCurrentAccessToken:cachedToken];
}

- (void)fetchServerConfiguration
{
  [self.components.serverConfigurationProvider loadServerConfigurationWithCompletionBlock:NULL];
}

#if !TARGET_OS_TV
- (void)initializeProfile
{
  FBSDKProfile *cachedProfile = [self.components.profileSetter fetchCachedProfile];
  [self.components.profileSetter setCurrentProfile:cachedProfile];
}

#endif

#if !TARGET_OS_TV
- (void)checkAuthentication
{
  FBSDKAuthenticationToken *cachedAuthToken = [[self.components.authenticationTokenWallet tokenCache] authenticationToken];
  [self.components.authenticationTokenWallet setCurrentAuthenticationToken:cachedAuthToken];

  [FBSDKAuthenticationStatusUtility checkAuthenticationStatus];
}

#endif

- (BOOL)notifyLaunchObserversWithApplication:(UIApplication *)application
                               launchOptions:(NSDictionary<NSString *, id> *)launchOptions
{
  NSArray<id<FBSDKApplicationObserving>> *observers = [self.applicationObservers allObjects];
  BOOL someObserverHandledLaunch = NO;
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
      if ([observer application:application didFinishLaunchingWithOptions:launchOptions]) {
        someObserverHandledLaunch = YES;
      }
    }
  }

  return someObserverHandledLaunch;
}

// MARK: Entering Background

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
  self.applicationState = UIApplicationStateBackground;
  NSArray<id<FBSDKApplicationObserving>> *observers = [self.applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [observer applicationDidEnterBackground:notification.object];
    }
  }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  self.applicationState = UIApplicationStateActive;
  // Auto log basic events in case autoLogAppEventsEnabled is set
  if (self.components.settings.isAutoLogAppEventsEnabled) {
    [self.components.appEvents activateApp];
  }
#if !TARGET_OS_TV
  [self.components.skAdNetworkReporter checkAndRevokeTimer];
#endif

  NSArray<id<FBSDKApplicationObserving>> *observers = [self.applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [observer applicationDidBecomeActive:notification.object];
    }
  }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
  self.applicationState = UIApplicationStateInactive;
  NSArray<id<FBSDKApplicationObserving>> *const observers = [self.applicationObservers copy];
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
  if (![self.applicationObservers containsObject:observer]) {
    [self.applicationObservers addObject:observer];
  }
}

- (void)removeObserver:(id<FBSDKApplicationObserving>)observer
{
  if ([self.applicationObservers containsObject:observer]) {
    [self.applicationObservers removeObject:observer];
  }
}

- (void)setApplicationState:(UIApplicationState)state
{
  _applicationState = state;
  [self.components.appEvents setApplicationState:state];
}

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
  NSURL *targetURL = [targetURLString isKindOfClass:NSString.class] ? [NSURL URLWithString:targetURLString] : nil;

  NSMutableDictionary<FBSDKAppEventParameterName, id> *logData = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:logData setObject:targetURL.absoluteString forKey:@"targetURL"];
  [FBSDKTypeUtility dictionary:logData setObject:targetURL.host forKey:@"targetURLHost"];

  NSDictionary<NSString *, id> *refererData = applinkData[@"referer_data"];
  if (refererData) {
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"target_url"] forKey:@"referralTargetURL"];
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"url"] forKey:@"referralURL"];
    [FBSDKTypeUtility dictionary:logData setObject:refererData[@"app_name"] forKey:@"referralAppName"];
  }
  [FBSDKTypeUtility dictionary:logData setObject:url.absoluteString forKey:@"inputURL"];
  [FBSDKTypeUtility dictionary:logData setObject:url.scheme forKey:@"inputURLScheme"];

  [self.components.appEvents logInternalEvent:FBSDKAppLinkInboundEvent
                                   parameters:logData
                           isImplicitlyLogged:YES];
}

- (void)_logSDKInitialize
{
  NSDictionary<NSString *, id> *metaInfo = @{
    @"FBSDKLoginManager" : @"login_lib_included",
    @"FBSDKAutoLog" : @"marketing_lib_included",
    @"FBSDKMessengerButton" : @"messenger_lib_included",
    @"FBSDKPlacesManager" : @"places_lib_included",
    @"FBSDKShareDialog" : @"share_lib_included",
    @"FBSDKTVInterfaceFactory" : @"tv_lib_included",
  };

  NSInteger bitmask = 0;
  NSInteger bit = 0;
  NSMutableDictionary<FBSDKAppEventParameterName, id> *params = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:params setObject:@1 forKey:@"core_lib_included"];
  for (NSString *className in metaInfo.allKeys) {
    NSString *keyName = [FBSDKTypeUtility dictionary:metaInfo objectForKey:className ofType:NSObject.class];
    if (objc_lookUpClass([className UTF8String])) {
      [FBSDKTypeUtility dictionary:params setObject:@1 forKey:keyName];
      bitmask |= 1 << bit;
    }
    bit++;
  }

  NSInteger existingBitmask = [self.components.defaultDataStore integerForKey:FBSDKKitsBitmaskKey];
  if (existingBitmask != bitmask) {
    [self.components.defaultDataStore setInteger:bitmask forKey:FBSDKKitsBitmaskKey];
    [self.components.appEvents logInternalEvent:@"fb_sdk_initialize"
                                     parameters:params
                             isImplicitlyLogged:NO];
  }
}

- (void)_logIfAutoAppLinkEnabled
{
#if !TARGET_OS_TV
  NSNumber *enabled = [NSBundle.mainBundle objectForInfoDictionaryKey:@"FBSDKAutoAppLinkEnabled"];
  if (enabled.boolValue) {
    NSMutableDictionary<FBSDKAppEventParameterName, id> *params = [NSMutableDictionary new];
    if (![FBSDKAppLinkUtility isMatchURLScheme:[NSString stringWithFormat:@"fb%@", self.components.settings.appID]]) {
      NSString *warning = @"You haven't set the Auto App Link URL scheme: fb<YOUR APP ID>";
      [FBSDKTypeUtility dictionary:params setObject:warning forKey:@"SchemeWarning"];
      NSLog(@"%@", warning);
    }
    [self.components.appEvents logInternalEvent:@"fb_auto_applink" parameters:params isImplicitlyLogged:YES];
  }
#endif
}

// MARK: - Testability

#if DEBUG

+ (void)resetHasInitializeBeenCalled
{
  hasInitializeBeenCalled = NO;
}

- (void)resetApplicationObserverCache
{
  _applicationObservers = [NSHashTable new];
}

#endif

@end
