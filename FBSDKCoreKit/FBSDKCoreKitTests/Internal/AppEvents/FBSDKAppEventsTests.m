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

#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
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
- (void)checkPersistedEvents;
- (void)publishInstall;
- (void)publishATE;
- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)fetchServerConfiguration:(FBSDKCodeBlock)callback;
- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (FBSDKAppEvents *)singleton;

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
}
@end

@implementation FBSDKAppEventsTests

- (void)setUp
{
  self.shouldAppEventsMockBePartial = YES;

  [super setUp];

  [self stubLoadingAdNetworkReporterConfiguration];
  [self stubServerConfigurationFetchingWithConfiguration:FBSDKServerConfigurationFixtures.defaultConfig error:nil];

  _mockEventName = @"fb_mock_event";
  _mockPayload = @{@"fb_push_payload" : @{@"campaign" : @"testCampaign"}};
  _mockPurchaseAmount = 1.0;
  _mockCurrency = @"USD";

  [FBSDKAppEvents setLoggingOverrideAppID:_mockAppID];

  // Mock FBSDKAppEventsUtility methods
  [self stubAppEventsUtilityShouldDropAppEventWith:NO];

  // This should be removed when these tests are updated to check the actual requests that are created
  [self stubAllocatingGraphRequestConnection];
}

- (void)tearDown
{
  [super tearDown];

  [OHHTTPStubs removeAllStubs];
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

- (void)testActivateApp
{
  OCMExpect([self.appEventsMock publishInstall]);
  OCMExpect([self.appEventsMock fetchServerConfiguration:NULL]);

  [FBSDKAppEvents activateApp];

  OCMVerifyAll(self.appEventsMock);
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
  [self stubUserDefaultsWith:[UserDefaultsSpy new]];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingDisallowed];

  XCTAssertNil(
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessToken.validToken],
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
    [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:SampleAccessToken.validToken],
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

  FBSDKGraphRequest *request = [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil];
  XCTAssertEqualObjects(
    request.parameters,
    @{ @"udid" : advertiserID },
    "Should include the udid in the request when there is no access token available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithoutAdvertiserID
{
  FBSDKAccessToken *token = SampleAccessToken.validToken;
  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
  [self stubAppEventsUtilityAdvertiserIDWith:nil];
  [self stubAppEventsUtilityTokenStringToUseForTokenWith:token.tokenString];

  FBSDKGraphRequest *request = [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];
  XCTAssertEqualObjects(
    request.tokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    request.parameters[@"udid"],
    "Should not include the udid in the request when there is none available"
  );
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithAdvertiserID
{
  NSString *expectedGraphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", _mockAppID];

  FBSDKAccessToken *token = SampleAccessToken.validToken;
  NSString *advertiserID = @"abc123";

  [self stubSettingsShouldLimitEventAndDataUsageWith:NO];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];
  [self stubAppEventsUtilityTokenStringToUseForTokenWith:token.tokenString];
  [self stubAppEventsUtilityAdvertiserIDWith:advertiserID];

  FBSDKGraphRequest *request = [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:token];

  XCTAssertEqualObjects(
    request.tokenString,
    token.tokenString,
    "Should include the access token in the request when there is one available"
  );
  XCTAssertNil(
    request.parameters[@"udid"],
    "Should not include the udid in the request when there is an access token available"
  );
  XCTAssertEqualObjects(
    request.graphPath,
    expectedGraphPath,
    "Should use the expected graph path for the request"
  );
  XCTAssertEqual(
    request.HTTPMethod,
    FBSDKHTTPMethodGET,
    "Should use the expected http method for the request"
  );
  XCTAssertEqual(
    request.flags,
    FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery,
    "Should use the expected flags for the request"
  );
}

- (void)testPublishInstall
{
  [self stubUserDefaultsWith:[UserDefaultsSpy new]];
  [self stubAppID:self.appID];
  OCMExpect([self.appEventsMock fetchServerConfiguration:[OCMArg any]]);

  [self.appEventsMock publishInstall];

  OCMVerifyAll(self.appEventsMock);
}

- (void)testPublishATEWithNoPing
{
  [self stubAppID:@"mockAppID"];
  [self stubUserDefaultsWith:[UserDefaultsSpy new]];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  id graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:FBSDKHTTPMethodPOST
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  [self.appEventsMock publishATE];

  OCMVerify([graphRequestMock startWithCompletionHandler:[OCMArg any]]);

  [graphRequestMock stopMocking];
  graphRequestMock = nil;
}

- (void)testPublishATEWithPingLessThan24Hours
{
  [self stubAppID:@"mockAppID"];
  UserDefaultsSpy *userDefault = [UserDefaultsSpy new];
  [userDefault setObject:[NSDate dateWithTimeIntervalSinceNow:-12 * 60 * 60] forKey:[NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", @"mockAppID"]];
  [self stubUserDefaultsWith:userDefault];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  id graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:FBSDKHTTPMethodPOST
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  [self.appEventsMock publishATE];

  OCMReject([graphRequestMock startWithCompletionHandler:[OCMArg any]]);

  [graphRequestMock stopMocking];
  graphRequestMock = nil;
}

- (void)testPublishATEWithVerifyingParams
{
  [self stubAppID:@"mockAppID"];
  [self stubUserDefaultsWith:[UserDefaultsSpy new]];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  [self.appEventsMock publishATE];

  OCMReject(
    [self.appEventsUtilityClassMock activityParametersDictionaryForEvent:[OCMArg any]
                                               shouldAccessAdvertisingID:[OCMArg any]]
  );
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  id mockGateKeeperManager = OCMClassMock([FBSDKGateKeeperManager class]);
  OCMStub(
    [mockGateKeeperManager boolForKey:[OCMArg any]
                         defaultValue:NO]
  ).andReturn(NO);

  OCMExpect([self.appEventStatesMock addEvent:[OCMArg any] isImplicit:NO]);

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  [self.appEventStatesMock verify];

  [mockGateKeeperManager stopMocking];
  mockGateKeeperManager = nil;
}

- (void)testAppEventsKillSwitchEnabled
{
  id mockGateKeeperManager = OCMClassMock([FBSDKGateKeeperManager class]);
  OCMStub(
    [mockGateKeeperManager boolForKey:[OCMArg any]
                         defaultValue:NO]
  ).andReturn(YES);

  OCMReject([self.appEventStatesMock addEvent:[OCMArg any] isImplicit:NO]);

  [self.appEventsMock instanceLogEvent:_mockEventName
                            valueToSum:@(_mockPurchaseAmount)
                            parameters:nil
                    isImplicitlyLogged:NO
                           accessToken:nil];

  [mockGateKeeperManager stopMocking];
  mockGateKeeperManager = nil;
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

@end
