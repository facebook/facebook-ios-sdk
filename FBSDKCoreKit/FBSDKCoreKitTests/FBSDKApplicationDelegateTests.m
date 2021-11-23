/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateFactory.h"
#import "FBSDKApplicationObserving.h"
#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKCodelessIndexer+Testing.h"
#import "FBSDKConversionValueUpdating.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKCrashShield+Internal.h"
#import "FBSDKCrashShield+Testing.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureExtractor+Testing.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequestConnection+Testing.h"
#import "FBSDKPaymentObserver.h"
#import "FBSDKProfile+Testing.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKRestrictiveDataFilterManager+Testing.h"
#import "FBSDKSKAdNetworkReporter+Testing.h"
#import "FBSDKTimeSpentData.h"

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
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [TestAccessTokenWallet reset];
  [TestAuthenticationTokenWallet reset];
  [TestGateKeeperManager reset];
  [TestProfileProvider reset];
}

- (void)testInitializingSdkAddsBridgeApiObserver
{
  [self.delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [self.delegate.applicationObservers containsObject:FBSDKBridgeAPI.sharedInstance],
    "Should add the shared bridge api instance to the application observers"
  );
}

- (void)testInitializingSdkPerformsSettingsLogging
{
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
  [self.delegate initializeSDKWithLaunchOptions:@{}];
  XCTAssertEqual(
    self.backgroundEventLogger.logBackgroundRefresStatusCallCount,
    1,
    "Should have background event logger log background refresh status upon initialization"
  );
}

// TEMP: added to configurator tests
- (void)testInitializingSdkConfiguresAppEventsConfigurationManager
{
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

- (void)testInitializingSdkChecksInstrumentFeature
{
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
