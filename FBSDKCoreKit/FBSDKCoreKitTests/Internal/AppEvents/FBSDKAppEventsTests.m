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

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEvents+SourceApplicationTracking.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKTestCase.h"
#import "FBSDKUtility.h"
#import "UserDefaultsSpy.h"

static NSString *const _mockAppID = @"mockAppID";
static NSString *const _mockUserID = @"mockUserID";

// An extension that redeclares a private method so that it can be mocked
@interface FBSDKApplicationDelegate (Testing)
- (void)_logSDKInitialize;
@end

@interface FBSDKAppEvents (Testing)
@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;
@property (nonatomic, strong) id<FBSDKAtePublishing> atePublisher;
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

+ (FBSDKAppEvents *)singleton;

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

@interface FBSDKAppEventsTests : FBSDKTestCase
{
  NSString *_mockEventName;
  NSDictionary<NSString *, id> *_mockPayload;
  double _mockPurchaseAmount;
  NSString *_mockCurrency;
  TestGraphRequestFactory *_graphRequestFactory;
  UserDefaultsSpy *_store;
  TestFeatureManager *_featureManager;
  TestSettings *_settings;
  TestOnDeviceMLModelManager *_onDeviceMLModelManager;
  TestPaymentObserver *_paymentObserver;
  TestAppEventsStateStore *_appEventsStateStore;
  TestMetadataIndexer *_metadataIndexer;
  TestAppEventsParameterProcessor *_eventDeactivationParameterProcessor;
  TestAppEventsParameterProcessor *_restrictiveDataFilterParameterProcessor;
  TestAppEventsStateProvider *_appEventsStateProvider;
}

@property (nonnull, nonatomic) TestAtePublisherFactory *atePublisherfactory;
@property (nonnull, nonatomic) TestAtePublisher *atePublisher;
@property (nonnull, nonatomic) TestTimeSpentRecorderFactory *timeSpentRecorderFactory;
@property (nonnull, nonatomic) TestTimeSpentRecorder *timeSpentRecorder;
@property (nonnull, nonatomic) TestAppEventsParameterProcessor *integrityParametersProcessor;

@end

@implementation FBSDKAppEventsTests

+ (void)setUp
{
  [super setUp];

  [FBSDKAppEvents reset];
}

- (void)setUp
{
  self.shouldAppEventsMockBePartial = YES;

  [super setUp];
  [self resetTestHelpers];
  _settings = [TestSettings new];
  _settings.stubbedIsAutoLogAppEventsEnabled = YES;
  [FBSDKInternalUtility reset];
  self.integrityParametersProcessor = [TestAppEventsParameterProcessor new];
  _onDeviceMLModelManager = [TestOnDeviceMLModelManager new];
  _onDeviceMLModelManager.integrityParametersProcessor = self.integrityParametersProcessor;
  _paymentObserver = [TestPaymentObserver new];
  _metadataIndexer = [TestMetadataIndexer new];

  _mockEventName = @"fb_mock_event";
  _mockPayload = @{@"fb_push_payload" : @{@"campaign" : @"testCampaign"}};
  _mockPurchaseAmount = 1.0;
  _mockCurrency = @"USD";
  _graphRequestFactory = [TestGraphRequestFactory new];
  _store = [UserDefaultsSpy new];
  _featureManager = [TestFeatureManager new];
  _paymentObserver = [TestPaymentObserver new];
  _appEventsStateStore = [TestAppEventsStateStore new];
  _eventDeactivationParameterProcessor = [TestAppEventsParameterProcessor new];
  _restrictiveDataFilterParameterProcessor = [TestAppEventsParameterProcessor new];
  _appEventsStateProvider = [TestAppEventsStateProvider new];
  self.atePublisherfactory = [TestAtePublisherFactory new];
  self.timeSpentRecorderFactory = [TestTimeSpentRecorderFactory new];
  self.timeSpentRecorder = self.timeSpentRecorderFactory.recorder;

  // Must be stubbed before the configure method is called
  self.atePublisher = [TestAtePublisher new];
  self.atePublisherfactory.stubbedPublisher = self.atePublisher;

  // This should be removed when these tests are updated to check the actual requests that are created
  [self stubAllocatingGraphRequestConnection];
  [FBSDKAppEvents.singleton configureWithGateKeeperManager:TestGateKeeperManager.class
                            appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
                               serverConfigurationProvider:TestServerConfigurationProvider.class
                                      graphRequestProvider:_graphRequestFactory
                                            featureChecker:_featureManager
                                                     store:_store
                                                    logger:TestLogger.class
                                                  settings:_settings
                                           paymentObserver:_paymentObserver
                                  timeSpentRecorderFactory:self.timeSpentRecorderFactory
                                       appEventsStateStore:_appEventsStateStore
                       eventDeactivationParameterProcessor:_eventDeactivationParameterProcessor
                   restrictiveDataFilterParameterProcessor:_restrictiveDataFilterParameterProcessor
                                       atePublisherFactory:self.atePublisherfactory
                                    appEventsStateProvider:_appEventsStateProvider
                                                  swizzler:TestSwizzler.class];

  [FBSDKAppEvents configureNonTVComponentsWithOnDeviceMLModelManager:_onDeviceMLModelManager
                                                     metadataIndexer:_metadataIndexer];

  [FBSDKAppEvents setLoggingOverrideAppID:_mockAppID];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings reset];
  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestServerConfigurationProvider reset];
  [TestGateKeeperManager reset];
}

- (void)resetTestHelpers
{
  [TestSettings reset];
  [TestLogger reset];
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
    self.atePublisherfactory.capturedAppID,
    _mockAppID,
    "Configuring should create an ate publisher with the expected app id"
  );
  XCTAssertEqualObjects(
    FBSDKAppEvents.singleton.atePublisher,
    self.atePublisher,
    "Should store the publisher created by the publisher factory"
  );
}

- (void)testAppEventsMockIsSingleton
{
  XCTAssertEqual(self.appEventsMock, [FBSDKAppEvents singleton]);
}

- (void)testLogPurchaseFlush
{
  OCMExpect([self.appEventsMock flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent]);

  OCMStub([self.appEventsMock flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogPurchase
{
  OCMExpect([self.appEventsMock logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any]]).andForwardToRealObject();
  OCMExpect([self.appEventsMock logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any] accessToken:[OCMArg any]]).andForwardToRealObject();
  OCMExpect([self.appEventsMock logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:[OCMArg any] accessToken:[OCMArg any]]).andForwardToRealObject();

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  OCMVerifyAll(self.appEventsMock);
  XCTAssertTrue(
    _appEventsStateProvider.state.isAddEventCalled,
    "Should add events to AppEventsState when logging purshase"
  );
  XCTAssertFalse(
    _appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly add events to AppEventsState when logging purshase"
  );
}

- (void)testFlush
{
  OCMExpect([self.appEventsMock flushForReason:FBSDKAppEventsFlushReasonExplicit]);

  [FBSDKAppEvents flush];

  OCMVerifyAll(self.appEventsMock);
}

#pragma mark  Tests for log product item

- (void)testLogProductItemNonNil
{
  NSDictionary<NSString *, NSString *> *expectedDict = @{
    @"fb_product_availability" : @"IN_STOCK",
    @"fb_product_brand" : @"PHILZ",
    @"fb_product_condition" : @"NEW",
    @"fb_product_description" : @"description",
    @"fb_product_gtin" : @"BLUE MOUNTAIN",
    @"fb_product_image_link" : @"https://www.sample.com",
    @"fb_product_item_id" : @"F40CEE4E-471E-45DB-8541-1526043F4B21",
    @"fb_product_link" : @"https://www.sample.com",
    @"fb_product_mpn" : @"BLUE MOUNTAIN",
    @"fb_product_price_amount" : @"1.000",
    @"fb_product_price_currency" : @"USD",
    @"fb_product_title" : @"title",
  };
  OCMExpect(
    [self.appEventsMock logEvent:@"fb_mobile_catalog_update"
                      parameters:expectedDict]
  );

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

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogProductItemNilGtinMpnBrand
{
  NSDictionary<NSString *, NSString *> *expectedDict = @{
    @"fb_product_availability" : @"IN_STOCK",
    @"fb_product_condition" : @"NEW",
    @"fb_product_description" : @"description",
    @"fb_product_image_link" : @"https://www.sample.com",
    @"fb_product_item_id" : @"F40CEE4E-471E-45DB-8541-1526043F4B21",
    @"fb_product_link" : @"https://www.sample.com",
    @"fb_product_price_amount" : @"1.000",
    @"fb_product_price_currency" : @"USD",
    @"fb_product_title" : @"title",
  };
  OCMReject(
    [self.appEventsMock logEvent:@"fb_mobile_catalog_update"
                      parameters:expectedDict]
  );

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
  [FBSDKAppEvents setUserID:_mockUserID];
  XCTAssertEqualObjects([FBSDKAppEvents userID], _mockUserID);
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
  NSString *eventName = @"fb_mobile_obtain_push_token";

  OCMExpect([self.appEventsMock logEvent:eventName]).andForwardToRealObject();
  OCMExpect(
    [self.appEventsMock logEvent:eventName
                      parameters:@{}]
  ).andForwardToRealObject();
  OCMExpect(
    [self.appEventsMock logEvent:eventName
                      valueToSum:nil
                      parameters:@{}
                     accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents setPushNotificationsDeviceTokenString:mockDeviceTokenString];

  OCMVerifyAll(self.appEventsMock);

  XCTAssertEqualObjects([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testActivateAppWithInitializedSDK
{
  OCMExpect([self.appEventsMock publishInstall]);
  OCMExpect([self.appEventsMock fetchServerConfiguration:NULL]);

  [FBSDKAppEvents.singleton activateApp];

  OCMVerifyAll(self.appEventsMock);
  XCTAssertTrue(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App with initialized SDK should restore recording time spent data."
  );
  XCTAssertTrue(
    self.timeSpentRecorder.capturedCalledFromActivateApp,
    "Activating App with initialized SDK should indicate its calling from activateApp when restoring recording time spent data."
  );
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
  [FBSDKAppEvents.singleton instanceLogEvent:_mockEventName
                                  valueToSum:@(_mockPurchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  [FBSDKAppEvents.singleton instanceLogEvent:_mockEventName
                                  valueToSum:@(_mockPurchaseAmount)
                                  parameters:nil
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  [FBSDKAppEvents.singleton applicationMovingFromActiveStateOrTerminating];

  XCTAssertTrue(
    _appEventsStateStore.capturedPersistedState.count > 0,
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
  [FBSDKAppEvents.singleton instanceLogEvent:_mockEventName
                                  valueToSum:@(_mockPurchaseAmount)
                                  parameters:parameters
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  XCTAssertEqualObjects(
    _eventDeactivationParameterProcessor.capturedEventName,
    _mockEventName,
    "AppEvents instance should submit the event name to event deactivation parameters processor."
  );
  XCTAssertEqualObjects(
    _eventDeactivationParameterProcessor.capturedParameters,
    parameters,
    "AppEvents instance should submit the parameters to event deactivation parameters processor."
  );
}

- (void)testInstanceLogEventProcessParametersWithRestrictiveDataFilterParameterProcessor
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [FBSDKAppEvents.singleton instanceLogEvent:_mockEventName
                                  valueToSum:@(_mockPurchaseAmount)
                                  parameters:parameters
                          isImplicitlyLogged:NO
                                 accessToken:nil];
  XCTAssertEqualObjects(
    _restrictiveDataFilterParameterProcessor.capturedEventName,
    _mockEventName,
    "AppEvents instance should submit the event name to the restrictive data filter parameters processor."
  );
  XCTAssertEqualObjects(
    _restrictiveDataFilterParameterProcessor.capturedParameters,
    parameters,
    "AppEvents instance should submit the parameters to the restrictive data filter parameters processor."
  );
}

#pragma mark  Test for log push notification

- (void)testLogPushNotificationOpen
{
  NSString *eventName = @"fb_mobile_push_opened";
  // with action and campaign
  NSDictionary<NSString *, NSString *> *expectedParams1 = @{
    @"fb_push_action" : @"testAction",
    @"fb_push_campaign" : @"testCampaign",
  };
  OCMExpect([self.appEventsMock logEvent:eventName parameters:expectedParams1]);
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload action:@"testAction"];
  OCMVerifyAll(self.appEventsMock);

  // empty action
  NSDictionary<NSString *, NSString *> *expectedParams2 = @{
    @"fb_push_campaign" : @"testCampaign",
  };
  OCMExpect([self.appEventsMock logEvent:eventName parameters:expectedParams2]);
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload];
  OCMVerifyAll(self.appEventsMock);

  // empty payload
  OCMReject([self.appEventsMock logEvent:eventName parameters:[OCMArg any]]);
  [FBSDKAppEvents logPushNotificationOpen:@{}];

  // empty campaign
  NSDictionary<NSString *, id> *mockPayload = @{@"fb_push_payload" : @{@"campaign" : @""}};
  OCMReject([self.appEventsMock logEvent:eventName parameters:[OCMArg any]]);
  [FBSDKAppEvents logPushNotificationOpen:mockPayload];

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
  OCMStub([self.appEventsMock flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  OCMVerifyAll(self.appEventsMock);
  XCTAssertTrue(
    _appEventsStateStore.retrievePersistedAppEventStatesWasCalled,
    "Should retrieve persisted states when logEvent was called and flush behavior was FlushReasonEagerlyFlushingEvent"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithTrackingDisallowed
{
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

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
  _settings.stubbedLimitEventAndDataUsage = YES;
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

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
  _settings.stubbedLimitEventAndDataUsage = NO;
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  [self stubAppEventsUtilityAdvertiserIDWith:nil];

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if there is no access token or advertiser id"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID
{
  NSString *advertiserID = @"abc123";
  _settings.stubbedLimitEventAndDataUsage = NO;
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  [self stubAppEventsUtilityAdvertiserIDWith:advertiserID];

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil];
  XCTAssertEqualObjects(
    _graphRequestFactory.capturedParameters,
    @{ @"udid" : advertiserID },
    "Should include the udid in the request when there is no access token available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithoutAdvertiserID
{
  FBSDKAccessToken *token = SampleAccessTokens.validToken;
  _settings.stubbedLimitEventAndDataUsage = NO;
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  [self stubAppEventsUtilityAdvertiserIDWith:nil];
  [FBSDKAppEvents setLoggingOverrideAppID:token.appID];

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];
  XCTAssertEqualObjects(
    _graphRequestFactory.capturedTokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    _graphRequestFactory.capturedParameters[@"udid"],
    "Should not include the udid in the request when there is none available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithAdvertiserID
{
  FBSDKAccessToken *token = SampleAccessTokens.validToken;
  [FBSDKAppEvents setLoggingOverrideAppID:token.appID];
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", token.appID];
  NSString *advertiserID = @"abc123";
  _settings.stubbedLimitEventAndDataUsage = NO;
  _settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  [self stubAppEventsUtilityAdvertiserIDWith:advertiserID];

  [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];

  XCTAssertEqualObjects(
    _graphRequestFactory.capturedTokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    _graphRequestFactory.capturedParameters[@"udid"],
    "Should not include the udid in the request when there is an access token available"
  );
  XCTAssertEqualObjects(
    _graphRequestFactory.capturedGraphPath,
    expectedGraphPath,
    "Should use the expected graph path for the request"
  );
  XCTAssertEqual(
    _graphRequestFactory.capturedHttpMethod,
    FBSDKHTTPMethodGET,
    "Should use the expected http method for the request"
  );
  XCTAssertEqual(
    _graphRequestFactory.capturedFlags,
    FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery,
    "Should use the expected flags for the request"
  );
}

- (void)testPublishInstall
{
  _settings.appID = self.appID;
  OCMExpect([self.appEventsMock fetchServerConfiguration:[OCMArg any]]);

  [self.appEventsMock publishInstall];

  OCMVerifyAll(self.appEventsMock);
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  XCTAssertTrue(
    _appEventsStateProvider.state.isAddEventCalled,
    "Should add events to AppEventsState when killswitch is disabled"
  );
  XCTAssertFalse(
    _appEventsStateProvider.state.capturedIsImplicit,
    "Shouldn't implicitly add events to AppEventsState when killswitch is disabled"
  );
}

- (void)testAppEventsKillSwitchEnabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:YES];

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];
  XCTAssertFalse(
    _appEventsStateProvider.state.isAddEventCalled,
    "Shouldn't add events to AppEventsState when killswitch is enabled"
  );
}

#pragma mark  Tests for log event

- (void)testLogEventWithValueToSum
{
  OCMExpect(
    [self.appEventsMock logEvent:_mockEventName
                      valueToSum:_mockPurchaseAmount
                      parameters:@{}]
  ).andForwardToRealObject();
  OCMExpect(
    [self.appEventsMock logEvent:_mockEventName
                      valueToSum:@(_mockPurchaseAmount)
                      parameters:@{}
                     accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents logEvent:_mockEventName valueToSum:_mockPurchaseAmount];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogInternalEvents
{
  OCMExpect(
    [self.appEventsMock logInternalEvent:_mockEventName
                              parameters:@{}
                      isImplicitlyLogged:NO]
  ).andForwardToRealObject();
  OCMExpect(
    [self.appEventsMock logInternalEvent:_mockEventName
                              valueToSum:nil
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName isImplicitlyLogged:NO];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogInternalEventsWithValue
{
  OCMExpect(
    [self.appEventsMock logInternalEvent:_mockEventName
                              valueToSum:_mockPurchaseAmount
                              parameters:@{}
                      isImplicitlyLogged:NO]
  ).andForwardToRealObject();
  OCMExpect(
    [self.appEventsMock logInternalEvent:_mockEventName
                              valueToSum:@(_mockPurchaseAmount)
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogInternalEventWithAccessToken
{
  id mockAccessToken = [OCMockObject niceMockForClass:[FBSDKAccessToken class]];
  OCMExpect(
    [self.appEventsMock logInternalEvent:_mockEventName
                              valueToSum:nil
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:mockAccessToken]
  ).andForwardToRealObject();
  [FBSDKAppEvents logInternalEvent:_mockEventName parameters:@{} isImplicitlyLogged:NO accessToken:mockAccessToken];
  OCMVerifyAll(self.appEventsMock);

  [mockAccessToken stopMocking];
  mockAccessToken = nil;
}

- (void)testInstanceLogEventWhenAutoLogAppEventsDisabled
{
  _settings.stubbedIsAutoLogAppEventsEnabled = NO;
  OCMReject(
    [self.appEventsMock instanceLogEvent:_mockEventName
                              valueToSum:@(_mockPurchaseAmount)
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:nil]
  );

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];
}

- (void)testInstanceLogEventWhenAutoLogAppEventsEnabled
{
  OCMExpect(
    [self.appEventsMock instanceLogEvent:_mockEventName
                              valueToSum:@(_mockPurchaseAmount)
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testLogImplicitEvent
{
  OCMExpect(
    [self.appEventsMock instanceLogEvent:_mockEventName
                              valueToSum:@(_mockPurchaseAmount)
                              parameters:@{}
                      isImplicitlyLogged:YES
                             accessToken:nil]
  );

  [FBSDKAppEvents logImplicitEvent:_mockEventName valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  OCMVerifyAll(self.appEventsMock);
}

#pragma mark ParameterProcessing

- (void)testLoggingEventWithoutIntegrityParametersProcessor
{
  _onDeviceMLModelManager.integrityParametersProcessor = nil;

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
    TestServerConfigurationProvider.capturedCompletionBlock,
    "The expected block should be captured by the ServerConfiguration provider"
  );
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    didRunCallback,
    "fetchServerConfiguration should call the callback block"
  );
}

- (void)testFetchingConfigurationIncludingCertainFeatures
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);

  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureATELogging],
    "fetchConfiguration should check if the ATELogging feature is enabled"
  );
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureCodelessEvents],
    "fetchConfiguration should check if CodelessEvents feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingEventDeactivation
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureEventDeactivation],
    "Fetching a configuration should check if the EventDeactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingEventDeactivationParameterProcessorIfEventDeactivationEnabled
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  [_featureManager completeCheckForFeature:FBSDKFeatureEventDeactivation with:YES];
  XCTAssertTrue(
    _eventDeactivationParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable event deactivation parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingRestrictiveDataFiltering
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureRestrictiveDataFiltering],
    "Fetching a configuration should check if the RestrictiveDataFiltering feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingRestrictiveDataFilterParameterProcessorIfRestrictiveDataFilteringEnabled
{
  [FBSDKAppEvents.singleton fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  [_featureManager completeCheckForFeature:FBSDKFeatureRestrictiveDataFiltering with:YES];
  XCTAssertTrue(
    _restrictiveDataFilterParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable restrictive data filter parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingAAM
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureAAM],
    "Fetch a configuration should check if the AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingMetadataIndexigIfAAMEnabled
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  [_featureManager completeCheckForFeature:FBSDKFeatureAAM with:YES];
  XCTAssertTrue(
    _metadataIndexer.enableWasCalled,
    "Fetching a configuration should enable metadata indexer if AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationStartsPaymentObservingIfConfigurationAllowed
{
  _settings.stubbedIsAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [FBSDKServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertTrue(
    _paymentObserver.didStartObservingTransactions,
    "fetchConfiguration should start payment observing if the configuration allows it"
  );
  XCTAssertFalse(
    _paymentObserver.didStopObservingTransactions,
    "fetchConfiguration shouldn't stop payment observing if the configuration allows it"
  );
}

- (void)testFetchingConfigurationStopsPaymentObservingIfConfigurationDisallowed
{
  _settings.stubbedIsAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [FBSDKServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @NO}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertFalse(
    _paymentObserver.didStartObservingTransactions,
    "Fetching a configuration shouldn't start payment observing if the configuration disallows it"
  );
  XCTAssertTrue(
    _paymentObserver.didStopObservingTransactions,
    "Fetching a configuration should stop payment observing if the configuration disallows it"
  );
}

- (void)testFetchingConfigurationStopPaymentObservingIfAutoLogAppEventsDisabled
{
  _settings.stubbedIsAutoLogAppEventsEnabled = NO;
  FBSDKServerConfiguration *serverConfiguration = [FBSDKServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(serverConfiguration, nil);
  XCTAssertFalse(
    _paymentObserver.didStartObservingTransactions,
    "Fetching a configuration shouldn't start payment observing if auto log app events is disabled"
  );
  XCTAssertTrue(
    _paymentObserver.didStopObservingTransactions,
    "Fetching a configuration should stop payment observing if auto log app events is disabled"
  );
}

- (void)testFetchingConfigurationIncludingSKAdNetworkIfSKAdNetworkReportEnabled
{
  _settings.stubbedIsSKAdNetworkReportEnabled = YES;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should check if the SKAdNetwork feature is enabled when SKAdNetworkReport is enabled"
  );
}

- (void)testFetchingConfigurationNotIncludingSKAdNetworkIfSKAdNetworkReportDisabled
{
  _settings.stubbedIsSKAdNetworkReportEnabled = NO;
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertFalse(
    [_featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should NOT check if the SKAdNetwork feature is disabled when SKAdNetworkReport is disabled"
  );
}

- (void)testFetchingConfigurationIncludingAEM
{
  if (@available(iOS 14.0, *)) {
    FBSDKAEMReporter.isEnabled = NO;
    [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
    TestAppEventsConfigurationProvider.capturedBlock();
    TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
    XCTAssertTrue(
      [_featureManager capturedFeaturesContains:FBSDKFeatureAEM],
      "Fetching a configuration should check if the AEM feature is enabled"
    );
  }
}

- (void)testFetchingConfigurationIncludingPrivacyProtection
{
  [[FBSDKAppEvents singleton] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [_featureManager capturedFeaturesContains:FBSDKFeaturePrivacyProtection],
    "Fetching a configuration should check if the PrivacyProtection feature is enabled"
  );
  [_featureManager completeCheckForFeature:FBSDKFeaturePrivacyProtection
                                      with:YES];
  XCTAssertTrue(
    _onDeviceMLModelManager.isEnabled,
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
