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

#import "FBSDKAppEvents.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKTestCase.h"
#import "UserDefaultsSpy.h"

@interface FBSDKGraphRequestConnection (AppDelegateTesting)
+ (BOOL)canMakeRequests;
+ (void)resetCanMakeRequests;
@end

@interface FBSDKApplicationDelegate (Testing)

+ (void)resetIsSdkInitialized;

- (BOOL)isAppLaunched;
- (void)setIsAppLaunched:(BOOL)isLaunched;
- (NSHashTable<id<FBSDKApplicationObserving>> *)applicationObservers;
- (void)resetApplicationObserverCache;
- (void)_logSDKInitialize;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)setApplicationState:(UIApplicationState)state;

@end

@interface FBSDKBridgeAPI (ApplicationObserving) <FBSDKApplicationObserving>
@end

@interface FBSDKApplicationDelegateTests : FBSDKTestCase
{
  FBSDKApplicationDelegate *_delegate;
  UserDefaultsSpy *_defaultsSpy;
  FBSDKProfile *_profile;
  id _partialDelegateMock;
  NotificationCenterSpy *_notificationCenterSpy;
}
@end

@interface FBSDKAppEvents (Testing)
+ (UIApplicationState)applicationState;
+ (void)resetCanLogEvents;
+ (BOOL)canLogEvents;
@end

@implementation FBSDKApplicationDelegateTests

- (void)setUp
{
  [super setUp];

  _delegate = FBSDKApplicationDelegate.sharedInstance;
  _delegate.isAppLaunched = NO;

  _defaultsSpy = [UserDefaultsSpy new];
  [self stubUserDefaultsWith:_defaultsSpy];

  _notificationCenterSpy = [NotificationCenterSpy new];
  [self stubDefaultNotificationCenterWith:_notificationCenterSpy];

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

  _defaultsSpy = nil;
  _profile = nil;

  [_partialDelegateMock stopMocking];
  _partialDelegateMock = nil;
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
  [FBSDKApplicationDelegate resetIsSdkInitialized];
  [FBSDKGraphRequestConnection resetCanMakeRequests];

  [FBSDKApplicationDelegate initializeSDK:@{}];

  XCTAssertTrue(
    [FBSDKGraphRequestConnection canMakeRequests],
    "Initializing the SDK should enable making graph requests"
  );
}

- (void)testInitializingSdkEnablesLogEvents
{
  [FBSDKApplicationDelegate resetIsSdkInitialized];
  [FBSDKAppEvents resetCanLogEvents];

  [FBSDKApplicationDelegate initializeSDK:@{}];

  XCTAssertTrue(
    [FBSDKAppEvents canLogEvents],
    "Initializing the SDK should enable event logging"
  );
}

- (void)testInitializingSdkConfiguresGateKeeperManager
{
  [FBSDKApplicationDelegate resetIsSdkInitialized];
  [FBSDKGateKeeperManager reset];

  [FBSDKApplicationDelegate initializeSDK:@{}];

  NSObject *requestProvider = (NSObject *)FBSDKGateKeeperManager.requestProvider;
  NSObject *settings = (NSObject *)FBSDKGateKeeperManager.settings;

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
  FBSDKAccessToken *expected = SampleAccessToken.validToken;
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:expected
                                                  authenticationToken:nil];
  [self stubTokenCacheWith:cache];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current access token to the cached access token when it exists
  OCMVerify(ClassMethod([self.accessTokenClassMock setCurrentAccessToken:expected]));
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithoutCache
{
  [self stubTokenCacheWith:[[TestTokenCache alloc] initWithAccessToken:nil authenticationToken:nil]];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current access token to nil access token when there isn't a cached token
  OCMVerify(ClassMethod([self.accessTokenClassMock setCurrentAccessToken:nil]));
}

- (void)testDidFinishLaunchingSetsCurrentAuthenticationTokenWithCache
{
  FBSDKAuthenticationToken *expected = SampleAuthenticationToken.validToken;
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:nil
                                                  authenticationToken:expected];
  [self stubTokenCacheWith:cache];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current authentication token to the cached access token when it exists
  OCMVerify(ClassMethod([self.authenticationTokenClassMock setCurrentAuthenticationToken:expected]));
}

- (void)testDidFinishLaunchingSetsCurrentAuthenticationTokenWithoutCache
{
  TestTokenCache *cache = [[TestTokenCache alloc] initWithAccessToken:nil authenticationToken:nil];
  [self stubTokenCacheWith:cache];

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
  XCTAssertEqual([FBSDKAppEvents applicationState], UIApplicationStateBackground, "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground");
}

@end
