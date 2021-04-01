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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKAppEvents.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKTestCase.h"

@interface FBSDKGraphRequestConnection (AppDelegateTesting)
+ (BOOL)canMakeRequests;
+ (void)resetCanMakeRequests;
@end

@interface FBSDKGraphRequest (AppDelegateTesting)
+ (Class<FBSDKCurrentAccessTokenStringProviding>)currentAccessTokenStringProvider;
@end

@interface FBSDKApplicationDelegate (Testing)

- (BOOL)isAppLaunched;
- (void)setIsAppLaunched:(BOOL)isLaunched;
- (NSHashTable<id<FBSDKApplicationObserving>> *)applicationObservers;
- (void)resetApplicationObserverCache;
- (void)_logSDKInitialize;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)setApplicationState:(UIApplicationState)state;
- (void)initializeSDKWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

@end

@interface FBSDKBridgeAPI (ApplicationObserving) <FBSDKApplicationObserving>
@end

@interface FBSDKCodelessIndexer (Testing)
+ (id<FBSDKGraphRequestProviding>)requestProvider;
@end

@interface FBSDKSKAdNetworkReporter (Testing)
+ (id<FBSDKGraphRequestProviding>)requestProvider;
+ (id<FBSDKDataPersisting>)store;
@end

@interface FBSDKAppLinkUtility (Testing)
+ (id<FBSDKGraphRequestProviding>)requestProvider;
+ (id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider;
@end

@interface FBSDKProfile (Testing)
+ (id<FBSDKDataPersisting>)store;
@end

@interface FBSDKApplicationDelegateTests : FBSDKTestCase
{
  FBSDKApplicationDelegate *_delegate;
  FBSDKProfile *_profile;
  id _partialDelegateMock;
}
@end

@interface FBSDKAppEvents (ApplicationDelegateTesting)
+ (UIApplicationState)applicationState;
+ (BOOL)canLogEvents;
+ (Class<FBSDKGateKeeperManaging>)gateKeeperManager;
+ (Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider;
+ (Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider;
+ (id<FBSDKGraphRequestProviding>)requestProvider;
+ (Class<FBSDKFeatureChecking>)featureChecker;
+ (id<FBSDKDataPersisting>)store;
+ (id<FBSDKLogging>)logger;
@end

@implementation FBSDKApplicationDelegateTests

- (void)setUp
{
  [super setUp];

  [TestAccessTokenWallet reset];
  [TestSettings reset];

  _delegate = [[FBSDKApplicationDelegate alloc] initWithNotificationObserver:[TestNotificationCenter new]
                                                                 tokenWallet:TestAccessTokenWallet.class
                                                                    settings:TestSettings.class];
  _delegate.isAppLaunched = NO;

  _profile = [[FBSDKProfile alloc] initWithUserID:self.name
                                        firstName:nil
                                       middleName:nil
                                         lastName:nil
                                             name:nil
                                          linkURL:nil
                                      refreshDate:nil];

  // Avoid actually calling log initialize b/c of the side effects.
  _partialDelegateMock = OCMPartialMock(_delegate);
  OCMStub([_partialDelegateMock _logSDKInitialize]);

  [_delegate resetApplicationObserverCache];

  [self stubLoadingAdNetworkReporterConfiguration];
  [self stubServerConfigurationFetchingWithConfiguration:FBSDKServerConfigurationFixtures.defaultConfig error:nil];
  [self stubLoadingGateKeepers];
}

- (void)tearDown
{
  [super tearDown];

  _delegate = nil;
  _profile = nil;

  [_partialDelegateMock stopMocking];
  _partialDelegateMock = nil;

  [TestAccessTokenWallet reset];
  [TestSettings reset];
}

// MARK: - Observers

- (void)testDefaultObservers
{
  // Note: in reality this will have one observer from the BridgeAPI load method.
  // this needs to be re-architected to avoid this.
  XCTAssertEqual(
    _delegate.applicationObservers.count,
    0,
    "Should have no observers by default"
  );
}

- (void)testAddingNewObserver
{
  TestApplicationDelegateObserver *observer = [TestApplicationDelegateObserver new];
  [_delegate addObserver:observer];

  XCTAssertEqual(
    [_delegate applicationObservers].count,
    1,
    "Should be able to add a single observer"
  );
}

- (void)testAddingDuplicateObservers
{
  TestApplicationDelegateObserver *observer = [TestApplicationDelegateObserver new];
  [_delegate addObserver:observer];
  [_delegate addObserver:observer];

  XCTAssertEqual(
    [_delegate applicationObservers].count,
    1,
    "Should only add one instance of a given observer"
  );
}

- (void)testRemovingObserver
{
  TestApplicationDelegateObserver *observer = [TestApplicationDelegateObserver new];
  [_delegate addObserver:observer];
  [_delegate removeObserver:observer];

  XCTAssertEqual(
    _delegate.applicationObservers.count,
    0,
    "Should be able to remove observers that are present in the stored list"
  );
}

- (void)testRemovingMissingObserver
{
  TestApplicationDelegateObserver *observer = [TestApplicationDelegateObserver new];
  [_delegate removeObserver:observer];

  XCTAssertEqual(
    _delegate.applicationObservers.count,
    0,
    "Should not be able to remove absent observers"
  );
}

// MARK: - Lifecycle Methods

- (void)testInitializingSdkEnablesGraphRequests
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKGraphRequestConnection resetCanMakeRequests];

  [_delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [FBSDKGraphRequestConnection canMakeRequests],
    "Initializing the SDK should enable making graph requests"
  );
}

- (void)testInitializingSdkEnablesAppEvents
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAppEvents reset];

  [_delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [FBSDKAppEvents canLogEvents],
    "Initializing the SDK should enable event logging"
  );

  XCTAssertEqualObjects(
    FBSDKAppEvents.gateKeeperManager,
    FBSDKGateKeeperManager.class,
    "Initializing the SDK should set gate keeper manager for event logging"
  );
  NSObject *requestProvider = (NSObject *) FBSDKAppEvents.requestProvider;
  XCTAssertEqualObjects(
    requestProvider.class,
    FBSDKGraphRequestFactory.class,
    "Initializing the SDK should set graph request factory for event logging"
  );

  XCTAssertEqualObjects(
    FBSDKAppEvents.appEventsConfigurationProvider,
    FBSDKAppEventsConfigurationManager.class,
    "Initializing the SDK should set AppEvents configuration provider for event logging"
  );
  XCTAssertEqualObjects(
    FBSDKAppEvents.serverConfigurationProvider,
    FBSDKServerConfigurationManager.class,
    "Initializing the SDK should set server configuration provider for event logging"
  );
  NSObject *store = (NSObject *)FBSDKAppEvents.store;
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
  XCTAssertEqualObjects(
    FBSDKAppEvents.featureChecker,
    FBSDKFeatureManager.class,
    "Initializing the SDK should set feature checker for event logging"
  );
  XCTAssertEqualObjects(
    FBSDKAppEvents.logger,
    FBSDKLogger.class,
    "Initializing the SDK should set concrete logger for event logging"
  );
}

- (void)testInitializingSdkConfiguresGateKeeperManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKGateKeeperManager reset];

  [_delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *requestProvider = (NSObject *)FBSDKGateKeeperManager.requestProvider;
  NSObject *connectionProvider = (NSObject *)FBSDKGateKeeperManager.connectionProvider;
  NSObject *settings = (NSObject *)FBSDKGateKeeperManager.settings;
  NSObject *store = (NSObject *)FBSDKGateKeeperManager.store;

  XCTAssertTrue(
    [FBSDKGateKeeperManager canLoadGateKeepers],
    "Initializing the SDK should enable loading gatekeepers"
  );
  XCTAssertEqualObjects(
    settings,
    FBSDKSettings.class,
    "Should be configured with the expected concrete settings"
  );
  XCTAssertEqualObjects(
    requestProvider.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    connectionProvider.class,
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
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *requestProvider = (NSObject *)[FBSDKCodelessIndexer requestProvider];
  XCTAssertEqualObjects(
    requestProvider.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
}

- (void)testInitializingSdkConfiguresAppLinkUtility
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *requestProvider = (NSObject *)[FBSDKAppLinkUtility requestProvider];
  NSObject *infoDictionaryProvider = (NSObject *)[FBSDKAppLinkUtility infoDictionaryProvider];
  XCTAssertEqualObjects(
    requestProvider.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    infoDictionaryProvider.class,
    NSBundle.class,
    "Should be configured with the expected concrete info dictionary provider"
  );
}

- (void)testConfiguringFBSDKSKAdNetworkReporter
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *requestProvider = (NSObject *)[FBSDKSKAdNetworkReporter requestProvider];
  NSObject *store = (NSObject *)[FBSDKSKAdNetworkReporter store];
  XCTAssertEqualObjects(
    requestProvider.class,
    FBSDKGraphRequestFactory.class,
    "Should be configured with the expected concrete graph request provider"
  );
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the standard user defaults"
  );
}

- (void)testInitializingSdkConfiguresAccessTokenCache
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAccessToken setTokenCache:nil];
  [_delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *tokenCache = (NSObject *) FBSDKAccessToken.tokenCache;
  XCTAssertEqualObjects(tokenCache.class, FBSDKTokenCache.class, "Should be configured with expected concrete token cache");
}

- (void)testInitializingSdkConfiguresProfile
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *store = (NSObject *)[FBSDKProfile store];
  NSObject *tokenProvider = (NSObject *)[FBSDKProfile accessTokenProvider];
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
}

- (void)testInitializingSdkConfiguresAuthenticationTokenCache
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKAuthenticationToken setTokenCache:nil];
  [_delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *tokenCache = (NSObject *) FBSDKAuthenticationToken.tokenCache;
  XCTAssertEqualObjects(tokenCache.class, FBSDKTokenCache.class, "Should be configured with expected concrete token cache");
}

- (void)testInitializingSdkConfiguresAccessTokenConnectionFactory
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  FBSDKAccessToken.connectionFactory = nil;
  [_delegate initializeSDKWithLaunchOptions:@{}];

  NSObject *connectionFactory = (NSObject *) FBSDKAccessToken.connectionFactory;
  XCTAssertEqualObjects(
    connectionFactory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "Should be configured with expected concrete graph request connection factory"
  );
}

- (void)testInitializingSdkConfiguresSettings
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [FBSDKSettings reset];
  [_delegate initializeSDKWithLaunchOptions:@{}];

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
    eventLogger.class,
    FBSDKEventLogger.class,
    "Should be configured with the expected concrete event logger"
  );
}

- (void)testInitializingSdkConfiguresInternalUtility
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *infoDictionaryProvider = (NSObject *)[FBSDKInternalUtility infoDictionaryProvider];
  XCTAssertEqualObjects(
    infoDictionaryProvider,
    NSBundle.mainBundle,
    "Should be configured with the expected concrete info dictionary provider"
  );
}

- (void)testInitializingSdkConfiguresGraphRequestPiggybackManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *tokenWallet = (NSObject *) FBSDKGraphRequestPiggybackManager.tokenWallet;
  XCTAssertEqualObjects(
    tokenWallet,
    FBSDKAccessToken.class,
    "Should be configured with the expected concrete access token provider"
  );
}

- (void)testInitializingSdkAddsBridgeApiObserver
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertTrue(
    [_delegate.applicationObservers containsObject:FBSDKBridgeAPI.sharedInstance],
    "Should add the shared bridge api instance to the application observers"
  );
}

- (void)testInitializingSdkPerformsSettingsLogging
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  XCTAssertEqual(
    TestSettings.logWarningsCallCount,
    1,
    "Should have settings log warnings upon initialization"
  );
  XCTAssertEqual(
    TestSettings.logIfSDKSettingsChangedCallCount,
    1,
    "Should have settings log if there were changes upon initialization"
  );
  XCTAssertEqual(
    TestSettings.recordInstallCallCount,
    1,
    "Should have settings record installations upon initialization"
  );
}

- (void)testInitializingSdkConfiguresAppEventsConfigurationManager
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
  NSObject *store = (NSObject *) FBSDKAppEventsConfigurationManager.shared.store;
  XCTAssertEqualObjects(
    store,
    NSUserDefaults.standardUserDefaults,
    "Should be configured with the expected concrete data store"
  );
}

- (void)testInitializingSdkConfiguresCurrentAccessTokenProviderForGraphRequest
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];

  XCTAssertEqualObjects(
    [FBSDKGraphRequest currentAccessTokenStringProvider],
    FBSDKAccessToken.class,
    "Should be configered with expected access token class."
  );
}

- (void)testInitializingSdkConfiguresWebDialogView
{
  [FBSDKApplicationDelegate resetHasInitializeBeenCalled];
  [_delegate initializeSDKWithLaunchOptions:@{}];
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

- (void)testDidFinishLaunchingLaunchedApp
{
  _delegate.isAppLaunched = YES;

  XCTAssertFalse(
    [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil],
    "Should return false if the application is already launched"
  );
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithCache
{
  FBSDKAccessToken *expected = SampleAccessTokens.validToken;
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:expected
                                                  authenticationToken:nil];
  [TestAccessTokenWallet setTokenCache:cache];

  _delegate = [[FBSDKApplicationDelegate alloc] initWithNotificationObserver:[TestNotificationCenter new]
                                                                 tokenWallet:TestAccessTokenWallet.class
                                                                    settings:TestSettings.class];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

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

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

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
  [FBSDKAuthenticationToken setTokenCache:cache];
  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current authentication token to the cached access token when it exists
  OCMVerify(ClassMethod([self.authenticationTokenClassMock setCurrentAuthenticationToken:expected]));
}

- (void)testDidFinishLaunchingSetsCurrentAuthenticationTokenWithoutCache
{
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:nil authenticationToken:nil];
  [FBSDKAuthenticationToken setTokenCache:cache];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current authentication token to nil access token when there isn't a cached token
  OCMVerify(ClassMethod([self.authenticationTokenClassMock setCurrentAuthenticationToken:nil]));
}

- (void)testDidFinishLaunchingLoadsServerConfiguration
{
  [self stubAllocatingGraphRequestConnection];
  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should load the server configuration on finishing launching
  OCMVerify(ClassMethod([self.serverConfigurationManagerClassMock loadServerConfigurationWithCompletionBlock:nil]));
}

- (void)testDidFinishLaunchingWithAutoLogEnabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should log initialization when auto log app events is enabled
  OCMVerify([_partialDelegateMock _logSDKInitialize]);
}

- (void)testDidFinishLaunchingWithAutoLogDisabled
{
  // Should not log initialization when auto log app events are disabled
  OCMReject([_partialDelegateMock _logSDKInitialize]);

  [self stubIsAutoLogAppEventsEnabled:NO];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];
}

- (void)testDidFinishLaunchingSetsProfileWithCache
{
  [self stubCachedProfileWith:_profile];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current profile to the value fetched from the cache
  OCMVerify([self.profileClassMock setCurrentProfile:_profile]);
}

- (void)testDidFinishLaunchingSetsProfileWithoutCache
{
  [self stubCachedProfileWith:nil];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current profile to nil when the cache is empty
  OCMVerify([self.profileClassMock setCurrentProfile:nil]);
}

- (void)testDidFinishLaunchingWithObservers
{
  TestApplicationDelegateObserver *observer1 = [TestApplicationDelegateObserver new];
  TestApplicationDelegateObserver *observer2 = [TestApplicationDelegateObserver new];

  [_delegate addObserver:observer1];
  [_delegate addObserver:observer2];

  BOOL notifiedObservers = [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

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
  BOOL notifiedObservers = [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  XCTAssertFalse(notifiedObservers, "Should indicate if no observers were notified");
}

- (void)testAppEventsEnabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];
  OCMStub(ClassMethod([self.appEventsMock activateApp]));

  id notification = OCMClassMock([NSNotification class]);
  [_delegate applicationDidBecomeActive:notification];

  OCMVerify([self.appEventsMock activateApp]);
}

- (void)testAppEventsDisabled
{
  [self stubIsAutoLogAppEventsEnabled:NO];

  OCMReject([self.appEventsMock activateApp]);
  OCMStub(ClassMethod([self.appEventsMock activateApp]));

  id notification = OCMClassMock([NSNotification class]);
  [_delegate applicationDidBecomeActive:notification];
}

- (void)testAppNotifyObserversWhenAppWillResignActive
{
  id observer = OCMStrictProtocolMock(@protocol(FBSDKApplicationObserving));
  [_delegate addObserver:observer];

  NSNotification *notification = OCMClassMock([NSNotification class]);
  id application = OCMClassMock([UIApplication class]);
  [OCMStub([notification object]) andReturn:application];
  OCMExpect([observer applicationWillResignActive:application]);

  [_delegate applicationWillResignActive:notification];

  OCMVerify([observer applicationWillResignActive:application]);
}

- (void)testSetApplicationState
{
  [_delegate setApplicationState:UIApplicationStateBackground];
  XCTAssertEqual(
    [FBSDKAppEvents applicationState],
    UIApplicationStateBackground,
    "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground"
  );
}

@end
