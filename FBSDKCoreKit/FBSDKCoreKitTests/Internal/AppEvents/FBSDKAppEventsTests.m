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

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEvents+SourceApplicationTracking.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitAEMImport.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKUtility.h"

// An extension that redeclares a private method so that it can be mocked
@interface FBSDKApplicationDelegate (Testing)
- (void)_logSDKInitialize;
@end

@interface FBSDKAppEvents (Testing)
@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;
@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;

- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;

- (void)publishInstall;
- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)fetchServerConfiguration:(FBSDKCodeBlock)callback;
- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;
- (void)applicationDidBecomeActive;
- (void)applicationMovingFromActiveStateOrTerminating;
- (void)setFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior;
- (void)publishATE;

+ (FBSDKAppEvents *)singleton;
+ (void)setSingletonInstanceToInstance:(FBSDKAppEvents *)appEvents;
+ (void)reset;

+ (UIApplicationState)applicationState;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logInternalEvent:(NSString *)eventName
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
             accessToken:(FBSDKAccessToken *)accessToken;

@end

@interface FBSDKAppEventsTests : XCTestCase

@property (nonnull, nonatomic) NSString *const mockAppID;
@property (nonnull, nonatomic) NSString *const mockUserID;
@property (nonnull, nonatomic) NSString *eventName;
@property (nonnull, nonatomic) NSDictionary<NSString *, id> *payload;
@property (nonatomic) double purchaseAmount;
@property (nonnull, nonatomic) NSString *currency;
@property (nonnull, nonatomic) TestAtePublisherFactory *atePublisherFactory;
@property (nonnull, nonatomic) TestAtePublisher *atePublisher;
@property (nonnull, nonatomic) TestTimeSpentRecorderFactory *timeSpentRecorderFactory;
@property (nonnull, nonatomic) TestTimeSpentRecorder *timeSpentRecorder;
@property (nonnull, nonatomic) TestAppEventsParameterProcessor *integrityParametersProcessor;
@property (nonnull, nonatomic) TestGraphRequestFactory *graphRequestFactory;
@property (nonnull, nonatomic) UserDefaultsSpy *store;
@property (nonnull, nonatomic) TestFeatureManager *featureManager;
@property (nonnull, nonatomic) TestSettings *settings;
@property (nonnull, nonatomic) TestOnDeviceMLModelManager *onDeviceMLModelManager;
@property (nonnull, nonatomic) TestPaymentObserver *paymentObserver;
@property (nonnull, nonatomic) TestAppEventsStateStore *appEventsStateStore;
@property (nonnull, nonatomic) TestMetadataIndexer *metadataIndexer;
@property (nonnull, nonatomic) TestAppEventsParameterProcessor *eventDeactivationParameterProcessor;
@property (nonnull, nonatomic) TestAppEventsParameterProcessor *restrictiveDataFilterParameterProcessor;
@property (nonnull, nonatomic) TestAppEventsStateProvider *appEventsStateProvider;
@property (nonnull, nonatomic) TestAdvertiserIDProvider *advertiserIDProvider;
@property (nonnull, nonatomic) TestAppEventsReporter *skAdNetworkReporter;
@property (nonnull, nonatomic) TestServerConfigurationProvider *serverConfigurationProvider;

@end

@implementation FBSDKAppEventsTests

+ (void)setUp
{
  [super setUp];

  [FBSDKAppEvents reset];
}

- (void)setUp
{
  [super setUp];

  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                                       flushPeriodInSeconds:0];
  [FBSDKAppEvents setSingletonInstanceToInstance:appEvents];

  [self resetTestHelpers];
  self.settings = [TestSettings new];
  self.settings.stubbedIsAutoLogAppEventsEnabled = YES;
  [FBSDKInternalUtility reset];
  self.integrityParametersProcessor = [TestAppEventsParameterProcessor new];
  self.onDeviceMLModelManager = [TestOnDeviceMLModelManager new];
  self.onDeviceMLModelManager.integrityParametersProcessor = self.integrityParametersProcessor;
  self.paymentObserver = [TestPaymentObserver new];
  self.metadataIndexer = [TestMetadataIndexer new];

  self.mockAppID = @"mockAppID";
  self.mockUserID = @"mockUserID";
  self.eventName = @"fb_mock_event";
  self.payload = @{@"fb_push_payload" : @{@"campaign" : @"testCampaign"}};
  self.purchaseAmount = 1.0;
  self.currency = @"USD";
  self.graphRequestFactory = [TestGraphRequestFactory new];
  self.store = [UserDefaultsSpy new];
  self.featureManager = [TestFeatureManager new];
  self.paymentObserver = [TestPaymentObserver new];
  self.appEventsStateStore = [TestAppEventsStateStore new];
  self.eventDeactivationParameterProcessor = [TestAppEventsParameterProcessor new];
  self.restrictiveDataFilterParameterProcessor = [TestAppEventsParameterProcessor new];
  self.appEventsStateProvider = [TestAppEventsStateProvider new];
  self.atePublisherFactory = [TestAtePublisherFactory new];
  self.timeSpentRecorderFactory = [TestTimeSpentRecorderFactory new];
  self.timeSpentRecorder = self.timeSpentRecorderFactory.recorder;
  self.advertiserIDProvider = [TestAdvertiserIDProvider new];
  self.skAdNetworkReporter = [TestAppEventsReporter new];
  self.serverConfigurationProvider = [[TestServerConfigurationProvider alloc]
                                      initWithConfiguration:ServerConfigurationFixtures.defaultConfig];

  // Must be stubbed before the configure method is called
  self.atePublisher = [TestAtePublisher new];
  self.atePublisherFactory.stubbedPublisher = self.atePublisher;

  [self configureAppEventsSingleton];

  [FBSDKAppEvents setLoggingOverrideAppID:self.mockAppID];
}

- (void)tearDown
{
  [FBSDKSettings reset];
  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestGateKeeperManager reset];

  [super tearDown];
}

- (void)resetTestHelpers
{
  [TestSettings reset];
  [TestLogger reset];
}

- (void)configureAppEventsSingleton
{
  [FBSDKAppEvents.singleton configureWithGateKeeperManager:TestGateKeeperManager.class
                            appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
                               serverConfigurationProvider:self.serverConfigurationProvider
                                      graphRequestProvider:self.graphRequestFactory
                                            featureChecker:self.featureManager
                                                     store:self.store
                                                    logger:TestLogger.class
                                                  settings:self.settings
                                           paymentObserver:self.paymentObserver
                                  timeSpentRecorderFactory:self.timeSpentRecorderFactory
                                       appEventsStateStore:self.appEventsStateStore
                       eventDeactivationParameterProcessor:self.eventDeactivationParameterProcessor
                   restrictiveDataFilterParameterProcessor:self.restrictiveDataFilterParameterProcessor
                                       atePublisherFactory:self.atePublisherFactory
                                    appEventsStateProvider:self.appEventsStateProvider
                                                  swizzler:TestSwizzler.class
                                      advertiserIDProvider:self.advertiserIDProvider];

  [FBSDKAppEvents.singleton configureNonTVComponentsWithOnDeviceMLModelManager:self.onDeviceMLModelManager
                                                               metadataIndexer:self.metadataIndexer
                                                           skAdNetworkReporter:self.skAdNetworkReporter];
}

- (void)testConfiguringSetsSwizzlerDependency
{
  XCTAssertEqualObjects(
    FBSDKAppEvents.singleton.swizzler,
    TestSwizzler.class,
    "Configuring should set the provided swizzler"
  );
}

- (void)testConfiguringCreatesAtePublisher
{
  XCTAssertEqualObjects(
    self.atePublisherFactory.capturedAppID,
    self.mockAppID,
    "Configuring should create an ate publisher with the expected app id"
  );
  XCTAssertEqualObjects(
    FBSDKAppEvents.singleton.atePublisher,
    self.atePublisher,
    "Should store the publisher created by the publisher factory"
  );
}

- (void)testPublishingATEWithNilPublisher
{
  self.atePublisherFactory.stubbedPublisher = nil;
  [self configureAppEventsSingleton];

  XCTAssertNil(FBSDKAppEvents.singleton.atePublisher);

  // Make sure the factory can create a publisher
  self.atePublisherFactory.stubbedPublisher = self.atePublisher;
  [FBSDKAppEvents.singleton publishATE];

  XCTAssertNotNil(
    FBSDKAppEvents.singleton.atePublisher,
    "Will lazily create an ate publisher when needed"
  );
}

- (void)testLogPurchaseFlushesWhenFlushBehaviorIsExplicit
{
  FBSDKAppEvents.flushBehavior = FBSDKAppEventsFlushBehaviorAuto;
  [FBSDKAppEvents logPurchase:self.purchaseAmount currency:self.currency];

  // Verifying flush
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedRequests.firstObject.graphPath,
    @"mockAppID/activities"
  );
}

- (void)testLogPurchase
{
  [FBSDKAppEvents logPurchase:self.purchaseAmount currency:self.currency];

  XCTAssertEqual(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_eventName"],
    FBSDKAppEventNamePurchased,
    "Should log an event with the expected event name"
  );
  XCTAssertEqual(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_valueToSum"],
    @(self.purchaseAmount),
    "Should log an event with the expected purchase amount"
  );
  XCTAssertEqualObjects(
    self.appEventsStateProvider.state.capturedEventDictionary[@"fb_currency"],
    self.currency,
    "Should log an event with the expected currency"
  );
  XCTAssertTrue(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Should add events to AppEventsState when logging purshase"
  );
  XCTAssertFalse(
    self.appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly add events to AppEventsState when logging purshase"
  );
}

- (void)testFlush
{
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id _Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
    // A not-the-best proxy to determine if a flush occurred.
    return TestAppEventsConfigurationProvider.capturedBlock != nil;
  }];
  XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];

  [FBSDKAppEvents logEvent:@"foo"];
  [FBSDKAppEvents flush];

  [self waitForExpectations:@[expectation] timeout:2];
}

#pragma mark  Tests for log product item

- (void)testLogProductItemNonNil
{
  [FBSDKAppEvents logProductItem:@"F40CEE4E-471E-45DB-8541-1526043F4B21"
                    availability:FBSDKProductAvailabilityInStock
                       condition:FBSDKProductConditionNew
                     description:@"description"
                       imageLink:@"https://www.sample.com"
                            link:@"https://www.sample.com"
                           title:@"title"
                     priceAmount:1.0
                        currency:@"USD"
                            gtin:@"BLUE MOUNTAIN"
                             mpn:@"BLUE MOUNTAIN"
                           brand:@"PHILZ"
                      parameters:@{}];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], @"fb_mobile_catalog_update");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_availability"], @"IN_STOCK");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_brand"], @"PHILZ");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_condition"], @"NEW");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_description"], @"description");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_gtin"], @"BLUE MOUNTAIN");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_image_link"], @"https://www.sample.com");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_item_id"], @"F40CEE4E-471E-45DB-8541-1526043F4B21");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_link"], @"https://www.sample.com");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_mpn"], @"BLUE MOUNTAIN");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_price_amount"], @"1.000");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_price_currency"], @"USD");
  XCTAssertEqualObjects(capturedParameters[@"fb_product_title"], @"title");
}

- (void)testLogProductItemNilGtinMpnBrand
{
  [FBSDKAppEvents logProductItem:@"F40CEE4E-471E-45DB-8541-1526043F4B21"
                    availability:FBSDKProductAvailabilityInStock
                       condition:FBSDKProductConditionNew
                     description:@"description"
                       imageLink:@"https://www.sample.com"
                            link:@"https://www.sample.com"
                           title:@"title"
                     priceAmount:1.0
                        currency:@"USD"
                            gtin:nil
                             mpn:nil
                           brand:nil
                      parameters:@{}];

  XCTAssertNil(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_eventName"],
    "Should not log a product item when key fields are missing"
  );
  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "A log entry of LoggingBehaviorDeveloperErrors should be posted when some parameters are nil for logProductItem"
  );
}

#pragma mark  Tests for set and clear user data

- (void)testSetAndClearUserData
{
  NSString *mockEmail = @"test_em";
  NSString *mockFirstName = @"test_fn";
  NSString *mockLastName = @"test_ln";
  NSString *mockPhone = @"123";

  [FBSDKAppEvents setUserEmail:mockEmail
                     firstName:mockFirstName
                      lastName:mockLastName
                         phone:mockPhone
                   dateOfBirth:nil
                        gender:nil
                          city:nil
                         state:nil
                           zip:nil
                       country:nil];

  NSDictionary<NSString *, NSString *> *expectedUserData = @{@"em" : [FBSDKUtility SHA256Hash:mockEmail],
                                                             @"fn" : [FBSDKUtility SHA256Hash:mockFirstName],
                                                             @"ln" : [FBSDKUtility SHA256Hash:mockLastName],
                                                             @"ph" : [FBSDKUtility SHA256Hash:mockPhone], };
  NSDictionary<NSString *, NSString *> *userData = (NSDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[[FBSDKAppEvents getUserData] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                          options: NSJSONReadingMutableContainers
                                                                                          error: nil];
  XCTAssertEqualObjects(userData, expectedUserData);

  [FBSDKAppEvents clearUserData];
  NSString *clearedUserData = [FBSDKAppEvents getUserData];
  XCTAssertEqualObjects(clearedUserData, @"{}");
}

- (void)testSetAndClearUserDataForType
{
  NSString *testEmail = @"apptest@fb.com";
  NSString *hashedEmailString = [FBSDKUtility SHA256Hash:testEmail];

  [FBSDKAppEvents setUserData:testEmail forType:FBSDKAppEventEmail];
  NSString *userData = [FBSDKAppEvents getUserData];
  XCTAssertTrue([userData containsString:@"em"]);
  XCTAssertTrue([userData containsString:hashedEmailString]);

  [FBSDKAppEvents clearUserDataForType:FBSDKAppEventEmail];
  userData = [FBSDKAppEvents getUserData];
  XCTAssertFalse([userData containsString:@"em"]);
  XCTAssertFalse([userData containsString:hashedEmailString]);
}

- (void)testSetAndClearUserID
{
  [FBSDKAppEvents setUserID:self.mockUserID];
  XCTAssertEqualObjects([FBSDKAppEvents userID], self.mockUserID);
  [FBSDKAppEvents clearUserID];
  XCTAssertNil([FBSDKAppEvents userID]);
}

- (void)testSetLoggingOverrideAppID
{
  NSString *mockOverrideAppID = @"2";
  [FBSDKAppEvents setLoggingOverrideAppID:mockOverrideAppID];
  XCTAssertEqualObjects([FBSDKAppEvents loggingOverrideAppID], mockOverrideAppID);
}

- (void)testSetPushNotificationsDeviceTokenString
{
  NSString *mockDeviceTokenString = @"testDeviceTokenString";
  self.eventName = @"fb_mobile_obtain_push_token";

  [FBSDKAppEvents setPushNotificationsDeviceTokenString:mockDeviceTokenString];

  XCTAssertEqualObjects(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_eventName"],
    self.eventName
  );
  XCTAssertEqualObjects([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testActivateAppWithInitializedSDK
{
  [FBSDKAppEvents.singleton activateApp];

  XCTAssertTrue(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App with initialized SDK should restore recording time spent data."
  );
  XCTAssertTrue(
    self.timeSpentRecorder.capturedCalledFromActivateApp,
    "Activating App with initialized SDK should indicate its calling from activateApp when restoring recording time spent data."
  );

  // The publish call happens after both configs are fetched
  TestAppEventsConfigurationProvider.capturedBlock();
  TestAppEventsConfigurationProvider.secondCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  self.serverConfigurationProvider.secondCapturedCompletionBlock(nil, nil);

  TestGraphRequest *request = self.graphRequestFactory.capturedRequests.firstObject;
  XCTAssertEqualObjects(request.parameters[@"event"], @"MOBILE_APP_INSTALL");
}

- (void)testApplicationBecomingActiveRestoresTimeSpentRecording
{
  [FBSDKAppEvents.singleton applicationDidBecomeActive];
  XCTAssertTrue(
    self.timeSpentRecorder.restoreWasCalled,
    "When application did become active, the time spent recording should be restored."
  );
  XCTAssertFalse(
    self.timeSpentRecorder.capturedCalledFromActivateApp,
    "When application did become active, the time spent recording restoration should be indicated that it's not activating."
  );
}

- (void)testApplicationTerminatingSuspendsTimeSpentRecording
{
  [FBSDKAppEvents.singleton applicationMovingFromActiveStateOrTerminating];
  XCTAssertTrue(
    self.timeSpentRecorder.suspendWasCalled,
    "When application terminates or moves from active state, the time spent recording should be suspended."
  );
}

- (void)testApplicationTerminatingPersistingStates
{
  [FBSDKAppEvents.singleton setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  [FBSDKAppEvents.singleton applicationMovingFromActiveStateOrTerminating];

  XCTAssertTrue(
    self.appEventsStateStore.capturedPersistedState.count > 0,
    "When application terminates or moves from active state, the existing state should be persisted."
  );
}

- (void)testUsingAppEventsWithUninitializedSDK
{
  NSString *foo = @"foo";
  [FBSDKAppEvents reset];
  FBSDKAppEvents *events = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                                    flushPeriodInSeconds:0];
  XCTAssertThrows([FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorAuto]);
  XCTAssertThrows([FBSDKAppEvents setLoggingOverrideAppID:self.name]);
  XCTAssertThrows([FBSDKAppEvents logEvent:FBSDKAppEventNameSearched]);
  XCTAssertThrows([FBSDKAppEvents logEvent:FBSDKAppEventNameSearched valueToSum:2]);
  XCTAssertThrows([FBSDKAppEvents logEvent:FBSDKAppEventNameSearched parameters:@{}]);
  XCTAssertThrows(
    [FBSDKAppEvents logEvent:FBSDKAppEventNameSearched
                  valueToSum:2
                  parameters:@{}]
  );
  XCTAssertThrows(
    [FBSDKAppEvents logEvent:FBSDKAppEventNameSearched
                  valueToSum:@2
                  parameters:@{}
                 accessToken:SampleAccessTokens.validToken]
  );
  XCTAssertThrows([FBSDKAppEvents logPurchase:2 currency:foo]);
  XCTAssertThrows(
    [FBSDKAppEvents logPurchase:2
                       currency:foo
                     parameters:@{}]
  );
  XCTAssertThrows(
    [FBSDKAppEvents logPurchase:2
                       currency:foo
                     parameters:@{}
                    accessToken:SampleAccessTokens.validToken]
  );
  XCTAssertThrows([FBSDKAppEvents logPushNotificationOpen:@{}]);
  XCTAssertThrows([FBSDKAppEvents logPushNotificationOpen:@{} action:foo]);
  XCTAssertThrows(
    [FBSDKAppEvents logProductItem:foo
                      availability:FBSDKProductAvailabilityInStock
                         condition:FBSDKProductConditionNew
                       description:foo
                         imageLink:foo
                              link:foo
                             title:foo
                       priceAmount:1
                          currency:foo
                              gtin:nil
                               mpn:nil
                             brand:nil
                        parameters:@{}]
  );
  XCTAssertThrows([FBSDKAppEvents setPushNotificationsDeviceToken:[NSData new]]);
  XCTAssertThrows([FBSDKAppEvents setPushNotificationsDeviceTokenString:foo]);
  XCTAssertThrows([FBSDKAppEvents flush]);
  XCTAssertThrows([FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken]);
  XCTAssertThrows([FBSDKAppEvents augmentHybridWKWebView:[WKWebView new]]);
  XCTAssertThrows([FBSDKAppEvents sendEventBindingsToUnity]);
  XCTAssertThrows([events activateApp]);
  XCTAssertThrows([FBSDKAppEvents clearUserID]);
  XCTAssertThrows(FBSDKAppEvents.userID);
  XCTAssertThrows([FBSDKAppEvents setUserID:foo]);

  XCTAssertNoThrow([FBSDKAppEvents setIsUnityInit:YES]);
  XCTAssertNoThrow(FBSDKAppEvents.anonymousID);
  XCTAssertNoThrow([FBSDKAppEvents setUserData:foo forType:foo]);
  XCTAssertNoThrow(
    [FBSDKAppEvents setUserEmail:nil
                       firstName:nil
                        lastName:nil
                           phone:nil
                     dateOfBirth:nil
                          gender:nil
                            city:nil
                           state:nil
                             zip:nil
                         country:nil]
  );
  XCTAssertNoThrow([FBSDKAppEvents getUserData]);
  XCTAssertNoThrow([FBSDKAppEvents clearUserDataForType:foo]);

  XCTAssertFalse(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App without initialized SDK cannot restore recording time spent data."
  );
}

- (void)testInstanceLogEventFilteringOutDeactivatedParameters
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:parameters
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  XCTAssertEqualObjects(
    self.eventDeactivationParameterProcessor.capturedEventName,
    self.eventName,
    "AppEvents instance should submit the event name to event deactivation parameters processor."
  );
  XCTAssertEqualObjects(
    self.eventDeactivationParameterProcessor.capturedParameters,
    parameters,
    "AppEvents instance should submit the parameters to event deactivation parameters processor."
  );
}

- (void)testInstanceLogEventProcessParametersWithRestrictiveDataFilterParameterProcessor
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:parameters
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  XCTAssertEqualObjects(
    self.restrictiveDataFilterParameterProcessor.capturedEventName,
    self.eventName,
    "AppEvents instance should submit the event name to the restrictive data filter parameters processor."
  );
  XCTAssertEqualObjects(
    self.restrictiveDataFilterParameterProcessor.capturedParameters,
    parameters,
    "AppEvents instance should submit the parameters to the restrictive data filter parameters processor."
  );
}

#pragma mark  Test for log push notification

- (void)testLogPushNotificationOpen
{
  self.eventName = @"fb_mobile_push_opened";

  [FBSDKAppEvents logPushNotificationOpen:self.payload action:@"testAction"];
  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"fb_push_action"], @"testAction");
  XCTAssertEqualObjects(capturedParameters[@"fb_push_campaign"], @"testCampaign");
}

- (void)testLogPushNotificationOpenWithEmptyAction
{
  self.eventName = @"fb_mobile_push_opened";

  [FBSDKAppEvents logPushNotificationOpen:self.payload];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertNil(capturedParameters[@"fb_push_action"]);
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"fb_push_campaign"], @"testCampaign");
}

- (void)testLogPushNotificationOpenWithEmptyPayload
{
  [FBSDKAppEvents logPushNotificationOpen:@{}];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
}

- (void)testLogPushNotificationOpenWithEmptyCampaign
{
  self.payload = @{@"fb_push_payload" : @{@"campaign" : @""}};
  [FBSDKAppEvents logPushNotificationOpen:self.payload];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "A log entry of LoggingBehaviorDeveloperErrors should be posted if logPushNotificationOpen is fed with empty campagin"
  );
}

- (void)testSetFlushBehavior
{
  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorAuto];
  XCTAssertEqual(FBSDKAppEventsFlushBehaviorAuto, FBSDKAppEvents.flushBehavior);

  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  XCTAssertEqual(FBSDKAppEventsFlushBehaviorExplicitOnly, FBSDKAppEvents.flushBehavior);
}

- (void)testCheckPersistedEventsCalledWhenLogEvent
{
  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(self.purchaseAmount) parameters:@{} accessToken:nil];

  XCTAssertTrue(
    self.appEventsStateStore.retrievePersistedAppEventStatesWasCalled,
    "Should retrieve persisted states when logEvent was called and flush behavior was FlushReasonEagerlyFlushingEvent"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithTrackingDisallowed
{
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken],
    "Should not create a request for third party id if tracking is disallowed even if there is a current access token"
  );
  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if tracking is disallowed"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithLimitedEventAndDataUsage
{
  self.settings.stubbedLimitEventAndDataUsage = YES;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken],
    "Should not create a request for third party id if event and data usage is limited even if there is a current access token"
  );
  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if event and data usage is limited"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithoutAdvertiserID
{
  self.settings.stubbedLimitEventAndDataUsage = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if there is no access token or advertiser id"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID
{
  NSString *advertiserID = @"abc123";
  self.settings.stubbedLimitEventAndDataUsage = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  self.advertiserIDProvider.advertiserID = advertiserID;

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil];
  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedParameters,
    @{ @"udid" : advertiserID },
    "Should include the udid in the request when there is no access token available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithoutAdvertiserID
{
  FBSDKAccessToken *token = SampleAccessTokens.validToken;
  self.settings.stubbedLimitEventAndDataUsage = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  [FBSDKAppEvents setLoggingOverrideAppID:token.appID];

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];
  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedTokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    self.graphRequestFactory.capturedParameters[@"udid"],
    "Should not include the udid in the request when there is none available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithAdvertiserID
{
  FBSDKAccessToken *token = SampleAccessTokens.validToken;
  [FBSDKAppEvents setLoggingOverrideAppID:token.appID];
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", token.appID];
  NSString *advertiserID = @"abc123";
  self.settings.stubbedLimitEventAndDataUsage = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  self.advertiserIDProvider.advertiserID = advertiserID;

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];

  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedTokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    self.graphRequestFactory.capturedParameters[@"udid"],
    "Should not include the udid in the request when there is an access token available"
  );
  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedGraphPath,
    expectedGraphPath,
    "Should use the expected graph path for the request"
  );
  XCTAssertEqual(
    self.graphRequestFactory.capturedHttpMethod,
    FBSDKHTTPMethodGET,
    "Should use the expected http method for the request"
  );
  XCTAssertEqual(
    self.graphRequestFactory.capturedFlags,
    FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery,
    "Should use the expected flags for the request"
  );
}

- (void)testPublishInstall
{
  [FBSDKAppEvents.singleton publishInstall];

  XCTAssertNotNil(
    TestAppEventsConfigurationProvider.capturedBlock,
    "Should fetch a configuration before publishing installs"
  );
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];

  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];

  XCTAssertTrue(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Should add events to AppEventsState when killswitch is disabled"
  );
  XCTAssertFalse(
    self.appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly add events to AppEventsState when killswitch is disabled"
  );
}

- (void)testAppEventsKillSwitchEnabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:YES];

  [FBSDKAppEvents.singleton instanceLogEvent:self.eventName
                                  valueToSum:@(self.purchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];

  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];
  XCTAssertFalse(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Shouldn't add events to AppEventsState when killswitch is enabled"
  );
}

#pragma mark  Tests for log event

- (void)testLogEventWithValueToSum
{
  [FBSDKAppEvents logEvent:self.eventName valueToSum:self.purchaseAmount];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @1);
}

- (void)testLogInternalEvents
{
  [FBSDKAppEvents logInternalEvent:self.eventName isImplicitlyLogged:NO];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertNil(capturedParameters[@"_valueToSum"]);
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
}

- (void)testLogInternalEventsWithValue
{
  [FBSDKAppEvents logInternalEvent:self.eventName valueToSum:self.purchaseAmount isImplicitlyLogged:NO];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
}

- (void)testLogInternalEventWithAccessToken
{
  [FBSDKAppEvents logInternalEvent:self.eventName parameters:@{} isImplicitlyLogged:NO accessToken:SampleAccessTokens.validToken];

  XCTAssertEqualObjects(self.appEventsStateProvider.capturedAppID, self.mockAppID);
  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertNil(capturedParameters[@"_valueToSum"]);
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
}

- (void)testInstanceLogEventWhenAutoLogAppEventsDisabled
{
  self.settings.stubbedIsAutoLogAppEventsEnabled = NO;
  [FBSDKAppEvents logInternalEvent:self.eventName valueToSum:self.purchaseAmount isImplicitlyLogged:NO];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
}

- (void)testLogEventWillRecordAndUpdateWithSKAdNetworkReporter
{
  if (@available(iOS 11.3, *)) {
    [FBSDKAppEvents logEvent:self.eventName valueToSum:self.purchaseAmount];
    XCTAssertEqualObjects(
      self.eventName,
      self.skAdNetworkReporter.capturedEvent,
      "Logging a event should invoke the SKAdNetwork reporter with the expected event name"
    );
    XCTAssertEqualObjects(
      @(self.purchaseAmount),
      self.skAdNetworkReporter.capturedValue,
      "Logging a event should invoke the SKAdNetwork reporter with the expected event value"
    );
  }
}

- (void)testLogImplicitEvent
{
  [FBSDKAppEvents logImplicitEvent:self.eventName valueToSum:@(self.purchaseAmount) parameters:@{} accessToken:nil];

  NSDictionary *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertEqualObjects(capturedParameters[@"_implicitlyLogged"], @"1");
}

#pragma mark ParameterProcessing

- (void)testLoggingEventWithoutIntegrityParametersProcessor
{
  self.onDeviceMLModelManager.integrityParametersProcessor = nil;

  [FBSDKAppEvents.singleton logEvent:@"event" parameters:@{@"foo" : @"bar"}];

  XCTAssertTrue(
    [TestLogger.capturedLogEntry containsString:@"foo = bar"],
    "Should not try to use a nil processor to filter the parameters"
  );
}

- (void)testLoggingEventWithIntegrityParametersProcessor
{
  NSDictionary *parameters = @{@"foo" : @"bar"};
  [FBSDKAppEvents.singleton logEvent:@"event" parameters:parameters];

  XCTAssertEqualObjects(
    self.integrityParametersProcessor.capturedParameters,
    parameters,
    "Should use the integrity parameters processor to filter the parameters"
  );
}

#pragma mark Test for Server Configuration

- (void)testFetchServerConfiguration
{
  FBSDKAppEventsConfiguration *configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:@{}];
  TestAppEventsConfigurationProvider.stubbedConfiguration = configuration;

  __block BOOL didRunCallback = NO;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:^void (void) {
    didRunCallback = YES;
  }];
  XCTAssertNotNil(
    TestAppEventsConfigurationProvider.capturedBlock,
    "The expected block should be captured by the AppEventsConfiguration provider"
  );
  TestAppEventsConfigurationProvider.capturedBlock();
  XCTAssertNotNil(
    self.serverConfigurationProvider.capturedCompletionBlock,
    "The expected block should be captured by the ServerConfiguration provider"
  );
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    didRunCallback,
    "fetchServerConfiguration should call the callback block"
  );
}

- (void)testFetchingConfigurationIncludingCertainFeatures
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);

  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureATELogging],
    "fetchConfiguration should check if the ATELogging feature is enabled"
  );
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureCodelessEvents],
    "fetchConfiguration should check if CodelessEvents feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingEventDeactivation
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureEventDeactivation],
    "Fetching a configuration should check if the EventDeactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingEventDeactivationParameterProcessorIfEventDeactivationEnabled
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureEventDeactivation with:YES];
  XCTAssertTrue(
    self.eventDeactivationParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable event deactivation parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingRestrictiveDataFiltering
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureRestrictiveDataFiltering],
    "Fetching a configuration should check if the RestrictiveDataFiltering feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingRestrictiveDataFilterParameterProcessorIfRestrictiveDataFilteringEnabled
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureRestrictiveDataFiltering with:YES];
  XCTAssertTrue(
    self.restrictiveDataFilterParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable restrictive data filter parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingAAM
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureAAM],
    "Fetch a configuration should check if the AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingMetadataIndexigIfAAMEnabled
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureAAM with:YES];
  XCTAssertTrue(
    self.metadataIndexer.enableWasCalled,
    "Fetching a configuration should enable metadata indexer if AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationStartsPaymentObservingIfConfigurationAllowed
{
  self.settings.stubbedIsAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertTrue(
    self.paymentObserver.didStartObservingTransactions,
    "fetchConfiguration should start payment observing if the configuration allows it"
  );
  XCTAssertFalse(
    self.paymentObserver.didStopObservingTransactions,
    "fetchConfiguration shouldn't stop payment observing if the configuration allows it"
  );
}

- (void)testFetchingConfigurationStopsPaymentObservingIfConfigurationDisallowed
{
  self.settings.stubbedIsAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @NO}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertFalse(
    self.paymentObserver.didStartObservingTransactions,
    "Fetching a configuration shouldn't start payment observing if the configuration disallows it"
  );
  XCTAssertTrue(
    self.paymentObserver.didStopObservingTransactions,
    "Fetching a configuration should stop payment observing if the configuration disallows it"
  );
}

- (void)testFetchingConfigurationStopPaymentObservingIfAutoLogAppEventsDisabled
{
  self.settings.stubbedIsAutoLogAppEventsEnabled = NO;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertFalse(
    self.paymentObserver.didStartObservingTransactions,
    "Fetching a configuration shouldn't start payment observing if auto log app events is disabled"
  );
  XCTAssertTrue(
    self.paymentObserver.didStopObservingTransactions,
    "Fetching a configuration should stop payment observing if auto log app events is disabled"
  );
}

- (void)testFetchingConfigurationIncludingSKAdNetworkIfSKAdNetworkReportEnabled
{
  self.settings.stubbedIsSKAdNetworkReportEnabled = YES;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should check if the SKAdNetwork feature is enabled when SKAdNetworkReport is enabled"
  );
}

- (void)testFetchingConfigurationEnablesSKAdNetworkReporterWhenSKAdNetworkReportAndConversionValueEnabled
{
  self.settings.stubbedIsSKAdNetworkReportEnabled = YES;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  if (@available(iOS 11.3, *)) {
    [self.featureManager completeCheckForFeature:FBSDKFeatureSKAdNetwork
                                            with:YES];
    [self.featureManager completeCheckForFeature:FBSDKFeatureSKAdNetworkConversionValue
                                            with:YES];
    XCTAssertTrue(
      [self.skAdNetworkReporter enableWasCalled],
      "Fetching a configuration should enable SKAdNetworkReporter when SKAdNetworkReport and SKAdNetworkConversionValue are enabled"
    );
  }
}

- (void)testFetchingConfigurationDoesNotEnableSKAdNetworkReporterWhenSKAdNetworkConversionValueIsDisabled
{
  self.settings.stubbedIsSKAdNetworkReportEnabled = YES;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  if (@available(iOS 11.3, *)) {
    [self.featureManager completeCheckForFeature:FBSDKFeatureSKAdNetwork
                                            with:YES];
    [self.featureManager completeCheckForFeature:FBSDKFeatureSKAdNetworkConversionValue
                                            with:NO];
    XCTAssertFalse(
      [self.skAdNetworkReporter enableWasCalled],
      "Fetching a configuration should NOT enable SKAdNetworkReporter if SKAdNetworkConversionValue is disabled"
    );
  }
}

- (void)testFetchingConfigurationNotIncludingSKAdNetworkIfSKAdNetworkReportDisabled
{
  self.settings.stubbedIsSKAdNetworkReportEnabled = NO;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertFalse(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should NOT check if the SKAdNetwork feature is disabled when SKAdNetworkReport is disabled"
  );
}

- (void)testFetchingConfigurationIncludingAEM
{
  if (@available(iOS 14.0, *)) {
    [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
    TestAppEventsConfigurationProvider.capturedBlock();
    self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
    XCTAssertTrue(
      [self.featureManager capturedFeaturesContains:FBSDKFeatureAEM],
      "Fetching a configuration should check if the AEM feature is enabled"
    );
  }
}

- (void)testFetchingConfigurationIncludingPrivacyProtection
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeaturePrivacyProtection],
    "Fetching a configuration should check if the PrivacyProtection feature is enabled"
  );
  [self.featureManager completeCheckForFeature:FBSDKFeaturePrivacyProtection
                                          with:YES];
  XCTAssertTrue(
    self.onDeviceMLModelManager.isEnabled,
    "Fetching a configuration should enable event processing if PrivacyProtection feature is enabled"
  );
}

#pragma mark Test for Singleton Values

- (void)testApplicationStateValues
{
  XCTAssertEqual([FBSDKAppEvents.singleton applicationState], UIApplicationStateInactive, "The default value of applicationState should be UIApplicationStateInactive");
  [FBSDKAppEvents.singleton setApplicationState:UIApplicationStateBackground];
  XCTAssertEqual([FBSDKAppEvents.singleton applicationState], UIApplicationStateBackground, "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground");
}

#pragma mark Source Application Tracking

- (void)testSetSourceApplicationOpenURL
{
  NSURL *url = [NSURL URLWithString:@"www.example.com"];
  [FBSDKAppEvents.singleton setSourceApplication:self.name openURL:url];

  XCTAssertEqualObjects(
    self.timeSpentRecorder.capturedSetSourceApplication,
    self.name,
    "Should behave as a proxy for tracking the source application"
  );
  XCTAssertEqualObjects(
    self.timeSpentRecorder.capturedSetSourceApplicationURL,
    url,
    "Should behave as a proxy for tracking the opened URL"
  );
}

- (void)testSetSourceApplicationFromAppLink
{
  [FBSDKAppEvents.singleton setSourceApplication:self.name isFromAppLink:YES];

  XCTAssertEqualObjects(
    self.timeSpentRecorder.capturedSetSourceApplicationFromAppLink,
    self.name,
    "Should behave as a proxy for tracking the source application"
  );
  XCTAssertTrue(
    self.timeSpentRecorder.capturedIsFromAppLink,
    "Should behave as a proxy for tracking whether the source application came from an app link"
  );
}

- (void)testRegisterAutoResetSourceApplication
{
  [FBSDKAppEvents.singleton registerAutoResetSourceApplication];

  XCTAssertTrue(
    self.timeSpentRecorder.wasRegisterAutoResetSourceApplicationCalled,
    "Should have the source application tracker register for auto resetting"
  );
}

- (void)registerAutoResetSourceApplication
{
  [self.timeSpentRecorder registerAutoResetSourceApplication];
}

@end
