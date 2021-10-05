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

#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsStateFactory.h"
#import "FBSDKApplicationObserving.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKConversionValueUpdating.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKCrashShield+Internal.h"
#import "FBSDKEventDeactivationManager+Protocols.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureExtractor+Internal.h"
#import "FBSDKFeatureExtractor+Testing.h"
#import "FBSDKFeatureManager+FeatureChecking.h"
#import "FBSDKPaymentObserver.h"
#import "FBSDKRestrictiveDataFilterManager+Protocols.h"
#import "FBSDKTimeSpentData.h"

@interface FBSDKGraphRequestConnection (AppDelegateTesting)
+ (BOOL)canMakeRequests;
+ (void)resetCanMakeRequests;
@end

@interface FBSDKApplicationDelegate (Testing)

- (BOOL)isAppLaunched;
- (void)setIsAppLaunched:(BOOL)isLaunched;
- (void)resetApplicationObserverCache;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)setApplicationState:(UIApplicationState)state;
- (void)initializeSDKWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
- (FBSDKSKAdNetworkReporter *)skAdNetworkReporter;

@end

@interface FBSDKBridgeAPI (ApplicationObserving) <FBSDKApplicationObserving>
@end

@interface FBSDKCodelessIndexer (Testing)
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;
@end

@interface FBSDKSKAdNetworkReporter (Testing)
- (id<FBSDKGraphRequestFactory>)graphRequestFactory;
- (id<FBSDKDataPersisting>)store;
- (Class<FBSDKConversionValueUpdating>)conversionValueUpdatable;
@end

@interface FBSDKProfile (Testing)
+ (id<FBSDKDataPersisting>)store;
@end

@interface FBSDKCrashShield (Testing)
+ (id<FBSDKSettings>)settings;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;
+ (id<FBSDKFeatureChecking>)featureChecking;
@end

@interface FBSDKRestrictiveDataFilterManager (Testing)
- (id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;
@end

@interface FBSDKAppEvents (ApplicationDelegateTesting)

@property (nonatomic, readonly) id<FBSDKAtePublishing> atePublisher;

+ (Class<FBSDKGateKeeperManaging>)gateKeeperManager;
+ (Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider;
+ (id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;
+ (id<FBSDKFeatureChecking>)featureChecker;
+ (id<FBSDKDataPersisting>)store;
+ (Class<FBSDKLogging>)logger;
+ (id<FBSDKSettings>)settings;
+ (id<FBSDKPaymentObserving>)paymentObserver;
+ (id<FBSDKTimeSpentRecording>)timeSpentRecorder;
+ (id<FBSDKAppEventsStatePersisting>)appEventsStateStore;
+ (id<FBSDKAppEventsParameterProcessing>)eventDeactivationParameterProcessor;
+ (id<FBSDKAppEventsParameterProcessing>)restrictiveDataFilterParameterProcessor;
@end

@interface FBSDKAppEventsState (Testing)

@property (class, nullable, nonatomic) NSArray<id<FBSDKEventsProcessing>> *eventProcessors;

@end

@interface FBSDKApplicationDelegateTests : XCTestCase

@property (nonatomic) FBSDKApplicationDelegate *delegate;
@property (nonatomic) TestFeatureManager *featureChecker;
@property (nonatomic) TestAppEvents *appEvents;
@property (nonatomic) UserDefaultsSpy *store;
@property (nonatomic) TestSettings *settings;
@property (nonatomic) TestBackgroundEventLogger *backgroundEventLogger;

@end

@implementation FBSDKApplicationDelegateTests

static NSString *bitmaskKey = @"com.facebook.sdk.kits.bitmask";

- (void)setUp
{
  [super setUp];

  [self.class resetTestData];

  self.appEvents = [TestAppEvents new];
  self.settings = [TestSettings new];
  self.featureChecker = [TestFeatureManager new];
  self.backgroundEventLogger = [[TestBackgroundEventLogger alloc] initWithInfoDictionaryProvider:[TestBundle new]
                                                                                     eventLogger:self.appEvents];
  TestServerConfigurationProvider *serverConfigurationProvider = [[TestServerConfigurationProvider alloc]
                                                                  initWithConfiguration:ServerConfigurationFixtures.defaultConfig];
  self.delegate = [[FBSDKApplicationDelegate alloc] initWithNotificationCenter:[TestNotificationCenter new]
                                                                   tokenWallet:TestAccessTokenWallet.class
                                                                      settings:self.settings
                                                                featureChecker:self.featureChecker
                                                                     appEvents:self.appEvents
                                                   serverConfigurationProvider:serverConfigurationProvider
                                                                         store:self.store
                                                     authenticationTokenWallet:TestAuthenticationTokenWallet.class
                                                               profileProvider:TestProfileProvider.class
                                                         backgroundEventLogger:self.backgroundEventLogger
                                                               paymentObserver:[TestPaymentObserver new]];
  self.delegate.isAppLaunched = NO;

  [self.delegate resetApplicationObserverCache];
}

- (void)tearDown
{
  [super tearDown];

  self.delegate = nil;

  [self.class resetTestData];
  [self.settings reset];
}

+ (void)resetTestData
{
  [TestAccessTokenWallet reset];
  [TestAuthenticationTokenWallet reset];
  [TestGateKeeperManager reset];
  [TestProfileProvider reset];
}

// MARK: - Lifecycle Methods

- (void)testInitializingSdkEnablesGraphRequests
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKGraphRequestConnection resetCanMakeRequests];

  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [FBSDKGraphRequestConnection canMakeRequests],
    "Initializing the SDK should enable making graph requests"
  );
}

- (void)testInitializingSdkEnablesAppEvents
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAppEvents reset];

  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureGateKeeperManager,
    FBSDKGateKeeperManager.class,
    "Initializing the SDK should set gate keeper manager for event logging"
  );
  NSObject *graphRequestFactory = (NSObject *) self.appEvents.capturedConfigureGraphRequestFactory;
  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Initializing the SDK should set graph request factory for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureAppEventsConfigurationProvider,
    FBSDKAppEventsConfigurationManager.class,
    "Initializing the SDK should set AppEvents configuration provider for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureServerConfigurationProvider,
    FBSDKServerConfigurationManager.shared,
    "Initializing the SDK should set server configuration provider for event logging"
  );
  NSObject *store = (NSObject *)self.appEvents.capturedConfigureStore;
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureFeatureChecker,
    self.delegate.featureChecker,
    "Initializing the SDK should set feature checker for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureLogger,
    FBSDKLogger.class,
    "Initializing the SDK should set concrete logger for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureSettings,
    FBSDKSettings.sharedSettings,
    "Initializing the SDK should set concrete settings for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigurePaymentObserver,
    self.delegate.paymentObserver,
    "Initializing the SDK should set concrete payment observer for event logging"
  );
  XCTAssertTrue(
    [(NSObject *)self.appEvents.capturedConfigureTimeSpentRecorderFactory
     isKindOfClass:FBSDKTimeSpentRecordingFactory.class],
    "Initializing the SDK should set concrete time spent recorder factory for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureAppEventsStateStore,
    FBSDKAppEventsStateManager.shared,
    "Initializing the SDK should set concrete state store for event logging"
  );
  NSObject *capturedConfigureEventDeactivationParameterProcessor = (NSObject *)self.appEvents.capturedConfigureEventDeactivationParameterProcessor;
  XCTAssertEqualObjects(
    capturedConfigureEventDeactivationParameterProcessor.class,
    FBSDKEventDeactivationManager.class,
    "Initializing the SDK should set concrete event deactivation parameter processor for event logging"
  );
  NSObject *capturedConfigureRestrictiveDataFilterParameterProcessor = (NSObject *)self.appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor;

  XCTAssertEqualObjects(
    capturedConfigureRestrictiveDataFilterParameterProcessor.class,
    FBSDKRestrictiveDataFilterManager.class,
    "Initializing the SDK should set concrete restrictive data filter parameter processor for event logging"
  );
  XCTAssertTrue(
    [(NSObject *)self.appEvents.capturedConfigureAtePublisherFactory isKindOfClass:FBSDKAtePublisherFactory.class],
    "Initializing the SDK should set concrete ate publisher factory for event logging"
  );

  NSObject *capturedConfigureAppEventsStateProvider = (NSObject *)self.appEvents.capturedConfigureAppEventsStateProvider;
  XCTAssertEqualObjects(
    capturedConfigureAppEventsStateProvider.class,
    FBSDKAppEventsStateFactory.class,
    "Initializing the SDK should set concrete AppEvents state provider for event logging"
  );

  XCTAssertEqualObjects(
    self.appEvents.capturedConfigureSwizzler,
    FBSDKSwizzler.class,
    "Initializing the SDK should set concrete swizzler for event logging"
  );

  XCTAssertEqualObjects(
    self.appEvents.capturedAdvertiserIDProvider,
    FBSDKAppEventsUtility.shared,
    "Initializing the SDK should set concrete advertiser ID provider"
  );

  XCTAssertEqualObjects(
    self.appEvents.capturedCodelessIndexer,
    FBSDKCodelessIndexer.class,
    "Initializing the SDK should set concrete codeless indexer"
  );

  XCTAssertTrue(
    [(NSObject *)self.appEvents.capturedUserDataStore isKindOfClass:FBSDKUserDataStore.class],
    "Initializing the SDK should set the expected concrete user data store"
  );
}

- (void)testInitializingSdkConfiguresEventsProcessorsForAppEventsState
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAppEvents reset];

  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSArray *expected = @[
    self.appEvents.capturedConfigureEventDeactivationParameterProcessor,
    self.appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor
  ];
  XCTAssertEqualObjects(
    FBSDKAppEventsState.eventProcessors,
    expected,
    "Initializing the SDK should configure events processors for FBSDKAppEventsState"
  );
}

- (void)testConfiguringNonTVAppEventsDependencies
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAppEvents reset];

  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertEqualObjects(
    self.appEvents.capturedOnDeviceMLModelManager,
    FBSDKModelManager.shared,
    "Initializing the SDK should set concrete on device model manager for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedMetadataIndexer,
    FBSDKMetadataIndexer.shared,
    "Initializing the SDK should set concrete metadata indexer for event logging"
  );
  XCTAssertEqualObjects(
    self.appEvents.capturedSKAdNetworkReporter,
    [self.delegate skAdNetworkReporter],
    "Initializing the SDK should set concrete SKAdNetworkReporter for event logging"
  );
}

- (void)testInitializingSdkConfiguresGateKeeperManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKGateKeeperManager reset];

  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *graphRequestFactory = (NSObject *)FBSDKGateKeeperManager.graphRequestFactory;
  NSObject *graphRequestConnectionFactory = (NSObject *)FBSDKGateKeeperManager.graphRequestConnectionFactory;
  NSObject *store = (NSObject *)FBSDKGateKeeperManager.store;

  XCTAssertTrue(
    [FBSDKGateKeeperManager canLoadGateKeepers],
    "Initializing the SDK should enable loading gatekeepers"
  );

  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    graphRequestConnectionFactory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "Should be configured with the expected concrete graph request connection provider"
  );
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
}

- (void)testConfiguringCodelessIndexer
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *graphRequestFactory = (NSObject *)[FBSDKCodelessIndexer graphRequestFactory];
  NSObject *serverConfigurationProvider = (NSObject *)[FBSDKCodelessIndexer serverConfigurationProvider];
  NSObject *store = (NSObject *)[FBSDKCodelessIndexer store];
  NSObject *graphRequestConnectionFactory = (NSObject *)[FBSDKCodelessIndexer graphRequestConnectionFactory];
  NSObject *swizzler = (NSObject *)[FBSDKCodelessIndexer swizzler];
  NSObject *settings = (NSObject *)[FBSDKCodelessIndexer settings];
  NSObject *advertiserIDProvider = (NSObject *)[FBSDKCodelessIndexer advertiserIDProvider];
  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    serverConfigurationProvider,
    FBSDKServerConfigurationManager.shared,
    "Should be configured with the expected concrete server configuration provider"
  );
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the standard user defaults"
  );
  XCTAssertEqualObjects(
    graphRequestConnectionFactory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "Should be configured with the expected concrete graph request connection provider"
  );
  XCTAssertEqualObjects(
    swizzler,
    FBSDKSwizzler.class,
    "Should be configured with the expected concrete swizzler"
  );
  XCTAssertEqualObjects(
    settings,
    FBSDKSettings.sharedSettings,
    "Should be configured with the expected concrete settings"
  );
  XCTAssertEqualObjects(
    advertiserIDProvider,
    FBSDKAppEventsUtility.shared,
    "Should be configured with the expected concrete advertiser identifier provider"
  );
}

- (void)testConfiguringCrashShield
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *settings = (NSObject *)[FBSDKCrashShield settings];
  NSObject *graphRequestFactory = (NSObject *)[FBSDKCrashShield graphRequestFactory];
  NSObject *featureChecking = (NSObject *)[FBSDKCrashShield featureChecking];
  XCTAssertEqualObjects(
    settings.class,
    FBSDKSettings.class,
    "Should be configured with the expected settings"
  );
  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    featureChecking.class,
    FBSDKFeatureManager.class,
    "Should be configured with the expected concrete Feature manager"
  );
}

- (void)testConfiguringRestrictiveDataFilterManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  FBSDKRestrictiveDataFilterManager *restrictiveDataFilterManager = (FBSDKRestrictiveDataFilterManager *) self.appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor;
  XCTAssertEqualObjects(
    restrictiveDataFilterManager.serverConfigurationProvider,
    FBSDKServerConfigurationManager.shared,
    "Should be configured with the expected concrete server configuration provider"
  );
}

- (void)testConfiguringFBSDKSKAdNetworkReporter
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *graphRequestFactory = (NSObject *)[[self.delegate skAdNetworkReporter] graphRequestFactory];
  NSObject *store = (NSObject *)[[self.delegate skAdNetworkReporter] store];
  NSObject *conversionValueUpdatable = (NSObject *)[[self.delegate skAdNetworkReporter] conversionValueUpdatable];
  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the standard user defaults"
  );
  if (@available(iOS 11.3, *)) {
    XCTAssertEqualObjects(
      conversionValueUpdatable,
      SKAdNetwork.class,
      "Should be configured with the default Conversion Value Updating Class"
    );
  }
}

- (void)testInitializingSdkConfiguresAccessTokenCache
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  FBSDKAccessToken.tokenCache = nil;
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *tokenCache = (NSObject *) FBSDKAccessToken.tokenCache;
  XCTAssertEqualObjects(tokenCache.class, FBSDKTokenCache.class, "Should be configured with expected concrete token cache");
}

- (void)testInitializingSdkConfiguresProfile
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *store = (NSObject *)[FBSDKProfile store];
  NSObject *tokenProvider = (NSObject *)[FBSDKProfile accessTokenProvider];
  NSObject *notificationCenter = (NSObject *)[FBSDKProfile notificationCenter];
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
  XCTAssertEqualObjects(
    tokenProvider,
    FBSDKAccessToken.class,
    "Should be configured with the expected concrete token provider"
  );
  XCTAssertEqualObjects(
    notificationCenter,
    NSNotificationCenter.defaultCenter,
    "Should be configured with the expected concrete Notification Center"
  );
}

- (void)testInitializingSdkConfiguresAuthenticationTokenCache
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *tokenCache = (NSObject *) FBSDKAuthenticationToken.tokenCache;
  XCTAssertEqualObjects(tokenCache.class, FBSDKTokenCache.class, "Should be configured with expected concrete token cache");
}

- (void)testInitializingSdkConfiguresAccessTokenConnectionFactory
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  FBSDKAccessToken.graphRequestConnectionFactory = [TestGraphRequestConnectionFactory new];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *graphRequestConnectionFactory = (NSObject *) FBSDKAccessToken.graphRequestConnectionFactory;
  XCTAssertEqualObjects(
    graphRequestConnectionFactory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "Should be configured with expected concrete graph request connection factory"
  );
}

- (void)testInitializingSdkConfiguresSettings
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKSettings reset];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *store = (NSObject *) FBSDKSettings.store;
  NSObject *appEventsConfigProvider = (NSObject *) FBSDKSettings.appEventsConfigurationProvider;
  NSObject *infoDictionaryProvider = (NSObject *) FBSDKSettings.infoDictionaryProvider;
  NSObject *eventLogger = (NSObject *) FBSDKSettings.eventLogger;
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
  XCTAssertEqualObjects(
    appEventsConfigProvider,
    FBSDKAppEventsConfigurationManager.class,
    "Should be configured with the expected concrete app events configuration provider"
  );
  XCTAssertEqualObjects(
    infoDictionaryProvider,
    NSBundle.mainBundle,
    "Should be configured with the expected concrete info dictionary provider"
  );
  XCTAssertEqualObjects(
    eventLogger,
    FBSDKAppEvents.shared,
    "Should be configured with the expected concrete event logger"
  );
}

- (void)testInitializingSdkConfiguresInternalUtility
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *infoDictionaryProvider = (NSObject *)[FBSDKInternalUtility.sharedUtility infoDictionaryProvider];
  XCTAssertEqualObjects(
    infoDictionaryProvider,
    NSBundle.mainBundle,
    "Should be configured with the expected concrete info dictionary provider"
  );
}

- (void)testInitializingSdkConfiguresGraphRequestPiggybackManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *tokenWallet = (NSObject *) FBSDKGraphRequestPiggybackManager.tokenWallet;
  NSObject *settings = (NSObject *) FBSDKGraphRequestPiggybackManager.settings;
  NSObject *serverConfiguration = (NSObject *) FBSDKGraphRequestPiggybackManager.serverConfiguration;
  NSObject *graphRequestFactory = (NSObject *) FBSDKGraphRequestPiggybackManager.graphRequestFactory;

  XCTAssertEqualObjects(
    tokenWallet,
    FBSDKAccessToken.class,
    "Should be configured with the expected concrete access token provider"
  );

  XCTAssertEqualObjects(
    settings,
    FBSDKSettings.sharedSettings,
    "Should be configured with the expected concrete settings"
  );
  XCTAssertEqualObjects(
    serverConfiguration,
    FBSDKServerConfigurationManager.shared,
    "Should be configured with the expected concrete server configuration"
  );

  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,

    "Should be configured with the expected concrete graph request provider"
  );
}

- (void)testInitializingSdkAddsBridgeApiObserver
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [self.delegate.applicationObservers containsObject:FBSDKBridgeAPI.sharedInstance],
    "Should add the shared bridge api instance to the application observers"
  );
}

- (void)testInitializingSdkPerformsSettingsLogging
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  XCTAssertEqual(
    self.settings.logWarningsCallCount,
    1,
    "Should have settings log warnings upon initialization"
  );
  XCTAssertEqual(
    self.settings.logIfSDKSettingsChangedCallCount,
    1,
    "Should have settings log if there were changes upon initialization"
  );
  XCTAssertEqual(
    self.settings.recordInstallCallCount,
    1,
    "Should have settings record installations upon initialization"
  );
}

- (void)testInitializingSdkPerformsBackgroundEventLogging
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  XCTAssertEqual(
    self.backgroundEventLogger.logBackgroundRefresStatusCallCount,
    1,
    "Should have background event logger log background refresh status upon initialization"
  );
}

- (void)testInitializingSdkConfiguresAppEventsConfigurationManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *store = (NSObject *) FBSDKAppEventsConfigurationManager.shared.store;
  NSObject *settings = (NSObject *) FBSDKAppEventsConfigurationManager.shared.settings;
  NSObject *graphRequestFactory = (NSObject *) FBSDKAppEventsConfigurationManager.shared.graphRequestFactory;
  NSObject *graphRequestConnectionFactory = (NSObject *) FBSDKAppEventsConfigurationManager.shared.graphRequestConnectionFactory;

  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
  XCTAssertEqualObjects(
    settings,
    FBSDKSettings.sharedSettings,
    "Should be configured with the expected concrete settings"
  );
  XCTAssertEqualObjects(
    graphRequestFactory.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete request provider"
  );
  XCTAssertEqualObjects(
    graphRequestConnectionFactory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "Should be configured with the expected concrete connection provider"
  );
}

- (void)testInitializingSdkConfiguresCurrentAccessTokenProviderForGraphRequest
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertEqualObjects(
    [FBSDKGraphRequest currentAccessTokenStringProvider],
    FBSDKAccessToken.class,
    "Should be configered with expected access token class."
  );
}

- (void)testInitializingSdkConfiguresWebDialogView
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *webViewProvider = (NSObject *) FBSDKWebDialogView.webViewProvider;
  NSObject *urlOpener = (NSObject *) FBSDKWebDialogView.urlOpener;
  XCTAssertEqualObjects(
    webViewProvider.class,
    FBSDKWebViewFactory.class,
    "Should be configured with the expected concrete web view provider"
  );
  XCTAssertEqualObjects(
    urlOpener,
    UIApplication.sharedApplication,
    "Should be configured with the expected concrete url opener"
  );
}

- (void)testInitializingSdkConfiguresFeatureExtractor
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *keyProvider = (NSObject *) FBSDKFeatureExtractor.keyProvider;
  XCTAssertEqualObjects(
    keyProvider.class,
    FBSDKModelManager.class,
    "Should be configured with the expected concrete web view provider"
  );
}

- (void)testInitializingSdkConfiguresButtonSuperclass
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *notifier = (NSObject *) FBSDKButton.applicationActivationNotifier;
  XCTAssertEqualObjects(
    notifier.class,
    FBSDKApplicationDelegate.class,
    "Should be configured with the expected concrete application activation notifier"
  );
}

- (void)testInitializingSdkChecksInstrumentFeature
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  XCTAssert(
    [self.featureChecker capturedFeaturesContains:FBSDKFeatureInstrument],
    "Should check if the instrument feature is enabled on initialization"
  );
}

- (void)testDidFinishLaunchingLaunchedApp
{
  self.delegate.isAppLaunched = YES;

  XCTAssertFalse(
    [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil],
    "Should return false if the application is already launched"
  );
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithCache
{
  FBSDKAccessToken *expected = SampleAccessTokens.validToken;
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:expected
                                                  authenticationToken:nil];
  TestAccessTokenWallet.tokenCache = cache;

  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertEqualObjects(
    TestAccessTokenWallet.currentAccessToken,
    expected,
    "Should set the current access token to the cached access token when it exists"
  );
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithoutCache
{
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  [TestAccessTokenWallet setTokenCache:[[TestTokenCache alloc] initWithAccessToken:nil authenticationToken:nil]];

  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertNil(
    TestAccessTokenWallet.currentAccessToken,
    "Should set the current access token to nil access token when there isn't a cached token"
  );
}

- (void)testDidFinishLaunchingSetsCurrentAuthenticationTokenWithCache
{
  FBSDKAuthenticationToken *expected = SampleAuthenticationToken.validToken;
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:nil
                                                  authenticationToken:expected];
  TestAuthenticationTokenWallet.tokenCache = cache;
  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertEqualObjects(
    TestAuthenticationTokenWallet.currentAuthenticationToken,
    expected,
    "Should set the current authentication token to the cached access token when it exists"
  );
}

- (void)testDidFinishLaunchingSetsCurrentAuthenticationTokenWithoutCache
{
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:nil authenticationToken:nil];
  TestAuthenticationTokenWallet.tokenCache = cache;

  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertNil(
    TestAuthenticationTokenWallet.currentAuthenticationToken,
    "Should set the current authentication token to nil access token when there isn't a cached token"
  );
}

- (void)testDidFinishLaunchingWithAutoLogEnabled
{
  [self.settings setStubbedIsAutoLogAppEventsEnabled:YES];

  [self.store setInteger:1 forKey:bitmaskKey];

  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertEqualObjects(
    self.appEvents.capturedEventName,
    @"fb_sdk_initialize",
    "Should log initialization when auto log app events is enabled"
  );
}

- (void)testDidFinishLaunchingWithAutoLogDisabled
{
  [self.settings setStubbedIsAutoLogAppEventsEnabled:NO];

  [self.store setInteger:1 forKey:bitmaskKey];

  [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertNil(
    self.appEvents.capturedEventName,
    "Should not log initialization when auto log app events are disabled"
  );
}

- (void)testDidFinishLaunchingWithObservers
{
  TestApplicationDelegateObserver *observer1 = [TestApplicationDelegateObserver new];
  TestApplicationDelegateObserver *observer2 = [TestApplicationDelegateObserver new];

  [self.delegate addObserver:observer1];
  [self.delegate addObserver:observer2];

  BOOL notifiedObservers = [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertEqual(
    observer1.didFinishLaunchingCallCount,
    1,
    "Should invoke did finish launching on all observers"
  );
  XCTAssertEqual(
    observer2.didFinishLaunchingCallCount,
    1,
    "Should invoke did finish launching on all observers"
  );
  XCTAssertTrue(notifiedObservers, "Should indicate if observers were notified");
}

- (void)testDidFinishLaunchingWithoutObservers
{
  BOOL notifiedObservers = [self.delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertFalse(notifiedObservers, "Should indicate if no observers were notified");
}

- (void)testAppEventsEnabled
{
  [self.settings setStubbedIsAutoLogAppEventsEnabled:YES];

  NSNotification *notification = [[NSNotification alloc] initWithName:UIApplicationDidBecomeActiveNotification
                                                               object:self
                                                             userInfo:nil];

  [self.delegate applicationDidBecomeActive:notification];

  XCTAssertTrue(
    self.appEvents.wasActivateAppCalled,
    "Should have app events activate the app when autolog app events is enabled"
  );
  XCTAssertEqual(
    self.appEvents.capturedApplicationState,
    UIApplicationStateActive,
    "Should set the application state to active when the notification is received"
  );
}

- (void)testAppEventsDisabled
{
  [self.settings setStubbedIsAutoLogAppEventsEnabled:NO];

  NSNotification *notification = [[NSNotification alloc] initWithName:UIApplicationDidBecomeActiveNotification
                                                               object:self
                                                             userInfo:nil];
  [self.delegate applicationDidBecomeActive:notification];

  XCTAssertFalse(
    self.appEvents.wasActivateAppCalled,
    "Should not have app events activate the app when autolog app events is enabled"
  );
  XCTAssertEqual(
    self.appEvents.capturedApplicationState,
    UIApplicationStateActive,
    "Should set the application state to active when the notification is received"
  );
}

- (void)testSetApplicationState
{
  [self.delegate setApplicationState:UIApplicationStateBackground];
  XCTAssertEqual(
    self.appEvents.capturedApplicationState,
    UIApplicationStateBackground,
    "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground"
  );
}

@end
