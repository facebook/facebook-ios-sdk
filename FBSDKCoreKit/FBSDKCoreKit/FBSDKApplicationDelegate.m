/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKApplicationDelegate.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>

#import "FBSDKATEPublisherFactory.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAccessTokenExpirer.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateFactory.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppLinkFactory.h"
#import "FBSDKAppLinkNavigation+Internal.h"
#import "FBSDKAppLinkTargetFactory.h"
#import "FBSDKAppLinkURLFactory.h"
#import "FBSDKApplicationLifecycleObserving.h"
#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKBridgeAPI+Internal.h"
#import "FBSDKBridgeAPIRequest+Private.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKCrashObserver.h"
#import "FBSDKCrashShield+Internal.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKError+Internal.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKErrorFactory.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestPiggybackManager+Internal.h"
#import "FBSDKImpressionLoggerFactory.h"
#import "FBSDKImpressionLoggingButton+Internal.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKKeychainStoreFactory.h"
#import "FBSDKLogger.h"
#import "FBSDKLoggerFactory.h"
#import "FBSDKLogging.h"
#import "FBSDKPaymentObserver.h"
#import "FBSDKPaymentProductRequestorFactory.h"
#import "FBSDKProfileProtocols.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKSuggestedEventsIndexer.h"
#import "FBSDKSwizzler+Swizzling.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKTokenCache.h"
#import "FBSDKURLSessionProxyFactory.h"
#import "FBSDKUserDataStore.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSProcessInfo+Protocols.h"
#import "NSURLSession+Protocols.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"

#if !TARGET_OS_TV
 #import "FBSDKAEMNetworker.h"
 #import "FBSDKAppLinkUtility+Internal.h"
 #import "FBSDKBackgroundEventLogger.h"
 #import "FBSDKBackgroundEventLogging.h"
 #import "FBSDKCodelessIndexer+Internal.h"
 #import "FBSDKContainerViewController.h"
 #import "FBSDKFeatureExtractor.h"
 #import "FBSDKMeasurementEvent+Internal.h"
 #import "FBSDKMeasurementEventListener.h"
 #import "FBSDKMetadataIndexer.h"
 #import "FBSDKModelManager.h"
 #import "FBSDKProductRequestFactory.h"
 #import "FBSDKProfile+Internal.h"
 #import "FBSDKSKAdNetworkReporter+Internal.h"
 #import "FBSDKURL+Internal.h"
 #import "FBSDKURLOpener.h"
 #import "FBSDKWebDialogView.h"
 #import "FBSDKWebViewFactory.h"
 #import "SKAdNetwork+ConversionValueUpdating.h"
 #import "UIApplication+URLOpener.h"
#endif

static NSString *const FBSDKAppLinkInboundEvent = @"fb_al_inbound";
static NSString *const FBSDKKitsBitmaskKey = @"com.facebook.sdk.kits.bitmask";
static BOOL hasInitializeBeenCalled = NO;
static UIApplicationState _applicationState;

@interface FBSDKApplicationDelegate ()

@property (nonnull, nonatomic, readonly) id<FBSDKFeatureChecking> featureChecker;
@property (nonnull, nonatomic, readonly) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> tokenWallet;
@property (nonnull, nonatomic, readonly) id<FBSDKSettingsLogging, FBSDKSettings> settings;
@property (nonnull, nonatomic, readonly) id<FBSDKNotificationObserving> notificationObserver;
@property (nonnull, nonatomic, readonly) NSHashTable<id<FBSDKApplicationObserving>> *applicationObservers;
@property (nonnull, nonatomic, readonly) id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging> appEvents;
@property (nonnull, nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonnull, nonatomic, readonly) Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> authenticationTokenWallet;
@property (nonnull, nonatomic, readonly) FBSDKAccessTokenExpirer *accessTokenExpirer;
@property (nonnull, nonatomic, readonly) id<FBSDKPaymentObserving> paymentObserver;
@property (nonnull, nonatomic, readonly) id<FBSDKUserDataPersisting> userDataStore;

#if !TARGET_OS_TV
@property (nonnull, nonatomic, readonly) Class<FBSDKProfileProviding> profileProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKBackgroundEventLogging> backgroundEventLogger;
@property (nonatomic) FBSDKSKAdNetworkReporter *skAdNetworkReporter;
#endif

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
#if TARGET_OS_TV
  return [self initWithNotificationCenter:NSNotificationCenter.defaultCenter
                              tokenWallet:FBSDKAccessToken.class
                                 settings:FBSDKSettings.sharedSettings
                           featureChecker:FBSDKFeatureManager.shared
                                appEvents:FBSDKAppEvents.shared
              serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                    store:NSUserDefaults.standardUserDefaults
                authenticationTokenWallet:FBSDKAuthenticationToken.class];
#else
  FBSDKBackgroundEventLogger *backgroundEventLogger = [[FBSDKBackgroundEventLogger alloc] initWithInfoDictionaryProvider:NSBundle.mainBundle
                                                                                                             eventLogger:FBSDKAppEvents.shared];
  FBSDKPaymentProductRequestorFactory *paymentProductRequestorFactory = [[FBSDKPaymentProductRequestorFactory alloc] initWithSettings:FBSDKSettings.sharedSettings
                                                                                                                          eventLogger:FBSDKAppEvents.shared
                                                                                                                    gateKeeperManager:FBSDKGateKeeperManager.class
                                                                                                                                store:NSUserDefaults.standardUserDefaults
                                                                                                                        loggerFactory:[FBSDKLoggerFactory new]
                                                                                                               productsRequestFactory:[FBSDKProductRequestFactory new]
                                                                                                              appStoreReceiptProvider:[NSBundle bundleForClass:self.class]];
  id<FBSDKPaymentObserving> paymentObserver = [[FBSDKPaymentObserver alloc]
                                               initWithPaymentQueue:SKPaymentQueue.defaultQueue
                                               paymentProductRequestorFactory:paymentProductRequestorFactory];

  return [self initWithNotificationCenter:NSNotificationCenter.defaultCenter
                              tokenWallet:FBSDKAccessToken.class
                                 settings:FBSDKSettings.sharedSettings
                           featureChecker:FBSDKFeatureManager.shared
                                appEvents:FBSDKAppEvents.shared
              serverConfigurationProvider:FBSDKServerConfigurationManager.shared
                                    store:NSUserDefaults.standardUserDefaults
                authenticationTokenWallet:FBSDKAuthenticationToken.class
                          profileProvider:FBSDKProfile.class
                    backgroundEventLogger:backgroundEventLogger
                          paymentObserver:paymentObserver];
#endif
}

#if TARGET_OS_TV
- (instancetype)initWithNotificationCenter:(id<FBSDKNotificationObserving, FBSDKNotificationPosting>)notificationCenter
                               tokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                                  settings:(id<FBSDKSettingsLogging, FBSDKSettings>)settings
                            featureChecker:(id<FBSDKFeatureChecking>)featureChecker
                                 appEvents:(id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging>)appEvents
               serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                     store:(id<FBSDKDataPersisting>)store
                 authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
{
  if ((self = [super init])) {
    _applicationObservers = [NSHashTable new];
    _notificationObserver = notificationCenter;
    _tokenWallet = tokenWallet;
    _settings = settings;
    _featureChecker = featureChecker;
    _appEvents = appEvents;
    _serverConfigurationProvider = serverConfigurationProvider;
    _store = store;
    _authenticationTokenWallet = authenticationTokenWallet;
    _accessTokenExpirer = [[FBSDKAccessTokenExpirer alloc] initWithNotificationCenter:notificationCenter];
  }
  return self;
}

#else
- (instancetype)initWithNotificationCenter:(id<FBSDKNotificationObserving, FBSDKNotificationPosting>)notificationCenter
                               tokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                                  settings:(id<FBSDKSettingsLogging, FBSDKSettings>)settings
                            featureChecker:(id<FBSDKFeatureChecking>)featureChecker
                                 appEvents:(id<FBSDKSourceApplicationTracking, FBSDKAppEventsConfiguring, FBSDKApplicationLifecycleObserving, FBSDKApplicationActivating, FBSDKApplicationStateSetting, FBSDKEventLogging>)appEvents
               serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                     store:(id<FBSDKDataPersisting>)store
                 authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
                           profileProvider:(Class<FBSDKProfileProviding>)profileProvider
                     backgroundEventLogger:(id<FBSDKBackgroundEventLogging>)backgroundEventLogger
                           paymentObserver:(id<FBSDKPaymentObserving>)paymentObserver
{
  if ((self = [super init])) {
    _applicationObservers = [NSHashTable new];
    _notificationObserver = notificationCenter;
    _tokenWallet = tokenWallet;
    _settings = settings;
    _featureChecker = featureChecker;
    _appEvents = appEvents;
    _serverConfigurationProvider = serverConfigurationProvider;
    _store = store;
    _authenticationTokenWallet = authenticationTokenWallet;
    _profileProvider = profileProvider;
    _backgroundEventLogger = backgroundEventLogger;
    _accessTokenExpirer = [[FBSDKAccessTokenExpirer alloc] initWithNotificationCenter:notificationCenter];
    _paymentObserver = paymentObserver;
    _userDataStore = [FBSDKUserDataStore new];
  }
  return self;
}

#endif

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
  [self configureDependencies];

  [self logInitialization];
  [self addObservers];
  [self.appEvents startObservingApplicationLifecycleNotifications];
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
  [self.appEvents setSourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                               openURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
  // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
  [self.appEvents registerAutoResetSourceApplication];
  [FBSDKInternalUtility.sharedUtility validateFacebookReservedURLSchemes];
}

#if !TARGET_OS_TV
- (void)initializeMeasurementListener
{
  // Register Listener for App Link measurement events
  FBSDKMeasurementEventListener *listener = [[FBSDKMeasurementEventListener alloc] initWithEventLogger:self.appEvents
                                                                              sourceApplicationTracker:self.appEvents];
  [listener registerForAppLinkMeasurementEvents];
}

#endif

#if !TARGET_OS_TV
- (void)logBackgroundRefreshStatus
{
  [self.backgroundEventLogger logBackgroundRefreshStatus:[UIApplication.sharedApplication backgroundRefreshStatus]];
}

#endif

- (void)logInitialization
{
  id<FBSDKSettingsLogging> const settingsLogger = self.settings;
  [settingsLogger logWarnings];
  [settingsLogger logIfSDKSettingsChanged];
  [settingsLogger recordInstall];
}

- (void)enableInstrumentation
{
  [self.featureChecker checkFeature:FBSDKFeatureInstrument completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKInstrumentManager.shared enable];
    }
  }];
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

#pragma mark - UIApplicationDelegate

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
  [self.appEvents setSourceApplication:sourceApplication openURL:url];

#if !TARGET_OS_TV
  [self.featureChecker checkFeature:FBSDKFeatureAEM completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBAEMReporter setCatalogReportEnabled:[self.featureChecker isEnabled:FBSDKFeatureAEMCatalogReport]];
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

    if (self.settings.isAutoLogAppEventsEnabled) {
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
  FBSDKAccessToken *cachedToken = [[self.tokenWallet tokenCache] accessToken];
  [self.tokenWallet setCurrentAccessToken:cachedToken];
}

- (void)fetchServerConfiguration
{
  [self.serverConfigurationProvider loadServerConfigurationWithCompletionBlock:NULL];
}

#if !TARGET_OS_TV
- (void)initializeProfile
{
  FBSDKProfile *cachedProfile = [self.profileProvider fetchCachedProfile];
  [self.profileProvider setCurrentProfile:cachedProfile];
}

#endif

#if !TARGET_OS_TV
- (void)checkAuthentication
{
  FBSDKAuthenticationToken *cachedAuthToken = [[self.authenticationTokenWallet tokenCache] authenticationToken];
  [self.authenticationTokenWallet setCurrentAuthenticationToken:cachedAuthToken];

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
  if (self.settings.isAutoLogAppEventsEnabled) {
    [self.appEvents activateApp];
  }
#if !TARGET_OS_TV
  [self.skAdNetworkReporter checkAndRevokeTimer];
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
  [self.appEvents setApplicationState:state];
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

  NSMutableDictionary<NSString *, id> *logData = [NSMutableDictionary new];
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

  [self.appEvents logInternalEvent:FBSDKAppLinkInboundEvent
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
  NSMutableDictionary<NSString *, NSNumber *> *params = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:params setObject:@1 forKey:@"core_lib_included"];
  for (NSString *className in metaInfo.allKeys) {
    NSString *keyName = [FBSDKTypeUtility dictionary:metaInfo objectForKey:className ofType:NSObject.class];
    if (objc_lookUpClass([className UTF8String])) {
      [FBSDKTypeUtility dictionary:params setObject:@1 forKey:keyName];
      bitmask |= 1 << bit;
    }
    bit++;
  }

  NSInteger existingBitmask = [self.store integerForKey:FBSDKKitsBitmaskKey];
  if (existingBitmask != bitmask) {
    [self.store setInteger:bitmask forKey:FBSDKKitsBitmaskKey];
    [self.appEvents logInternalEvent:@"fb_sdk_initialize"
                          parameters:params
                  isImplicitlyLogged:NO];
  }
}

- (void)_logIfAutoAppLinkEnabled
{
#if !TARGET_OS_TV
  NSNumber *enabled = [NSBundle.mainBundle objectForInfoDictionaryKey:@"FBSDKAutoAppLinkEnabled"];
  if (enabled.boolValue) {
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary new];
    if (![FBSDKAppLinkUtility isMatchURLScheme:[NSString stringWithFormat:@"fb%@", self.settings.appID]]) {
      NSString *warning = @"You haven't set the Auto App Link URL scheme: fb<YOUR APP ID>";
      [FBSDKTypeUtility dictionary:params setObject:warning forKey:@"SchemeWarning"];
      NSLog(@"%@", warning);
    }
    [self.appEvents logInternalEvent:@"fb_auto_applink" parameters:params isImplicitlyLogged:YES];
  }
#endif
}

- (void)configureDependencies
{
  id<FBSDKGraphRequestFactory> graphRequestFactory = [FBSDKGraphRequestFactory new];
  id<FBSDKDataPersisting> store = NSUserDefaults.standardUserDefaults;
  id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory = [FBSDKGraphRequestConnectionFactory new];
  id<FBSDKSettings> sharedSettings = FBSDKSettings.sharedSettings;
  id<FBSDKServerConfigurationProviding> serverConfigurationProvider = FBSDKServerConfigurationManager.shared;
  id<FBSDKFeatureChecking> sharedFeatureChecker = FBSDKFeatureManager.shared;
  id<FBSDKCrashHandler> sharedCrashHandler = FBSDKCrashHandler.shared;
  id<FBSDKCrashObserving> crashObserver = [[FBSDKCrashObserver alloc] initWithFeatureChecker:sharedFeatureChecker
                                                                         graphRequestFactory:graphRequestFactory
                                                                                    settings:sharedSettings
                                                                                crashHandler:sharedCrashHandler];
  id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider = FBSDKAppEventsConfigurationManager.shared;
  FBSDKErrorFactory *errorFactory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];

  [FBSDKGraphRequestConnection configureWithURLSessionProxyFactory:[FBSDKURLSessionProxyFactory new]
                                        errorConfigurationProvider:[FBSDKErrorConfigurationProvider new]
                                                  piggybackManager:FBSDKGraphRequestPiggybackManager.self
                                                          settings:sharedSettings
                                     graphRequestConnectionFactory:graphRequestConnectionFactory
                                                       eventLogger:FBSDKAppEvents.shared
                                    operatingSystemVersionComparer:NSProcessInfo.processInfo
                                           macCatalystDeterminator:NSProcessInfo.processInfo
                                               accessTokenProvider:FBSDKAccessToken.class
                                                 accessTokenSetter:FBSDKAccessToken.class
                                                      errorFactory:errorFactory
                                       authenticationTokenProvider:FBSDKAuthenticationToken.class]; // TEMP: added to configurator
  [FBSDKServerConfigurationManager.shared configureWithGraphRequestFactory:graphRequestFactory
                                             graphRequestConnectionFactory:graphRequestConnectionFactory]; // TEMP: added to configurator
  [FBSDKSettings configureWithStore:store
     appEventsConfigurationProvider:appEventsConfigurationProvider
             infoDictionaryProvider:NSBundle.mainBundle
                        eventLogger:FBSDKAppEvents.shared]; // TEMP: added to configurator
  [FBSDKFeatureManager.shared configureWithGateKeeperManager:FBSDKGateKeeperManager.class
                                                    settings:sharedSettings
                                                       store:store]; // TEMP: added to configurator
  [FBSDKGraphRequest configureWithSettings:sharedSettings
          currentAccessTokenStringProvider:FBSDKAccessToken.class
             graphRequestConnectionFactory:graphRequestConnectionFactory]; // TEMP: added to configurator
  [FBSDKGraphRequestConnection setCanMakeRequests];
  [FBSDKGateKeeperManager configureWithSettings:sharedSettings
                            graphRequestFactory:graphRequestFactory
                  graphRequestConnectionFactory:graphRequestConnectionFactory
                                          store:store]; // TEMP: added to configurator
  [FBSDKInstrumentManager.shared configureWithFeatureChecker:sharedFeatureChecker
                                                    settings:sharedSettings
                                               crashObserver:crashObserver
                                               errorReporter:FBSDKErrorReporter.shared
                                                crashHandler:sharedCrashHandler]; // TEMP: added to configurator
  FBSDKTokenCache *tokenCache = [[FBSDKTokenCache alloc] initWithSettings:sharedSettings
                                                     keychainStoreFactory:[FBSDKKeychainStoreFactory new]];
  [FBSDKAccessToken configureWithTokenCache:tokenCache
              graphRequestConnectionFactory:graphRequestConnectionFactory
               graphRequestPiggybackManager:FBSDKGraphRequestPiggybackManager.self]; // TEMP: added to configurator
  FBSDKAuthenticationToken.tokenCache = tokenCache;
  [FBSDKAppEventsDeviceInfo.shared configureWithSettings:sharedSettings];
  FBSDKATEPublisherFactory *atePublisherFactory = [[FBSDKATEPublisherFactory alloc] initWithStore:store
                                                                              graphRequestFactory:graphRequestFactory
                                                                                         settings:sharedSettings
                                                                        deviceInformationProvider:FBSDKAppEventsDeviceInfo.shared];
  id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording> timeSpentRecorder;
  timeSpentRecorder = [[FBSDKTimeSpentData alloc] initWithEventLogger:self.appEvents
                                          serverConfigurationProvider:serverConfigurationProvider];
  FBSDKEventDeactivationManager *eventDeactivationManager = [FBSDKEventDeactivationManager new];
  FBSDKRestrictiveDataFilterManager *restrictiveDataFilterManager = [[FBSDKRestrictiveDataFilterManager alloc] initWithServerConfigurationProvider:serverConfigurationProvider];
  FBSDKAppEventsUtility.shared.appEventsConfigurationProvider = appEventsConfigurationProvider; // TEMP: added to configurator
  FBSDKAppEventsUtility.shared.deviceInformationProvider = FBSDKAppEventsDeviceInfo.shared; // TEMP: added to configurator
  FBSDKAppEventsState.eventProcessors = @[eventDeactivationManager, restrictiveDataFilterManager]; // TEMP: added to configurator
  [self.appEvents configureWithGateKeeperManager:FBSDKGateKeeperManager.class
                  appEventsConfigurationProvider:appEventsConfigurationProvider
                     serverConfigurationProvider:serverConfigurationProvider
                             graphRequestFactory:graphRequestFactory
                                  featureChecker:self.featureChecker
                                primaryDataStore:store
                                          logger:FBSDKLogger.class
                                        settings:sharedSettings
                                 paymentObserver:self.paymentObserver
                               timeSpentRecorder:timeSpentRecorder
                             appEventsStateStore:FBSDKAppEventsStateManager.shared
             eventDeactivationParameterProcessor:eventDeactivationManager
         restrictiveDataFilterParameterProcessor:restrictiveDataFilterManager
                             atePublisherFactory:atePublisherFactory
                          appEventsStateProvider:[FBSDKAppEventsStateFactory new]
                            advertiserIDProvider:FBSDKAppEventsUtility.shared
                                   userDataStore:self.userDataStore]; // TEMP: added to configurator

  FBSDKImpressionLoggerFactory *impressionLoggerFactory = [[FBSDKImpressionLoggerFactory alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                                                eventLogger:FBSDKAppEvents.shared
                                                                                                         notificationCenter:NSNotificationCenter.defaultCenter
                                                                                                          accessTokenWallet:FBSDKAccessToken.class];
  [FBSDKImpressionLoggingButton configureWithImpressionLoggerFactory:impressionLoggerFactory];

  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:NSBundle.mainBundle
                                                            loggerFactory:[FBSDKLoggerFactory new]]; // TEMP: added to configurator
  [FBSDKAppEventsConfigurationManager configureWithStore:store
                                                settings:sharedSettings
                                     graphRequestFactory:graphRequestFactory
                           graphRequestConnectionFactory:graphRequestConnectionFactory]; // TEMP: added to configurator
  [FBSDKGraphRequestPiggybackManager configureWithTokenWallet:FBSDKAccessToken.class
                                                     settings:sharedSettings
                                  serverConfigurationProvider:serverConfigurationProvider
                                          graphRequestFactory:graphRequestFactory]; // TEMP: added to configurator
  [FBSDKButton configureWithApplicationActivationNotifier:self
                                              eventLogger:FBSDKAppEvents.shared
                                      accessTokenProvider:FBSDKAccessToken.class]; // TEMP: added to configurator
  [FBSDKError configureWithErrorReporter:FBSDKErrorReporter.shared]; // TEMP: added to configurator
#if !TARGET_OS_TV
  [FBSDKBridgeAPIRequest configureWithInternalURLOpener:UIApplication.sharedApplication
                                        internalUtility:FBSDKInternalUtility.sharedUtility
                                               settings:FBSDKSettings.sharedSettings]; // TEMP: added to configurator
  [FBSDKURL configureWithSettings:sharedSettings
                   appLinkFactory:[FBSDKAppLinkFactory new]
             appLinkTargetFactory:[FBSDKAppLinkTargetFactory new]
               appLinkEventPoster:[FBSDKMeasurementEvent new]]; // TEMP: added to configurator
  FBSDKSuggestedEventsIndexer *suggestedEventsIndexer = [[FBSDKSuggestedEventsIndexer alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                             serverConfigurationProvider:serverConfigurationProvider
                                                                                                                swizzler:FBSDKSwizzler.class
                                                                                                                settings:sharedSettings
                                                                                                             eventLogger:FBSDKAppEvents.shared
                                                                                                        featureExtractor:FBSDKFeatureExtractor.class
                                                                                                          eventProcessor:FBSDKModelManager.shared];
  FBSDKAppEventsUtility *sharedAppEventsUtility = FBSDKAppEventsUtility.shared;
  [FBSDKModelManager.shared configureWithFeatureChecker:FBSDKFeatureManager.shared
                                    graphRequestFactory:graphRequestFactory
                                            fileManager:NSFileManager.defaultManager
                                                  store:store
                                               settings:sharedSettings
                                          dataExtractor:NSData.class
                                      gateKeeperManager:FBSDKGateKeeperManager.class
                                 suggestedEventsIndexer:suggestedEventsIndexer
                                       featureExtractor:FBSDKFeatureExtractor.class]; // TEMP: added to configurator
  [FBSDKFeatureExtractor configureWithRulesFromKeyProvider:FBSDKModelManager.shared]; // TEMP: added to configurator
  [FBSDKAppLinkUtility configureWithGraphRequestFactory:graphRequestFactory
                                 infoDictionaryProvider:NSBundle.mainBundle
                                               settings:sharedSettings
                         appEventsConfigurationProvider:FBSDKAppEventsConfigurationManager.shared
                                   advertiserIDProvider:sharedAppEventsUtility
                                appEventsDropDeterminer:sharedAppEventsUtility
                            appEventParametersExtractor:sharedAppEventsUtility
                                      appLinkURLFactory:[FBSDKAppLinkURLFactory new]
                                         userIDProvider:FBSDKAppEvents.shared
                                          userDataStore:self.userDataStore]; // TEMP: added to configurator

  [FBSDKCodelessIndexer configureWithGraphRequestFactory:graphRequestFactory
                             serverConfigurationProvider:serverConfigurationProvider
                                               dataStore:store
                           graphRequestConnectionFactory:graphRequestConnectionFactory
                                                swizzler:FBSDKSwizzler.class
                                                settings:sharedSettings
                                    advertiserIDProvider:FBSDKAppEventsUtility.shared]; // TEMP: added to configurator
  [FBSDKCrashShield configureWithSettings:sharedSettings
                      graphRequestFactory:[FBSDKGraphRequestFactory new]
                          featureChecking:FBSDKFeatureManager.shared]; // TEMP: added to configurator
  self.skAdNetworkReporter = nil;
  if (@available(iOS 11.3, *)) {
    self.skAdNetworkReporter = [[FBSDKSKAdNetworkReporter alloc] initWithGraphRequestFactory:graphRequestFactory
                                                                                       store:store
                                                                    conversionValueUpdatable:SKAdNetwork.class];
  }
  if (@available(iOS 14.0, *)) {
    [FBAEMReporter configureWithNetworker:[FBSDKAEMNetworker new]
                                    appID:sharedSettings.appID
                                 reporter:self.skAdNetworkReporter];
  }
  [FBSDKProfile configureWithDataStore:store
                   accessTokenProvider:FBSDKAccessToken.class
                    notificationCenter:NSNotificationCenter.defaultCenter
                              settings:sharedSettings
                             urlHoster:FBSDKInternalUtility.sharedUtility]; // TEMP: added to configurator
  [FBSDKWebDialogView configureWithWebViewProvider:[FBSDKWebViewFactory new]
                                         urlOpener:UIApplication.sharedApplication]; // TEMP: added to configurator
  FBSDKMetadataIndexer *metaIndexer = [[FBSDKMetadataIndexer alloc] initWithUserDataStore:self.userDataStore
                                                                                 swizzler:FBSDKSwizzler.class];
  [self.appEvents configureNonTVComponentsWithOnDeviceMLModelManager:FBSDKModelManager.shared
                                                     metadataIndexer:metaIndexer
                                                 skAdNetworkReporter:self.skAdNetworkReporter
                                                     codelessIndexer:FBSDKCodelessIndexer.class
                                                            swizzler:FBSDKSwizzler.class
                                                         aemReporter:FBAEMReporter.class]; // TEMP: added to configurator
  [FBSDKAuthenticationStatusUtility configureWithProfileSetter:FBSDKProfile.class
                                       sessionDataTaskProvider:NSURLSession.sharedSession
                                             accessTokenWallet:FBSDKAccessToken.class
                                     authenticationTokenWallet:FBSDKAuthenticationToken.class]; // TEMP: added to configurator
  [FBSDKAppLinkNavigation configureWithSettings:sharedSettings
                                      urlOpener:UIApplication.sharedApplication
                             appLinkEventPoster:[FBSDKMeasurementEvent new]
                                appLinkResolver:FBSDKWebViewAppLinkResolver.sharedInstance]; // TEMP: added to configurator
#endif
}

// MARK: - Testability

#if DEBUG && FBTEST

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
