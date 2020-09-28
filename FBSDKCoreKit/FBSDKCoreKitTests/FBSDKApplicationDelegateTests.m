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

#import "NotificationCenterSpy.h"

#import "AppDelegateObserverFake.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKTestCase.h"
#import "SampleAccessToken.h"
#import "UserDefaultsSpy.h"

@interface FBSDKApplicationDelegate (Testing)

- (BOOL)isAppLaunched;
- (void)setIsAppLaunched:(BOOL)isLaunched;
- (NSHashTable<id<FBSDKApplicationObserving>> *)applicationObservers;
- (void)resetApplicationObserverCache;
- (void)_logSDKInitialize;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;

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

  [self stubAppEventsSingletonWith:self.appEventsMock];
  [self stubLoadingAdNetworkReporterConfiguration];

  [self stubServerConfigurationFetchingWithConfiguration:FBSDKServerConfigurationFixtures.defaultConfig error:nil];
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
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
  [_delegate addObserver:observer];

  XCTAssertEqual(
    [_delegate applicationObservers].count,
    1,
    "Should be able to add a single observer"
  );
}

- (void)testAddingDuplicateObservers
{
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
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
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
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
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
  [_delegate removeObserver:observer];

  XCTAssertEqual(
    _delegate.applicationObservers.count,
    0,
    "Should not be able to remove absent observers"
  );
}

// MARK: - Lifecycle Methods

- (void)testDidFinishLaunchingLaunchedApp
{
  _delegate.isAppLaunched = YES;

  XCTAssertFalse(
    [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil],
    "Should return false if the application is already launched"
  );
  // TODO: check that side effects do not occur
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithCache
{
  FBSDKAccessToken *expected = SampleAccessToken.validToken;
  FakeAccessTokenCache *cache = [[FakeAccessTokenCache alloc] initWithToken:expected];
  [self stubAccessTokenCacheWith:cache];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current access token to the cached access token when it exists
  OCMVerify(ClassMethod([self.accessTokenClassMock setCurrentAccessToken:expected]));
}

- (void)testDidFinishLaunchingSetsCurrentAccessTokenWithoutCache
{
  [self stubAccessTokenCacheWith:[[FakeAccessTokenCache alloc] initWithToken:nil]];

  [_delegate application:UIApplication.sharedApplication didFinishLaunchingWithOptions:nil];

  // Should set the current access token to nil access token when there isn't a cached token
  OCMVerify(ClassMethod([self.accessTokenClassMock setCurrentAccessToken:nil]));
}

- (void)testDidFinishLaunchingLoadsServerConfiguration
{
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
  ApplicationDelegateObserverFake *observer1 = [ApplicationDelegateObserverFake new];
  ApplicationDelegateObserverFake *observer2 = [ApplicationDelegateObserverFake new];

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

- (void)testDidFinishLaunchingCalledFromAutoInit
{
  // Should not log that the SDK implements didFinishLaunching manually
  OCMReject(
    ClassMethod(
      [self.appEventsMock logInternalEvent:@"fb_sdk_implements_did_finish_launching"
                                parameters:@{}
                        isImplicitlyLogged:OCMOCK_VALUE(YES)]
    )
  );

  // Stub all the dependencies of initializing SDK
  [self stubFBApplicationDelegateSharedInstanceWith:_delegate];
  [self stubRegisterAppForAdNetworkAttribution];
  [self stubDefaultNotificationCenterWith:_notificationCenterSpy];
  OCMStub([_partialDelegateMock applicationDidBecomeActive:UIApplication.sharedApplication]);
  [self stubCheckingFeatures];
  [self stubDefaultMeasurementEventListenerWith:[FBSDKMeasurementEventListener new]];
  [self stubCachedProfileWith:nil];
  OCMStub([self.timeSpentDataClassMock setSourceApplication:OCMArg.any openURL:OCMArg.any]);
  OCMStub([self.timeSpentDataClassMock registerAutoResetSourceApplication]);
  OCMStub([self.internalUtilityClassMock validateFacebookReservedURLSchemes]);

  NSDictionary *launchOptions = @{};
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
  [_delegate addObserver:observer];
  [FBSDKApplicationDelegate initializeSDK:launchOptions];

  XCTAssertEqualObjects(observer.capturedLaunchOptions, @{}, "Observers should not be passed the modified launch arguments.");
  // Should Modify the launch arguments when didFinishLaunching is invoked from the `initializeSDK` method
  OCMVerify(
    [_partialDelegateMock application:UIApplication.sharedApplication
        didFinishLaunchingWithOptions:@{@"_calledFromAutoInitSDK" : @YES}]
  );
}

- (void)testDidFinishLaunchingCalledManually
{
  NSDictionary *launchOptions = @{@"foo" : @"bar"};
  ApplicationDelegateObserverFake *observer = [ApplicationDelegateObserverFake new];
  [_delegate addObserver:observer];
  [FBSDKApplicationDelegate.sharedInstance application:UIApplication.sharedApplication
                         didFinishLaunchingWithOptions:launchOptions];

  XCTAssertEqualObjects(observer.capturedLaunchOptions, @{@"foo" : @"bar"}, "Observers should not be passed modified launch arguments.");
  OCMVerify(
    ClassMethod(
      [self.appEventsMock logInternalEvent:@"fb_sdk_implements_did_finish_launching"
                                parameters:@{}
                        isImplicitlyLogged:OCMOCK_VALUE(YES)]
    )
  );
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

@end
