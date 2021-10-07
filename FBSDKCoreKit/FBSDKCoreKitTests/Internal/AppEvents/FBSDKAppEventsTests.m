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

#import <FBAEMKit/FBAEMKit.h>

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
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;
- (void)applicationDidBecomeActive;
- (void)applicationMovingFromActiveStateOrTerminating;
- (void)setFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior;
- (void)publishATE;

+ (FBSDKAppEvents *)shared;
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
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logImplicitEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
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
@property (nonnull, nonatomic) TestUserDataStore *userDataStore;

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
  FBSDKAppEvents.singletonInstanceToInstance = appEvents;

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
  self.userDataStore = [TestUserDataStore new];

  // Must be stubbed before the configure method is called
  self.atePublisher = [TestAtePublisher new];
  self.atePublisherFactory.stubbedPublisher = self.atePublisher;

  [self configureAppEventsSingleton];

  FBSDKAppEvents.loggingOverrideAppID = self.mockAppID;
}

- (void)tearDown
{
  [FBSDKSettings reset];
  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestGateKeeperManager reset];
  [self resetTestHelpers];

  [super tearDown];
}

- (void)resetTestHelpers
{
  [self.settings reset];
  [TestLogger reset];
  [TestCodelessEvents reset];
}

- (void)configureAppEventsSingleton
{
  [FBSDKAppEvents.shared configureWithGateKeeperManager:TestGateKeeperManager.class
                         appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
                            serverConfigurationProvider:self.serverConfigurationProvider
                                    graphRequestFactory:self.graphRequestFactory
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
                                   advertiserIDProvider:self.advertiserIDProvider
                                          userDataStore:self.userDataStore];

  [FBSDKAppEvents.shared configureNonTVComponentsWithOnDeviceMLModelManager:self.onDeviceMLModelManager
                                                            metadataIndexer:self.metadataIndexer
                                                        skAdNetworkReporter:self.skAdNetworkReporter
                                                            codelessIndexer:TestCodelessEvents.class];
}

- (void)testConfiguringSetsSwizzlerDependency
{
  XCTAssertEqualObjects(
    FBSDKAppEvents.shared.swizzler,
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
    FBSDKAppEvents.shared.atePublisher,
    self.atePublisher,
    "Should store the publisher created by the publisher factory"
  );
}

- (void)testPublishingATEWithNilPublisher
{
  self.atePublisherFactory.stubbedPublisher = nil;
  [self configureAppEventsSingleton];

  XCTAssertNil(FBSDKAppEvents.shared.atePublisher);

  // Make sure the factory can create a publisher
  self.atePublisherFactory.stubbedPublisher = self.atePublisher;
  [FBSDKAppEvents.shared publishATE];

  XCTAssertNotNil(
    FBSDKAppEvents.shared.atePublisher,
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

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
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

#pragma mark  Tests for user data

- (void)testGettingUserData
{
  [FBSDKAppEvents.shared getUserData];

  XCTAssertTrue(
    self.userDataStore.wasGetUserDataCalled,
    "Should rely on the underlying store for user data"
  );
}

- (void)testSetAndClearUserData
{
  NSString *email = @"test_em";
  NSString *firstName = @"test_fn";
  NSString *lastName = @"test_ln";
  NSString *phone = @"test_phone";
  NSString *dateOfBirth = @"test_dateOfBirth";
  NSString *gender = @"test_gender";
  NSString *city = @"test_city";
  NSString *state = @"test_state";
  NSString *zip = @"test_zip";
  NSString *country = @"test_country";

  // Setting
  [FBSDKAppEvents.shared setUserEmail:email
                            firstName:firstName
                             lastName:lastName
                                phone:phone
                          dateOfBirth:dateOfBirth
                               gender:gender
                                 city:city
                                state:state
                                  zip:zip
                              country:country];

  XCTAssertEqualObjects(self.userDataStore.capturedEmail, email);
  XCTAssertEqualObjects(self.userDataStore.capturedFirstName, firstName);
  XCTAssertEqualObjects(self.userDataStore.capturedLastName, lastName);
  XCTAssertEqualObjects(self.userDataStore.capturedPhone, phone);
  XCTAssertEqualObjects(self.userDataStore.capturedDateOfBirth, dateOfBirth);
  XCTAssertEqualObjects(self.userDataStore.capturedGender, gender);
  XCTAssertEqualObjects(self.userDataStore.capturedCity, city);
  XCTAssertEqualObjects(self.userDataStore.capturedState, state);
  XCTAssertEqualObjects(self.userDataStore.capturedZip, zip);
  XCTAssertEqualObjects(self.userDataStore.capturedCountry, country);
  XCTAssertNil(self.userDataStore.capturedExternalId);

  // Clearing
  [FBSDKAppEvents.shared clearUserData];
  XCTAssertTrue(
    self.userDataStore.wasClearUserDataCalled,
    @"Should rely on the underlying store for clearing user data"
  );
}

- (void)testSettingUserDataForType
{
  [FBSDKAppEvents.shared setUserData:self.name forType:FBSDKAppEventEmail];

  XCTAssertEqualObjects(
    self.userDataStore.capturedSetUserDataForTypeData,
    self.name,
    @"Should invoke the underlying store with the expected user data"
  );
  XCTAssertEqualObjects(
    self.userDataStore.capturedSetUserDataForTypeType,
    FBSDKAppEventEmail,
    @"Should invoke the underlying store with the expected user data type"
  );
}

- (void)testClearingUserDataForType
{
  [FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventEmail];

  XCTAssertEqualObjects(
    self.userDataStore.capturedClearUserDataForTypeType,
    FBSDKAppEventEmail,
    @"Should rely on the underlying store for clearing user data by type"
  );
}

- (void)testSetAndClearUserID
{
  FBSDKAppEvents.userID = self.mockUserID;
  XCTAssertEqualObjects([FBSDKAppEvents userID], self.mockUserID);
  [FBSDKAppEvents clearUserID];
  XCTAssertNil([FBSDKAppEvents userID]);
}

- (void)testSetLoggingOverrideAppID
{
  NSString *mockOverrideAppID = @"2";
  FBSDKAppEvents.loggingOverrideAppID = mockOverrideAppID;
  XCTAssertEqualObjects([FBSDKAppEvents loggingOverrideAppID], mockOverrideAppID);
}

- (void)testSetPushNotificationsDeviceTokenString
{
  NSString *mockDeviceTokenString = @"testDeviceTokenString";
  self.eventName = @"fb_mobile_obtain_push_token";

  FBSDKAppEvents.pushNotificationsDeviceTokenString = mockDeviceTokenString;

  XCTAssertEqualObjects(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_eventName"],
    self.eventName
  );
  XCTAssertEqualObjects([FBSDKAppEvents shared].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testActivateAppWithInitializedSDK
{
  [FBSDKAppEvents.shared activateApp];

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
  TestAppEventsConfigurationProvider.lastCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  self.serverConfigurationProvider.secondCapturedCompletionBlock(nil, nil);

  TestGraphRequest *request = self.graphRequestFactory.capturedRequests.firstObject;
  XCTAssertEqualObjects(request.parameters[@"event"], @"MOBILE_APP_INSTALL");
}

- (void)testApplicationBecomingActiveRestoresTimeSpentRecording
{
  [FBSDKAppEvents.shared applicationDidBecomeActive];
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
  [FBSDKAppEvents.shared applicationMovingFromActiveStateOrTerminating];
  XCTAssertTrue(
    self.timeSpentRecorder.suspendWasCalled,
    "When application terminates or moves from active state, the time spent recording should be suspended."
  );
}

- (void)testApplicationTerminatingPersistingStates
{
  [FBSDKAppEvents.shared setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
                               valueToSum:@(self.purchaseAmount)
                               parameters:nil
                       isImplicitlyLogged:NO
                              accessToken:nil];
  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
                               valueToSum:@(self.purchaseAmount)
                               parameters:nil
                       isImplicitlyLogged:NO
                              accessToken:nil];
  [FBSDKAppEvents.shared applicationMovingFromActiveStateOrTerminating];

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
  XCTAssertNoThrow([FBSDKAppEvents.shared setUserData:foo forType:foo]);
  XCTAssertNoThrow(
    [FBSDKAppEvents.shared setUserEmail:nil
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
  XCTAssertNoThrow([FBSDKAppEvents.shared getUserData]);
  XCTAssertNoThrow([FBSDKAppEvents.shared clearUserDataForType:foo]);

  XCTAssertFalse(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App without initialized SDK cannot restore recording time spent data."
  );
}

- (void)testInstanceLogEventFilteringOutDeactivatedParameters
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
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
  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
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
  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"fb_push_action"], @"testAction");
  XCTAssertEqualObjects(capturedParameters[@"fb_push_campaign"], @"testCampaign");
}

- (void)testLogPushNotificationOpenWithEmptyAction
{
  self.eventName = @"fb_mobile_push_opened";

  [FBSDKAppEvents logPushNotificationOpen:self.payload];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
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
  FBSDKAppEvents.flushBehavior = FBSDKAppEventsFlushBehaviorAuto;
  XCTAssertEqual(FBSDKAppEventsFlushBehaviorAuto, FBSDKAppEvents.flushBehavior);

  FBSDKAppEvents.flushBehavior = FBSDKAppEventsFlushBehaviorExplicitOnly;
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
  self.settings.isEventDataUsageLimited = YES;
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
  self.settings.isEventDataUsageLimited = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if there is no access token or advertiser id"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID
{
  NSString *advertiserID = @"abc123";
  self.settings.isEventDataUsageLimited = NO;
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
  self.settings.isEventDataUsageLimited = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  FBSDKAppEvents.loggingOverrideAppID = token.appID;

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
  FBSDKAppEvents.loggingOverrideAppID = token.appID;
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", token.appID];
  NSString *advertiserID = @"abc123";
  self.settings.isEventDataUsageLimited = NO;
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
  [FBSDKAppEvents.shared publishInstall];

  XCTAssertNotNil(
    TestAppEventsConfigurationProvider.capturedBlock,
    "Should fetch a configuration before publishing installs"
  );
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];

  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
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

  [FBSDKAppEvents.shared instanceLogEvent:self.eventName
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

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @1);
}

- (void)testLogInternalEvents
{
  [FBSDKAppEvents logInternalEvent:self.eventName isImplicitlyLogged:NO];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertNil(capturedParameters[@"_valueToSum"]);
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
}

- (void)testLogInternalEventsWithValue
{
  [FBSDKAppEvents logInternalEvent:self.eventName valueToSum:self.purchaseAmount isImplicitlyLogged:NO];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
}

- (void)testLogInternalEventWithAccessToken
{
  [FBSDKAppEvents logInternalEvent:self.eventName parameters:@{} isImplicitlyLogged:NO accessToken:SampleAccessTokens.validToken];

  XCTAssertEqualObjects(self.appEventsStateProvider.capturedAppID, self.mockAppID);
  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
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

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertEqualObjects(capturedParameters[@"_implicitlyLogged"], @"1");
}

#pragma mark ParameterProcessing

- (void)testLoggingEventWithoutIntegrityParametersProcessor
{
  self.onDeviceMLModelManager.integrityParametersProcessor = nil;

  [FBSDKAppEvents.shared logEvent:@"event" parameters:@{@"foo" : @"bar"}];

  XCTAssertTrue(
    [TestLogger.capturedLogEntry containsString:@"foo = bar"],
    "Should not try to use a nil processor to filter the parameters"
  );
}

- (void)testLoggingEventWithIntegrityParametersProcessor
{
  NSDictionary<NSString *, id> *parameters = @{@"foo" : @"bar"};
  [FBSDKAppEvents.shared logEvent:@"event" parameters:parameters];

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
  [[FBSDKAppEvents shared] fetchServerConfiguration:^void (void) {
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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

- (void)testEnablingCodelessEvents
{
  [FBSDKAppEvents.shared fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  TestServerConfiguration *configuration = [[TestServerConfiguration alloc] initWithAppID:self.name];
  configuration.stubbedIsCodelessEventsEnabled = YES;

  self.serverConfigurationProvider.capturedCompletionBlock(configuration, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureCodelessEvents with:YES];
  XCTAssertTrue(
    TestCodelessEvents.wasEnabledCalled,
    "Should enable codeless events when the feature is enabled and the server configuration allows it"
  );
}

- (void)testFetchingConfigurationIncludingEventDeactivation
{
  [FBSDKAppEvents.shared fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureEventDeactivation],
    "Fetching a configuration should check if the EventDeactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingEventDeactivationParameterProcessorIfEventDeactivationEnabled
{
  [FBSDKAppEvents.shared fetchServerConfiguration:nil];
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
  [FBSDKAppEvents.shared fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureRestrictiveDataFiltering],
    "Fetching a configuration should check if the RestrictiveDataFiltering feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingRestrictiveDataFilterParameterProcessorIfRestrictiveDataFilteringEnabled
{
  [FBSDKAppEvents.shared fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
  TestAppEventsConfigurationProvider.capturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureAAM],
    "Fetch a configuration should check if the AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingMetadataIndexigIfAAMEnabled
{
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
    [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  [[FBSDKAppEvents shared] fetchServerConfiguration:nil];
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
  XCTAssertEqual([FBSDKAppEvents.shared applicationState], UIApplicationStateInactive, "The default value of applicationState should be UIApplicationStateInactive");
  [FBSDKAppEvents.shared setApplicationState:UIApplicationStateBackground];
  XCTAssertEqual([FBSDKAppEvents.shared applicationState], UIApplicationStateBackground, "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground");
}

#pragma mark Source Application Tracking

- (void)testSetSourceApplicationOpenURL
{
  NSURL *url = [NSURL URLWithString:@"www.example.com"];
  [FBSDKAppEvents.shared setSourceApplication:self.name openURL:url];

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
  [FBSDKAppEvents.shared setSourceApplication:self.name isFromAppLink:YES];

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
  [FBSDKAppEvents.shared registerAutoResetSourceApplication];

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
