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
#import "FBSDKSettings.h"
#import "FBSDKTestCase.h"
#import "FBSDKUtility.h"
#import "UserDefaultsSpy.h"

static NSString *const _mockAppID = @"mockAppID";
static NSString *const _mockUserID = @"mockUserID";

// An extension that redeclares a private method so that it can be mocked
@interface FBSDKApplicationDelegate ()
- (void)_logSDKInitialize;
@end

@interface FBSDKAppEvents ()
@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;
@property (nonatomic, strong) id<FBSDKAtePublishing> atePublisher;

- (void)checkPersistedEvents;
- (void)publishInstall;
- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)fetchServerConfiguration:(FBSDKCodeBlock)callback;
- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (FBSDKAppEvents *)singleton;

+ (void)reset;

+ (void)setCanLogEvents;

+ (BOOL)canLogEvents;

+ (UIApplicationState)applicationState;

+ (void)setGateKeeperManager:(Class<FBSDKGateKeeperManaging>)manager;

+ (void)setAppEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider;

+ (void)setServerConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)provider;

+ (void)setRequestProvider:(id<FBSDKGraphRequestProviding>)provider;

+ (void)setFeatureChecker:(Class<FBSDKFeatureChecking>)checker;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(NSDictionary<NSString *, id> *)parameters
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
}
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

  [FBSDKSettings reset];
  [FBSDKInternalUtility reset];
  [TestFeatureManager reset];
  [FBSDKAppEvents setAppEventsConfigurationProvider:TestAppEventsConfigurationProvider.class];
  [FBSDKAppEvents setServerConfigurationProvider:TestServerConfigurationProvider.class];
  [FBSDKAppEvents setFeatureChecker:TestFeatureManager.class];
  [TestLogger reset];

  [self stubLoadingAdNetworkReporterConfiguration];
  [self stubServerConfigurationFetchingWithConfiguration:FBSDKServerConfigurationFixtures.defaultConfig error:nil];

  _mockEventName = @"fb_mock_event";
  _mockPayload = @{@"fb_push_payload" : @{@"campaign" : @"testCampaign"}};
  _mockPurchaseAmount = 1.0;
  _mockCurrency = @"USD";
  _graphRequestFactory = [TestGraphRequestFactory new];
  _store = [UserDefaultsSpy new];

  [FBSDKAppEvents setLoggingOverrideAppID:_mockAppID];

  // Mock FBSDKAppEventsUtility methods
  [self stubAppEventsUtilityShouldDropAppEventWith:NO];

  // This should be removed when these tests are updated to check the actual requests that are created
  [self stubAllocatingGraphRequestConnection];
  [FBSDKAppEvents configureWithGateKeeperManager:TestGateKeeperManager.self
                  appEventsConfigurationProvider:TestAppEventsConfigurationProvider.self
                     serverConfigurationProvider:TestServerConfigurationProvider.self
                            graphRequestProvider:_graphRequestFactory
                                  featureChecker:TestFeatureManager.self
                                           store:_store
                                          logger:TestLogger.self];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKAppEvents reset];
  [TestAppEventsConfigurationProvider reset];
  [TestServerConfigurationProvider reset];
}

- (void)testInitializingCreatesAtePublisher
{
  // This is necessary for now because we stub the AppEvents Singleton. Should be able
  // to move away from this pattern once all the dependencies are manageable but for now
  // this is a workaround to be able to test that initializing uses the dependencies
  // configured on the type to create objects.
  FBSDKAppEvents *events = (FBSDKAppEvents *)[(NSObject *)[FBSDKAppEvents alloc] init];
  FBSDKAppEventsAtePublisher *publisher = events.atePublisher;

  XCTAssertEqualObjects(
    publisher.store,
    _store,
    "Initializing should create an ate publisher with the expected data store"
  );
  XCTAssertEqualObjects(
    publisher.appIdentifier,
    _mockAppID,
    "Initializing should create an ate publisher with the expected app id"
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
  OCMExpect([self.appEventStatesMock addEvent:[OCMArg any] isImplicit:NO]);

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  OCMVerifyAll(self.appEventsMock);
  [self.appEventStatesMock verify];
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

- (void)testLogInitialize
{
  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  id userDefaultsMock = OCMPartialMock(userDefaults);
  OCMStub([userDefaultsMock integerForKey:[OCMArg any]]).andReturn(1);
  OCMExpect(
    [self.appEventsMock logInternalEvent:@"fb_sdk_initialize"
                              parameters:[OCMArg any]
                      isImplicitlyLogged:NO]
  );

  [delegateMock _logSDKInitialize];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testActivateAppWithInitializedSDK
{
  [FBSDKAppEvents setCanLogEvents];

  OCMExpect([self.appEventsMock publishInstall]);
  OCMExpect([self.appEventsMock fetchServerConfiguration:NULL]);

  [FBSDKAppEvents activateApp];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testActivateAppWithoutInitializedSDK
{
  [FBSDKAppEvents activateApp];

  OCMReject([self.appEventsMock publishInstall]);
  OCMReject([self.appEventsMock fetchServerConfiguration:NULL]);
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
  OCMExpect([self.appEventsMock checkPersistedEvents]);

  OCMStub([self.appEventsMock flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testRequestForCustomAudienceThirdPartyIDWithTrackingDisallowed
{
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingDisallowed];

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
  [self stubSettingsShouldLimitEventAndDataUsageWith:YES];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

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
  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
  [self stubAppEventsUtilityAdvertiserIDWith:nil];

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil],
    "Should not create a request for third party id if there is no access token or advertiser id"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID
{
  NSString *advertiserID = @"abc123";
  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
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
  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
  [self stubAppEventsUtilityAdvertiserIDWith:nil];
  [self stubAppEventsUtilityTokenStringToUseForTokenWith:token.tokenString];

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
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", _mockAppID];

  FBSDKAccessToken *token = SampleAccessTokens.validToken;
  NSString *advertiserID = @"abc123";

  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
  [self stubAppEventsUtilityTokenStringToUseForTokenWith:token.tokenString];
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
  [self stubAppID:self.appID];
  OCMExpect([self.appEventsMock fetchServerConfiguration:[OCMArg any]]);

  [self.appEventsMock publishInstall];

  OCMVerifyAll(self.appEventsMock);
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];

  OCMExpect([self.appEventStatesMock addEvent:[OCMArg any] isImplicit:NO]);

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  [self.appEventStatesMock verify];
}

- (void)testAppEventsKillSwitchEnabled
{
  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:YES];

  OCMReject([self.appEventStatesMock addEvent:[OCMArg any] isImplicit:NO]);

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  [TestGateKeeperManager setGateKeeperValueWithKey:@"app_events_killswitch" value:NO];
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
  [self stubIsAutoLogAppEventsEnabled:NO];
  OCMReject(
    [self.appEventsMock instanceLogEvent:_mockEventName
                              valueToSum:@(_mockPurchaseAmount)
                              parameters:@{}
                      isImplicitlyLogged:NO
                             accessToken:nil]
  ).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];
}

- (void)testInstanceLogEventWhenAutoLogAppEventsEnabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];
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
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureRestrictiveDataFiltering],
    "fetchConfiguration should check if the RestrictiveDataFiltering feature is enabled"
  );
  // TODO: Once FBSDKRestrictiveDataFilterManager is injected, similar for all other features
  //
  // [TestFeatureManager capturedCompletionBlocks[FBSDKFeatureRestrictiveDataFiltering](YES)
  //
  // XCTAssertTrue(
  // self.restrictiveDataFilterManager.isEnabled,
  // "Should use the feature manager to determine if features are enabled"
  // )

  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureEventDeactivation],
    "fetchConfiguration should check if the EventDeactivation feature is enabled"
  );
  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureATELogging],
    "fetchConfiguration should check if the ATELogging feature is enabled"
  );
  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureCodelessEvents],
    "fetchConfiguration should check if CodelessEvents feature is enabled"
  );
  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureAAM],
    "fetchConfiguration should check if the AAM feature is enabled"
  );
  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeaturePrivacyProtection],
    "fetchConfiguration should check if the PrivacyProtection feature is enabled"
  );
  XCTAssertTrue(
    [TestFeatureManager capturedFeaturesContains:FBSDKFeatureSKAdNetwork],
    "fetchConfiguration should check if the SKAdNetwork feature is enabled"
  );
}

#pragma mark Test for Singleton Values

- (void)testCanLogEventValues
{
  [FBSDKAppEvents reset];
  XCTAssertFalse([FBSDKAppEvents canLogEvents], "The default value of canLogEvents should be NO");
  [FBSDKAppEvents setCanLogEvents];
  XCTAssertTrue([FBSDKAppEvents canLogEvents], "canLogEvents should now have a value of YES");
}

- (void)testApplicationStateValues
{
  XCTAssertEqual([FBSDKAppEvents applicationState], UIApplicationStateInactive, "The default value of applicationState should be UIApplicationStateInactive");
  [FBSDKAppEvents setApplicationState:UIApplicationStateBackground];
  XCTAssertEqual([FBSDKAppEvents applicationState], UIApplicationStateBackground, "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground");
}

@end
