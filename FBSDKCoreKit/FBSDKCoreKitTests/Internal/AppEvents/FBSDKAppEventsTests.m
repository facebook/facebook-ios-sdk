/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

@import TestTools;

#import <FBAEMKit/FBAEMKit.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents+Testing.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsTests : XCTestCase

@property (nonatomic) FBSDKAppEvents *appEvents;

@property (nonatomic) NSString *const mockAppID;
@property (nonatomic) NSString *const mockUserID;
@property (nonatomic) NSString *eventName;
@property (nonatomic) NSDictionary<NSString *, id> *payload;
@property (nonatomic) double purchaseAmount;
@property (nonatomic) NSString *currency;
@property (nonatomic) TestATEPublisherFactory *atePublisherFactory;
@property (nonatomic) TestATEPublisher *atePublisher;
@property (nonatomic) TestTimeSpentRecorder *timeSpentRecorder;
@property (nonatomic) TestAppEventsParameterProcessor *integrityParametersProcessor;
@property (nonatomic) TestGraphRequestFactory *graphRequestFactory;
@property (nonatomic) UserDefaultsSpy *primaryDataStore;
@property (nonatomic) TestFeatureManager *featureManager;
@property (nonatomic) TestSettings *settings;
@property (nonatomic) TestOnDeviceMLModelManager *onDeviceMLModelManager;
@property (nonatomic) TestPaymentObserver *paymentObserver;
@property (nonatomic) TestAppEventsStateStore *appEventsStateStore;
@property (nonatomic) TestMetadataIndexer *metadataIndexer;
@property (nonatomic) TestAppEventsConfigurationProvider *appEventsConfigurationProvider;
@property (nonatomic) TestAppEventsParameterProcessor *eventDeactivationParameterProcessor;
@property (nonatomic) TestAppEventsParameterProcessor *restrictiveDataFilterParameterProcessor;
@property (nonatomic) TestAppEventsStateProvider *appEventsStateProvider;
@property (nonatomic) TestAdvertiserIDProvider *advertiserIDProvider;
@property (nonatomic) TestAppEventsReporter *skAdNetworkReporter;
@property (nonatomic) TestServerConfigurationProvider *serverConfigurationProvider;
@property (nonatomic) TestUserDataStore *userDataStore;
@property (nonatomic) TestAppEventsUtility *appEventsUtility;

@end

@implementation FBSDKAppEventsTests

- (void)setUp
{
  [super setUp];

  self.appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                            flushPeriodInSeconds:0];

  [self resetTestHelpers];
  self.settings = [TestSettings new];
  self.settings.isAutoLogAppEventsEnabled = YES;
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
  self.primaryDataStore = [UserDefaultsSpy new];
  self.featureManager = [TestFeatureManager new];
  self.paymentObserver = [TestPaymentObserver new];
  self.appEventsStateStore = [TestAppEventsStateStore new];
  self.eventDeactivationParameterProcessor = [TestAppEventsParameterProcessor new];
  self.restrictiveDataFilterParameterProcessor = [TestAppEventsParameterProcessor new];
  self.appEventsConfigurationProvider = [TestAppEventsConfigurationProvider new];
  self.appEventsStateProvider = [TestAppEventsStateProvider new];
  self.atePublisherFactory = [TestATEPublisherFactory new];
  self.timeSpentRecorder = [TestTimeSpentRecorder new];
  self.advertiserIDProvider = [TestAdvertiserIDProvider new];
  self.skAdNetworkReporter = [TestAppEventsReporter new];
  self.serverConfigurationProvider = [[TestServerConfigurationProvider alloc]
                                      initWithConfiguration:ServerConfigurationFixtures.defaultConfig];
  self.userDataStore = [TestUserDataStore new];
  self.appEventsUtility = [TestAppEventsUtility new];
  self.appEventsUtility.stubbedIsIdentifierValid = YES;

  // Must be stubbed before the configure method is called
  self.atePublisher = [TestATEPublisher new];
  self.atePublisherFactory.stubbedPublisher = self.atePublisher;

  [self configureAppEvents];
  self.appEvents.loggingOverrideAppID = self.mockAppID;
}

- (void)tearDown
{
  [self resetTestHelpers];
  [super tearDown];
}

- (void)resetTestHelpers
{
  [TestGateKeeperManager reset];
  [TestLogger reset];
  [TestCodelessEvents reset];
  [TestAEMReporter reset];
}

- (void)configureAppEvents
{
  [self.appEvents configureWithGateKeeperManager:TestGateKeeperManager.class
                  appEventsConfigurationProvider:self.appEventsConfigurationProvider
                     serverConfigurationProvider:self.serverConfigurationProvider
                             graphRequestFactory:self.graphRequestFactory
                                  featureChecker:self.featureManager
                                primaryDataStore:self.primaryDataStore
                                          logger:TestLogger.class
                                        settings:self.settings
                                 paymentObserver:self.paymentObserver
                               timeSpentRecorder:self.timeSpentRecorder
                             appEventsStateStore:self.appEventsStateStore
             eventDeactivationParameterProcessor:self.eventDeactivationParameterProcessor
         restrictiveDataFilterParameterProcessor:self.restrictiveDataFilterParameterProcessor
                             atePublisherFactory:self.atePublisherFactory
                          appEventsStateProvider:self.appEventsStateProvider
                            advertiserIDProvider:self.advertiserIDProvider
                                   userDataStore:self.userDataStore
                                appEventsUtility:self.appEventsUtility];

  [self.appEvents configureNonTVComponentsWithOnDeviceMLModelManager:self.onDeviceMLModelManager
                                                     metadataIndexer:self.metadataIndexer
                                                 skAdNetworkReporter:self.skAdNetworkReporter
                                                     codelessIndexer:TestCodelessEvents.class
                                                            swizzler:TestSwizzler.class
                                                         aemReporter:TestAEMReporter.class];
}

- (void)testConfiguringSetsSwizzlerDependency
{
  XCTAssertEqualObjects(
    self.appEvents.swizzler,
    TestSwizzler.class,
    "Configuring should set the provided swizzler"
  );
}

- (void)testConfiguringCreatesATEPublisher
{
  XCTAssertEqualObjects(
    self.atePublisherFactory.capturedAppID,
    self.mockAppID,
    "Configuring should create an ate publisher with the expected app id"
  );
  XCTAssertEqualObjects(
    self.appEvents.atePublisher,
    self.atePublisher,
    "Should store the publisher created by the publisher factory"
  );
}

- (void)testPublishingATEWithNilPublisher
{
  self.appEvents.atePublisher = nil;
  [self.appEvents publishATE];

  XCTAssertEqualObjects(
    self.appEvents.atePublisher,
    self.atePublisher,
    "Should lazily create an ATE publisher when needed"
  );
}

- (void)testLogPurchaseFlushesWhenFlushBehaviorIsExplicit
{
  self.appEvents.flushBehavior = FBSDKAppEventsFlushBehaviorAuto;
  [self.appEvents logPurchase:self.purchaseAmount currency:self.currency];

  // Verifying flush
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertEqualObjects(
    self.graphRequestFactory.capturedRequests.firstObject.graphPath,
    @"mockAppID/activities"
  );
  [self validateAEMReporterCalledWithEventName:@"fb_mobile_purchase"
                                      currency:self.currency
                                         value:@(self.purchaseAmount)
                                    parameters:@{@"fb_currency" : @"USD"}];
}

- (void)testLogPurchase
{
  [self.appEvents logPurchase:self.purchaseAmount currency:self.currency];

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
  [self validateAEMReporterCalledWithEventName:@"fb_mobile_purchase"
                                      currency:self.currency
                                         value:@(self.purchaseAmount)
                                    parameters:@{@"fb_currency" : @"USD"}];
}

- (void)testFlush
{
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id _Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
    // A not-the-best proxy to determine if a flush occurred.
    return self.appEventsConfigurationProvider.firstCapturedBlock != nil;
  }];
  XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];

  [self.appEvents logEvent:@"foo"];
  [self.appEvents flush];

  [self waitForExpectations:@[expectation] timeout:2];

  [self validateAEMReporterCalledWithEventName:@"foo"
                                      currency:nil
                                         value:nil
                                    parameters:@{}];
}

#pragma mark  Tests for log product item

- (void)testLogProductItemNonNil
{
  [self.appEvents logProductItem:@"F40CEE4E-471E-45DB-8541-1526043F4B21"
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

  NSDictionary<NSString *, NSString *> *expectedAEMParameters = @{
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
    @"fb_product_title" : @"title"
  };

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
  [self validateAEMReporterCalledWithEventName:@"fb_mobile_catalog_update"
                                      currency:nil
                                         value:nil
                                    parameters:expectedAEMParameters];
}

- (void)testLogProductItemNilGtinMpnBrand
{
  [self.appEvents logProductItem:@"F40CEE4E-471E-45DB-8541-1526043F4B21"
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
  [self.appEvents getUserData];

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
  [self.appEvents setUserEmail:email
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
  [self.appEvents clearUserData];
  XCTAssertTrue(
    self.userDataStore.wasClearUserDataCalled,
    @"Should rely on the underlying store for clearing user data"
  );
}

- (void)testSettingUserDataForType
{
  [self.appEvents setUserData:self.name forType:FBSDKAppEventEmail];

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
  [self.appEvents clearUserDataForType:FBSDKAppEventEmail];

  XCTAssertEqualObjects(
    self.userDataStore.capturedClearUserDataForTypeType,
    FBSDKAppEventEmail,
    @"Should rely on the underlying store for clearing user data by type"
  );
}

- (void)testSetAndClearUserID
{
  self.appEvents.userID = self.mockUserID;
  XCTAssertEqualObjects(self.appEvents.userID, self.mockUserID);
  self.appEvents.userID = nil;
  XCTAssertNil(self.appEvents.userID);
}

- (void)testSetLoggingOverrideAppID
{
  NSString *mockOverrideAppID = @"2";
  self.appEvents.loggingOverrideAppID = mockOverrideAppID;
  XCTAssertEqualObjects(self.appEvents.loggingOverrideAppID, mockOverrideAppID);
}

- (void)testSetPushNotificationsDeviceTokenString
{
  NSString *mockDeviceTokenString = @"testDeviceTokenString";
  self.eventName = @"fb_mobile_obtain_push_token";

  self.appEvents.pushNotificationsDeviceTokenString = mockDeviceTokenString;

  XCTAssertEqualObjects(
    self.appEventsStateProvider.state.capturedEventDictionary[@"_eventName"],
    self.eventName
  );
  XCTAssertEqualObjects(self.appEvents.pushNotificationsDeviceTokenString, mockDeviceTokenString);
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:nil
                                    parameters:@{}];
}

- (void)testActivateAppWithInitializedSDK
{
  [self.appEvents activateApp];

  XCTAssertTrue(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App with initialized SDK should restore recording time spent data."
  );
  XCTAssertTrue(
    self.timeSpentRecorder.capturedCalledFromActivateApp,
    "Activating App with initialized SDK should indicate its calling from activateApp when restoring recording time spent data."
  );

  // The publish call happens after both configs are fetched
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.appEventsConfigurationProvider.lastCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  self.serverConfigurationProvider.secondCapturedCompletionBlock(nil, nil);

  TestGraphRequest *request = self.graphRequestFactory.capturedRequests.firstObject;
  XCTAssertEqualObjects(request.parameters[@"event"], @"MOBILE_APP_INSTALL");
}

- (void)testApplicationBecomingActiveRestoresTimeSpentRecording
{
  [self.appEvents applicationDidBecomeActive];
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
  [self.appEvents applicationMovingFromActiveStateOrTerminating];
  XCTAssertTrue(
    self.timeSpentRecorder.suspendWasCalled,
    "When application terminates or moves from active state, the time spent recording should be suspended."
  );
}

- (void)testApplicationTerminatingPersistingStates
{
  [self.appEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  [self.appEvents logEvent:self.eventName
                valueToSum:@(self.purchaseAmount)
                parameters:nil
        isImplicitlyLogged:NO
               accessToken:SampleAccessTokens.validToken];
  [self.appEvents logEvent:self.eventName
                valueToSum:@(self.purchaseAmount)
                parameters:nil
        isImplicitlyLogged:NO
               accessToken:SampleAccessTokens.validToken];
  [self.appEvents applicationMovingFromActiveStateOrTerminating];

  XCTAssertTrue(
    self.appEventsStateStore.capturedPersistedState.count > 0,
    "When application terminates or moves from active state, the existing state should be persisted."
  );
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:nil];
}

- (void)testUsingAppEventsWithUninitializedSDK
{
  NSString *foo = @"foo";
  self.appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                            flushPeriodInSeconds:0];
  XCTAssertThrows([self.appEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorAuto]);
  XCTAssertThrows(self.appEvents.loggingOverrideAppID = self.name);
  XCTAssertThrows([self.appEvents logEvent:FBSDKAppEventNameSearched]);
  XCTAssertThrows([self.appEvents logEvent:FBSDKAppEventNameSearched valueToSum:2]);
  XCTAssertThrows([self.appEvents logEvent:FBSDKAppEventNameSearched parameters:@{}]);
  XCTAssertThrows(
    [self.appEvents logEvent:FBSDKAppEventNameSearched
                  valueToSum:2
                  parameters:@{}]
  );
  XCTAssertThrows(
    [self.appEvents logEvent:FBSDKAppEventNameSearched
                  valueToSum:@2
                  parameters:@{}
                 accessToken:SampleAccessTokens.validToken]
  );
  XCTAssertThrows([self.appEvents logPurchase:2 currency:foo]);
  XCTAssertThrows(
    [self.appEvents logPurchase:2
                       currency:foo
                     parameters:@{}]
  );
  XCTAssertThrows(
    [self.appEvents logPurchase:2
                       currency:foo
                     parameters:@{}
                    accessToken:SampleAccessTokens.validToken]
  );
  XCTAssertThrows([self.appEvents logPushNotificationOpen:@{}]);
  XCTAssertThrows([self.appEvents logPushNotificationOpen:@{} action:foo]);
  XCTAssertThrows(
    [self.appEvents logProductItem:foo
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
  XCTAssertThrows([self.appEvents setPushNotificationsDeviceToken:[NSData new]]);
  XCTAssertThrows([self.appEvents setPushNotificationsDeviceTokenString:foo]);
  XCTAssertThrows([self.appEvents flush]);
  XCTAssertThrows([self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken]);
  XCTAssertThrows([self.appEvents augmentHybridWebView:[WKWebView new]]);
  XCTAssertThrows([self.appEvents sendEventBindingsToUnity]);
  XCTAssertThrows([self.appEvents activateApp]);
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  XCTAssertThrows([FBSDKAppEvents clearUserID]);
  #pragma clang diagnostic pop
  XCTAssertThrows(self.appEvents.userID);
  XCTAssertThrows(self.appEvents.userID = foo);

  XCTAssertNoThrow([self.appEvents setIsUnityInitialized:YES]);
  XCTAssertNoThrow(self.appEvents.anonymousID);
  XCTAssertNoThrow([self.appEvents setUserData:foo forType:foo]);
  XCTAssertNoThrow(
    [self.appEvents setUserEmail:nil
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
  XCTAssertNoThrow([self.appEvents getUserData]);
  XCTAssertNoThrow([self.appEvents clearUserDataForType:foo]);

  XCTAssertFalse(
    self.timeSpentRecorder.restoreWasCalled,
    "Activating App without initialized SDK cannot restore recording time spent data."
  );
  [self validateAEMReporterCalledWithEventName:nil
                                      currency:nil
                                         value:nil
                                    parameters:nil];
}

- (void)testLogEventFilteringOutDeactivatedParameters
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [self.appEvents logEvent:self.eventName
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
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:parameters];
}

- (void)testLogEventProcessParametersWithRestrictiveDataFilterParameterProcessor
{
  NSDictionary<NSString *, id> *parameters = @{@"key" : @"value"};
  [self.appEvents logEvent:self.eventName
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

  NSDictionary<NSString *, NSString *> *expectedAEMParameters = @{
    @"fb_push_action" : @"testAction",
    @"fb_push_campaign" : @"testCampaign",
  };

  [self.appEvents logPushNotificationOpen:self.payload action:@"testAction"];
  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"fb_push_action"], @"testAction");
  XCTAssertEqualObjects(capturedParameters[@"fb_push_campaign"], @"testCampaign");
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:nil
                                    parameters:expectedAEMParameters];
}

- (void)testLogPushNotificationOpenWithEmptyAction
{
  self.eventName = @"fb_mobile_push_opened";

  [self.appEvents logPushNotificationOpen:self.payload];

  NSDictionary<NSString *, NSString *> *expectedAEMParameters = @{
    @"fb_push_campaign" : @"testCampaign",
  };

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertNil(capturedParameters[@"fb_push_action"]);
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"fb_push_campaign"], @"testCampaign");
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:nil
                                    parameters:expectedAEMParameters];
}

- (void)testLogPushNotificationOpenWithEmptyPayload
{
  [self.appEvents logPushNotificationOpen:@{}];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
}

- (void)testLogPushNotificationOpenWithEmptyCampaign
{
  self.payload = @{@"fb_push_payload" : @{@"campaign" : @""}};
  [self.appEvents logPushNotificationOpen:self.payload];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "A log entry of LoggingBehaviorDeveloperErrors should be posted if logPushNotificationOpen is fed with empty campagin"
  );
}

- (void)testSetFlushBehavior
{
  self.appEvents.flushBehavior = FBSDKAppEventsFlushBehaviorAuto;
  XCTAssertEqual(FBSDKAppEventsFlushBehaviorAuto, self.appEvents.flushBehavior);

  self.appEvents.flushBehavior = FBSDKAppEventsFlushBehaviorExplicitOnly;
  XCTAssertEqual(FBSDKAppEventsFlushBehaviorExplicitOnly, self.appEvents.flushBehavior);
}

- (void)testCheckPersistedEventsCalledWhenLogEvent
{
  [self.appEvents logEvent:FBSDKAppEventNamePurchased
                valueToSum:@(self.purchaseAmount)
                parameters:@{}
               accessToken:nil];

  XCTAssertTrue(
    self.appEventsStateStore.retrievePersistedAppEventStatesWasCalled,
    "Should retrieve persisted states when logEvent was called and flush behavior was FlushReasonEagerlyFlushingEvent"
  );
  [self validateAEMReporterCalledWithEventName:FBSDKAppEventNamePurchased
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:@{}];
}

- (void)testRequestForCustomAudienceThirdPartyIDWithTrackingDisallowed
{
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingDisallowed;

  XCTAssertNil(
    [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken],
    "Should not create a request for third party id if tracking is disallowed even if there is a current access token"
  );
  XCTAssertNil(
    [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if tracking is disallowed"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithLimitedEventAndDataUsage
{
  self.settings.isEventDataUsageLimited = YES;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  XCTAssertNil(
    [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessTokens.validToken],
    "Should not create a request for third party id if event and data usage is limited even if there is a current access token"
  );
  XCTAssertNil(
    [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if event and data usage is limited"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithoutAdvertiserID
{
  self.settings.isEventDataUsageLimited = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;

  XCTAssertNil(
    [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if there is no access token or advertiser id"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID
{
  NSString *advertiserID = @"abc123";
  self.settings.isEventDataUsageLimited = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  self.advertiserIDProvider.advertiserID = advertiserID;

  [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil];
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
  self.appEventsUtility.stubbedTokenStringToUse = token.tokenString;
  self.appEvents.loggingOverrideAppID = token.appID;

  [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];
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
  self.appEvents.loggingOverrideAppID = token.appID;
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", token.appID];
  NSString *advertiserID = @"abc123";
  self.settings.isEventDataUsageLimited = NO;
  self.settings.advertisingTrackingStatus = FBSDKAdvertisingTrackingAllowed;
  self.advertiserIDProvider.advertiserID = advertiserID;
  self.appEventsUtility.stubbedTokenStringToUse = token.tokenString;

  [self.appEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];

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
  [self.appEvents publishInstall];

  XCTAssertNotNil(
    self.appEventsConfigurationProvider.firstCapturedBlock,
    "Should fetch a configuration before publishing installs"
  );
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];

  [self.appEvents logEvent:self.eventName
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
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:nil];
}

- (void)testAppEventsKillSwitchEnabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:YES];

  [self.appEvents logEvent:self.eventName
                valueToSum:@(self.purchaseAmount)
                parameters:nil
        isImplicitlyLogged:NO
               accessToken:nil];

  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];
  XCTAssertFalse(
    self.appEventsStateProvider.state.isAddEventCalled,
    "Shouldn't add events to AppEventsState when killswitch is enabled"
  );
  [self validateAEMReporterCalledWithEventName:nil
                                      currency:nil
                                         value:nil
                                    parameters:nil];
}

#pragma mark  Tests for log event

- (void)testLogEventWithValueToSum
{
  [self.appEvents logEvent:self.eventName valueToSum:self.purchaseAmount];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @1);
}

- (void)testLogInternalEvents
{
  [self.appEvents logInternalEvent:self.eventName isImplicitlyLogged:NO];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertNil(capturedParameters[@"_valueToSum"]);
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:nil
                                    parameters:@{}];
}

- (void)testLogInternalEventsWithValue
{
  [self.appEvents logInternalEvent:self.eventName valueToSum:self.purchaseAmount isImplicitlyLogged:NO];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:@{}];
}

- (void)testLogInternalEventWithAccessToken
{
  [self.appEvents logInternalEvent:self.eventName parameters:@{} isImplicitlyLogged:NO accessToken:SampleAccessTokens.validToken];

  XCTAssertEqualObjects(self.appEventsStateProvider.capturedAppID, self.mockAppID);
  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertNil(capturedParameters[@"_valueToSum"]);
  XCTAssertNil(capturedParameters[@"_implicitlyLogged"]);
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:nil
                                    parameters:@{}];
}

- (void)testLogEventWhenAutoLogAppEventsDisabled
{
  self.settings.isAutoLogAppEventsEnabled = NO;
  [self.appEvents logInternalEvent:self.eventName valueToSum:self.purchaseAmount isImplicitlyLogged:NO];

  XCTAssertNil(self.appEventsStateProvider.state.capturedEventDictionary);
}

- (void)testLogEventWhenEventsAreDropped
{
  self.appEventsUtility.shouldDropAppEvents = YES;
  self.settings.appID = @"123";

  [self.appEvents logEvent:@"event"];

  XCTAssertNil(
    self.appEventsStateProvider.state,
    @"State should be nil when dropping app events"
  );
}

- (void)testLogEventWhenEventsAreNotDropped
{
  self.appEventsUtility.shouldDropAppEvents = NO;
  self.settings.appID = @"123";

  [self.appEvents logEvent:@"event"];

  XCTAssertNotNil(
    self.appEventsStateProvider.state,
    @"State should not be nil when not dropping app events"
  );
}

- (void)testLogEventWillRecordAndUpdateWithSKAdNetworkReporter
{
  if (@available(iOS 11.3, *)) {
    [self.appEvents logEvent:self.eventName valueToSum:self.purchaseAmount];
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
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:@{}];
}

- (void)testLogImplicitEvent
{
  [self.appEvents logImplicitEvent:self.eventName valueToSum:@(self.purchaseAmount) parameters:@{} accessToken:SampleAccessTokens.validToken];

  NSDictionary<NSString *, id> *capturedParameters = self.appEventsStateProvider.state.capturedEventDictionary;
  XCTAssertEqualObjects(capturedParameters[@"_eventName"], self.eventName);
  XCTAssertEqualObjects(capturedParameters[@"_valueToSum"], @(self.purchaseAmount));
  XCTAssertEqualObjects(capturedParameters[@"_implicitlyLogged"], @"1");
  [self validateAEMReporterCalledWithEventName:self.eventName
                                      currency:nil
                                         value:@(self.purchaseAmount)
                                    parameters:@{}];
}

#pragma mark ParameterProcessing

- (void)testLoggingEventWithoutIntegrityParametersProcessor
{
  self.onDeviceMLModelManager.integrityParametersProcessor = nil;

  [self.appEvents logEvent:@"event" parameters:@{@"foo" : @"bar"}];

  XCTAssertTrue(
    [TestLogger.capturedLogEntry containsString:@"foo = bar"],
    "Should not try to use a nil processor to filter the parameters"
  );
}

- (void)testLoggingEventWithIntegrityParametersProcessor
{
  NSDictionary<NSString *, id> *parameters = @{@"foo" : @"bar"};
  [self.appEvents logEvent:@"event" parameters:parameters];

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
  self.appEventsConfigurationProvider.stubbedConfiguration = configuration;

  __block BOOL didRunCallback = NO;
  [self.appEvents fetchServerConfiguration:^void (void) {
    didRunCallback = YES;
  }];
  XCTAssertNotNil(
    self.appEventsConfigurationProvider.firstCapturedBlock,
    "The expected block should be captured by the AppEventsConfiguration provider"
  );
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureEventDeactivation],
    "Fetching a configuration should check if the EventDeactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingEventDeactivationParameterProcessorIfEventDeactivationEnabled
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureEventDeactivation with:YES];
  XCTAssertTrue(
    self.eventDeactivationParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable event deactivation parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingRestrictiveDataFiltering
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureRestrictiveDataFiltering],
    "Fetching a configuration should check if the RestrictiveDataFiltering feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingRestrictiveDataFilterParameterProcessorIfRestrictiveDataFilteringEnabled
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureRestrictiveDataFiltering with:YES];
  XCTAssertTrue(
    self.restrictiveDataFilterParameterProcessor.enableWasCalled,
    "Fetching a configuration should enable restrictive data filter parameters processor if event deactivation feature is enabled"
  );
}

- (void)testFetchingConfigurationIncludingAAM
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureAAM],
    "Fetch a configuration should check if the AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationEnablingMetadataIndexigIfAAMEnabled
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  [self.featureManager completeCheckForFeature:FBSDKFeatureAAM with:YES];
  XCTAssertTrue(
    self.metadataIndexer.enableWasCalled,
    "Fetching a configuration should enable metadata indexer if AAM feature is enabled"
  );
}

- (void)testFetchingConfigurationStartsPaymentObservingIfConfigurationAllowed
{
  self.settings.isAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  self.settings.isAutoLogAppEventsEnabled = YES;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @NO}];
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  self.settings.isAutoLogAppEventsEnabled = NO;
  FBSDKServerConfiguration *serverConfiguration = [ServerConfigurationFixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled" : @YES}];
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  self.settings.isSKAdNetworkReportEnabled = YES;
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertTrue(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should check if the SKAdNetwork feature is enabled when SKAdNetworkReport is enabled"
  );
}

- (void)testFetchingConfigurationEnablesSKAdNetworkReporterWhenSKAdNetworkReportAndConversionValueEnabled
{
  self.settings.isSKAdNetworkReportEnabled = YES;
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  self.settings.isSKAdNetworkReportEnabled = YES;
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  self.settings.isSKAdNetworkReportEnabled = NO;
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
  self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
  XCTAssertFalse(
    [self.featureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should NOT check if the SKAdNetwork feature is disabled when SKAdNetworkReport is disabled"
  );
}

- (void)testFetchingConfigurationIncludingAEM
{
  if (@available(iOS 14.0, *)) {
    [self.appEvents fetchServerConfiguration:nil];
    self.appEventsConfigurationProvider.firstCapturedBlock();
    self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
    XCTAssertTrue(
      [self.featureManager capturedFeaturesContains:FBSDKFeatureAEM],
      "Fetching a configuration should check if the AEM feature is enabled"
    );
  }
}

- (void)testFetchingConfigurationIncludingAEMCatalogReport
{
  if (@available(iOS 14.0, *)) {
    [self.featureManager enableWithFeature:FBSDKFeatureAEMCatalogReport];
    [self.appEvents fetchServerConfiguration:nil];
    self.appEventsConfigurationProvider.firstCapturedBlock();
    self.serverConfigurationProvider.capturedCompletionBlock(nil, nil);
    [self.featureManager completeCheckForFeature:FBSDKFeatureAEM
                                            with:YES];
    XCTAssertTrue(
      TestAEMReporter.setCatalogReportEnabledWasCalled,
      "Should enable or disable the catalog report"
    );
    XCTAssertTrue(
      TestAEMReporter.capturedSetCatalogReportEnabled,
      "AEM Catalog Report should be enabled"
    );
  }
}

- (void)testFetchingConfigurationIncludingPrivacyProtection
{
  [self.appEvents fetchServerConfiguration:nil];
  self.appEventsConfigurationProvider.firstCapturedBlock();
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
  XCTAssertEqual(self.appEvents.applicationState, UIApplicationStateInactive, "The default value of applicationState should be UIApplicationStateInactive");
  self.appEvents.applicationState = UIApplicationStateBackground;
  XCTAssertEqual(self.appEvents.applicationState, UIApplicationStateBackground, "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground");
}

#pragma mark Source Application Tracking

- (void)testSetSourceApplicationOpenURL
{
  NSURL *url = [NSURL URLWithString:@"www.example.com"];
  [self.appEvents setSourceApplication:self.name openURL:url];

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
  [self.appEvents setSourceApplication:self.name isFromAppLink:YES];

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
  [self.appEvents registerAutoResetSourceApplication];

  XCTAssertTrue(
    self.timeSpentRecorder.wasRegisterAutoResetSourceApplicationCalled,
    "Should have the source application tracker register for auto resetting"
  );
}

- (void)registerAutoResetSourceApplication
{
  [self.timeSpentRecorder registerAutoResetSourceApplication];
}

// MARK: - Helpers

- (void)validateAEMReporterCalledWithEventName:(nullable NSString *)eventName
                                      currency:(nullable NSString *)currency
                                         value:(nullable NSNumber *)value
                                    parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  XCTAssertEqualObjects(
    TestAEMReporter.capturedEvent,
    eventName,
    "Should invoke the AEM reporter with the expected event name"
  );
  XCTAssertEqualObjects(
    TestAEMReporter.capturedCurrency,
    currency,
    "Should invoke the AEM reporter with the correct currency inferred from the parameters"
  );
  XCTAssertEqualObjects(
    TestAEMReporter.capturedValue,
    value,
    "Should invoke the AEM reporter with the expected value"
  );
  XCTAssertEqualObjects(
    TestAEMReporter.capturedParameters,
    parameters,
    "Should invoke the AEM reporter with the expected parameters"
  );
}

@end

NS_ASSUME_NONNULL_END
