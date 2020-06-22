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

#import <OCMock/OCMock.h>

#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"
#import "FBSDKUtility.h"

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

@interface FBSDKAppEventsTests : XCTestCase
{
  id _partialMockAppEvents;
  id _mockAppStates;
  NSString *_mockEventName;
  NSDictionary <NSString *, id> *_mockPayload;
  double _mockPurchaseAmount;
  NSString *_mockCurrency;
}
@end

@implementation FBSDKAppEventsTests

- (void)setUp
{
  [FBSDKAppEvents resetSingleton];
  _partialMockAppEvents = OCMPartialMock([FBSDKAppEvents singleton]);
  OCMStub([_partialMockAppEvents singleton]).andReturn(_partialMockAppEvents);
  _mockAppStates = OCMClassMock([FBSDKAppEventsState class]);
  OCMStub([_mockAppStates alloc]).andReturn(_mockAppStates);
  OCMStub([_mockAppStates initWithToken:[OCMArg any] appID:[OCMArg any]]).andReturn(_mockAppStates);
  _mockEventName = @"fb_mock_event";
  _mockPayload  = @{@"fb_push_payload" : @{@"campaign" : @"testCampaign"}};
  _mockPurchaseAmount = 1.0;
  _mockCurrency = @"USD";

  [FBSDKAppEvents setLoggingOverrideAppID:_mockAppID];
}

- (void)tearDown
{
  [FBSDKAppEvents resetSingleton];
  [_partialMockAppEvents stopMocking];
  [_mockAppStates stopMocking];
  [OHHTTPStubs removeAllStubs];
}

- (void)testLogPurchaseFlush
{
  OCMExpect([_partialMockAppEvents flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent]);

  OCMStub([_partialMockAppEvents flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogPurchase
{
  OCMExpect([_partialMockAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any]]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any] accessToken:[OCMArg any]]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:[OCMArg any] accessToken:[OCMArg any]]).andForwardToRealObject();
  OCMExpect([_mockAppStates addEvent:[OCMArg any] isImplicit:NO]);

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  OCMVerifyAll(_partialMockAppEvents);
  [_mockAppStates verify];
}

- (void)testFlush
{
  OCMExpect([_partialMockAppEvents flushForReason:FBSDKAppEventsFlushReasonExplicit]);

  [FBSDKAppEvents flush];

  OCMVerifyAll(_partialMockAppEvents);
}

#pragma mark  Tests for log product item

- (void)testLogProductItemNonNil
{
  NSDictionary<NSString *, NSString *> *expectedDict = @{
    @"fb_product_availability":@"IN_STOCK",
    @"fb_product_brand":@"PHILZ",
    @"fb_product_condition":@"NEW",
    @"fb_product_description":@"description",
    @"fb_product_gtin":@"BLUE MOUNTAIN",
    @"fb_product_image_link":@"https://www.sample.com",
    @"fb_product_item_id":@"F40CEE4E-471E-45DB-8541-1526043F4B21",
    @"fb_product_link":@"https://www.sample.com",
    @"fb_product_mpn":@"BLUE MOUNTAIN",
    @"fb_product_price_amount":@"1.000",
    @"fb_product_price_currency":@"USD",
    @"fb_product_title":@"title",
  };
  OCMExpect([_partialMockAppEvents logEvent:@"fb_mobile_catalog_update"
                                 parameters:expectedDict]);

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

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogProductItemNilGtinMpnBrand
{
  NSDictionary<NSString *, NSString *> *expectedDict = @{
    @"fb_product_availability":@"IN_STOCK",
    @"fb_product_condition":@"NEW",
    @"fb_product_description":@"description",
    @"fb_product_image_link":@"https://www.sample.com",
    @"fb_product_item_id":@"F40CEE4E-471E-45DB-8541-1526043F4B21",
    @"fb_product_link":@"https://www.sample.com",
    @"fb_product_price_amount":@"1.000",
    @"fb_product_price_currency":@"USD",
    @"fb_product_title":@"title",
  };
  OCMReject([_partialMockAppEvents logEvent:@"fb_mobile_catalog_update"
                                 parameters:expectedDict]);

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
  NSString *mockEmail= @"test_em";
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

  NSDictionary<NSString *, NSString *> *expectedUserData = @{@"em":[FBSDKUtility SHA256Hash:mockEmail],
                                                             @"fn":[FBSDKUtility SHA256Hash:mockFirstName],
                                                             @"ln":[FBSDKUtility SHA256Hash:mockLastName],
                                                             @"ph":[FBSDKUtility SHA256Hash:mockPhone],
  };
  NSDictionary<NSString *, NSString *> *userData = (NSDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[[FBSDKAppEvents getUserData] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                                        options:NSJSONReadingMutableContainers
                                                                                                                          error:nil];
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

  OCMExpect([_partialMockAppEvents logEvent:eventName]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logEvent:eventName
                                 parameters:@{}]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logEvent:eventName
                                 valueToSum:nil
                                 parameters:@{}
                                accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents setPushNotificationsDeviceTokenString:mockDeviceTokenString];

  OCMVerifyAll(_partialMockAppEvents);

  XCTAssertEqualObjects([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testLogInitialize
{
  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  id userDefaultsMock = OCMPartialMock(userDefaults);
  OCMStub([userDefaultsMock integerForKey:[OCMArg any]]).andReturn(1);
  OCMExpect([_partialMockAppEvents logInternalEvent:@"fb_sdk_initialize"
                                         parameters:[OCMArg any]
                                 isImplicitlyLogged:NO]);

  [delegateMock _logSDKInitialize];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testActivateApp
{
  OCMExpect([_partialMockAppEvents publishInstall]);
  OCMExpect([_partialMockAppEvents fetchServerConfiguration:NULL]);

  [FBSDKAppEvents activateApp];

  OCMVerifyAll(_partialMockAppEvents);
}

#pragma mark  Test for log push notification

- (void)testLogPushNotificationOpen
{
  NSString *eventName = @"fb_mobile_push_opened";
  // with action and campaign
  NSDictionary <NSString *, NSString *> *expectedParams1 = @{
    @"fb_push_action":@"testAction",
    @"fb_push_campaign":@"testCampaign",
  };
  OCMExpect([_partialMockAppEvents logEvent:eventName parameters:expectedParams1]);
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload action:@"testAction"];
  OCMVerifyAll(_partialMockAppEvents);

  // empty action
  NSDictionary <NSString *, NSString *> *expectedParams2 = @{
    @"fb_push_campaign":@"testCampaign",
  };
  OCMExpect([_partialMockAppEvents logEvent:eventName parameters:expectedParams2]);
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload];
  OCMVerifyAll(_partialMockAppEvents);

  // empty payload
  OCMReject([_partialMockAppEvents logEvent:eventName parameters:[OCMArg any]]);
  [FBSDKAppEvents logPushNotificationOpen:@{}];

  // empty campaign
  NSDictionary <NSString *, id> *mockPayload = @{@"fb_push_payload" : @{@"campaign" : @""}};
  OCMReject([_partialMockAppEvents logEvent:eventName parameters:[OCMArg any]]);
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

  OCMExpect([_partialMockAppEvents checkPersistedEvents]);

  OCMStub([_partialMockAppEvents flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testRequestForCustomAudienceThirdPartyIDWithAccessToken
{
  id mockAccessToken = [OCMockObject niceMockForClass:[FBSDKAccessToken class]];
  id mockAppEventsUtility = [OCMockObject niceMockForClass:[FBSDKAppEventsUtility class]];
  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:mockAccessToken];
  NSString *graphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", _mockAppID];
  FBSDKGraphRequest *expectedRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                         parameters:@{}
                                                                        tokenString:tokenString
                                                                         HTTPMethod:nil
                                                                              flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];

  OCMStub([mockAppEventsUtility attributionID]).andReturn(NULL);

  // without access token
  [[mockAppEventsUtility expect] advertiserID];

  FBSDKGraphRequest *request = [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:nil];

  [mockAppEventsUtility verify];

  XCTAssertNil(request);

  // with access token
  [[mockAppEventsUtility reject] advertiserID];

  request = [FBSDKAppEvents requestForCustomAudienceThirdPartyIDWithAccessToken:mockAccessToken];

  XCTAssertEqualObjects(expectedRequest.graphPath, request.graphPath);
  XCTAssertEqualObjects(expectedRequest.HTTPMethod, request.HTTPMethod);
  XCTAssertEqualObjects(expectedRequest.parameters, expectedRequest.parameters);
}

- (void)testPublishInstall
{
  OCMExpect([_partialMockAppEvents fetchServerConfiguration:[OCMArg any]]);

  [_partialMockAppEvents publishInstall];

  OCMVerifyAll(_partialMockAppEvents);
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  id mockGateKeeperManager = OCMClassMock([FBSDKGateKeeperManager class]);
  OCMStub([mockGateKeeperManager boolForKey:[OCMArg any]
                               defaultValue:NO]).andReturn(NO);

  OCMExpect([_mockAppStates addEvent:[OCMArg any] isImplicit:NO]);

  [_partialMockAppEvents instanceLogEvent:_mockEventName
                               valueToSum:@(_mockPurchaseAmount)
                               parameters:nil
                       isImplicitlyLogged:NO
                              accessToken:nil];

  [_mockAppStates verify];
}

- (void)testAppEventsKillSwitchEnabled
{
  id mockGateKeeperManager = OCMClassMock([FBSDKGateKeeperManager class]);
  OCMStub([mockGateKeeperManager boolForKey:[OCMArg any]
                               defaultValue:NO]).andReturn(YES);

  OCMReject([_mockAppStates addEvent:[OCMArg any] isImplicit:NO]);

  [_partialMockAppEvents instanceLogEvent:_mockEventName
                               valueToSum:@(_mockPurchaseAmount)
                               parameters:nil
                       isImplicitlyLogged:NO
                              accessToken:nil];
}

- (void)testGraphRequestBannedWithAutoInitDisabled
{
  //test when autoInitEnabled is set to be NO
  __block int activiesEndpointCalledCountDisabled = 0;
  NSString *urlString = [NSString stringWithFormat:@"%@/activities", _mockAppID];
  XCTestExpectation *expectation = [self expectationWithDescription:@"No Graph Request is sent"];

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    XCTAssertNotNil(request);
    if ([request.URL.absoluteString rangeOfString:urlString].location != NSNotFound) {
      ++activiesEndpointCalledCountDisabled;
    }
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  [FBSDKSettings setAutoInitEnabled:NO];
  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];
  [expectation fulfill];
  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqual(0, activiesEndpointCalledCountDisabled, @"No Graph Request is sent");
}

#pragma mark  Tests for log event

- (void)testLogEventWithValueToSum
{
  OCMExpect([_partialMockAppEvents logEvent:_mockEventName
                                 valueToSum:_mockPurchaseAmount
                                 parameters:@{}]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logEvent:_mockEventName
                                 valueToSum:@(_mockPurchaseAmount)
                                 parameters:@{}
                                accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents logEvent:_mockEventName valueToSum:_mockPurchaseAmount];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogInternalEvents
{
  OCMExpect([_partialMockAppEvents logInternalEvent:_mockEventName
                                         parameters:@{}
                                 isImplicitlyLogged:NO]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logInternalEvent:_mockEventName
                                         valueToSum:nil
                                         parameters:@{}
                                 isImplicitlyLogged:NO
                                        accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName isImplicitlyLogged:NO];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogInternalEventsWithValue
{
  OCMExpect([_partialMockAppEvents logInternalEvent:_mockEventName
                                         valueToSum:_mockPurchaseAmount
                                         parameters:@{}
                                 isImplicitlyLogged:NO]).andForwardToRealObject();
  OCMExpect([_partialMockAppEvents logInternalEvent:_mockEventName
                                         valueToSum:@(_mockPurchaseAmount)
                                         parameters:@{}
                                 isImplicitlyLogged:NO
                                        accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogInternalEventWithAccessToken
{
  id mockAccessToken = [OCMockObject niceMockForClass:[FBSDKAccessToken class]];
  OCMExpect([_partialMockAppEvents logInternalEvent:_mockEventName
                                         valueToSum:nil
                                         parameters:@{}
                                 isImplicitlyLogged:NO
                                        accessToken:mockAccessToken]).andForwardToRealObject();
  [FBSDKAppEvents logInternalEvent:_mockEventName parameters:@{} isImplicitlyLogged:NO accessToken:mockAccessToken];
  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testInstanceLogEventWhenAutoLogAppEventsDisabled
{
  id mockSetting = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockSetting isAutoLogAppEventsEnabled]).andReturn(NO);
  OCMReject([_partialMockAppEvents instanceLogEvent:_mockEventName
                                         valueToSum:@(_mockPurchaseAmount)
                                         parameters:@{}
                                 isImplicitlyLogged:NO
                                        accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];
}

- (void)testInstanceLogEventWhenAutoLogAppEventsEnabled
{
  id mockSetting = OCMClassMock([FBSDKSettings class]);
  OCMStub([mockSetting isAutoLogAppEventsEnabled]).andReturn(YES);
  OCMExpect([_partialMockAppEvents instanceLogEvent:_mockEventName
                                         valueToSum:@(_mockPurchaseAmount)
                                         parameters:@{}
                                 isImplicitlyLogged:NO
                                        accessToken:nil]).andForwardToRealObject();

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  OCMVerifyAll(_partialMockAppEvents);
}

- (void)testLogImplicitEvent
{
  OCMExpect([_partialMockAppEvents instanceLogEvent:_mockEventName
                                         valueToSum:@(_mockPurchaseAmount)
                                         parameters:@{}
                                 isImplicitlyLogged:YES
                                        accessToken:nil]);

  [FBSDKAppEvents logImplicitEvent:_mockEventName valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  OCMVerifyAll(_partialMockAppEvents);
}

@end
