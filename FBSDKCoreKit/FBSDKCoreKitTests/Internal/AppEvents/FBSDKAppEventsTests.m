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
  id _mockAppEvents;
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
  _mockAppEvents = [OCMockObject niceMockForClass:[FBSDKAppEvents class]];
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
  [_mockAppEvents stopMocking];
  [_mockAppStates stopMocking];
  [OHHTTPStubs removeAllStubs];
}

- (void)testLogPurchaseFlush
{
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];

  [[partialMockAppEvents expect] flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];

  OCMStub([partialMockAppEvents flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  [partialMockAppEvents verify];
}

- (void)testLogPurchase
{
  [[[_mockAppEvents expect] andForwardToRealObject] logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any]];
  [[[_mockAppEvents expect] andForwardToRealObject] logPurchase:_mockPurchaseAmount currency:_mockCurrency parameters:[OCMArg any] accessToken:[OCMArg any]];
  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:[OCMArg any] accessToken:[OCMArg any]];
  [[_mockAppStates expect] addEvent:[OCMArg any] isImplicit:NO];

  [FBSDKAppEvents logPurchase:_mockPurchaseAmount currency:_mockCurrency];

  [_mockAppEvents verify];
  [_mockAppStates verify];
}

- (void)testFlush
{
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];

  [[partialMockAppEvents expect] flushForReason:FBSDKAppEventsFlushReasonExplicit];

  [FBSDKAppEvents flush];

  [partialMockAppEvents verify];
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
  [[_mockAppEvents expect] logEvent:@"fb_mobile_catalog_update"
                         parameters:expectedDict];

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

  [_mockAppEvents verify];
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
  [[_mockAppEvents reject] logEvent:@"fb_mobile_catalog_update"
                         parameters:expectedDict];

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

  NSDictionary<NSString *, NSString *> *expectedHashedDict = @{@"em":[FBSDKUtility SHA256Hash:mockEmail],
                                                               @"fn":[FBSDKUtility SHA256Hash:mockFirstName],
                                                               @"ln":[FBSDKUtility SHA256Hash:mockLastName],
                                                               @"ph":[FBSDKUtility SHA256Hash:mockPhone],
                                                               };
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:expectedHashedDict
                                                     options:0
                                                       error:nil];
  NSString *expectedUserData = [[NSString alloc] initWithData:jsonData
                                 encoding:NSUTF8StringEncoding];
  NSString *userData = [FBSDKAppEvents getUserData];
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

  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:eventName];
  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:eventName
                                                  parameters:@{}];
  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:eventName
                                                  valueToSum:nil
                                                  parameters:@{}
                                                 accessToken:nil];

  [FBSDKAppEvents setPushNotificationsDeviceTokenString:mockDeviceTokenString];

  [_mockAppEvents verify];

  XCTAssertEqualObjects([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testLogInitialize
{
  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  id userDefaultsMock = OCMPartialMock(userDefaults);
  [OCMStub([userDefaultsMock integerForKey:[OCMArg any]]) andReturnValue: OCMOCK_VALUE(1)];
  [[_mockAppEvents expect] logInternalEvent:@"fb_sdk_initialize"
                                 parameters:[OCMArg any]
                         isImplicitlyLogged:NO];

  [delegateMock _logSDKInitialize];

  [_mockAppEvents verify];
}

- (void)testActivateApp
{
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [[partialMockAppEvents expect] publishInstall];
  [[partialMockAppEvents expect] fetchServerConfiguration:NULL];

  [FBSDKAppEvents activateApp];

  [partialMockAppEvents verify];
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
  [[_mockAppEvents expect] logEvent:eventName parameters:expectedParams1];
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload action:@"testAction"];
  [_mockAppEvents verify];

  // empty action
  NSDictionary <NSString *, NSString *> *expectedParams2 = @{
                                                             @"fb_push_campaign":@"testCampaign",
                                                             };
  [[_mockAppEvents expect] logEvent:eventName parameters:expectedParams2];
  [FBSDKAppEvents logPushNotificationOpen:_mockPayload];
  [_mockAppEvents verify];

  // empty payload
  [[_mockAppEvents reject] logEvent:eventName parameters:[OCMArg any]];
  [FBSDKAppEvents logPushNotificationOpen:@{}];

  // empty campaign
  NSDictionary <NSString *, id> *mockPayload = @{@"fb_push_payload" : @{@"campaign" : @""}};
  [[_mockAppEvents reject] logEvent:eventName parameters:[OCMArg any]];
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
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];

  [[partialMockAppEvents expect] checkPersistedEvents];

  OCMStub([partialMockAppEvents flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  [partialMockAppEvents verify];
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
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [[partialMockAppEvents expect] fetchServerConfiguration:[OCMArg any]];

  [[FBSDKAppEvents singleton] publishInstall];

  [partialMockAppEvents verify];
}

#pragma mark  Tests for Kill Switch

- (void)testAppEventsKillSwitchDisabled
{
  id mockGateKeeperManager = OCMClassMock([FBSDKGateKeeperManager class]);
  OCMStub([mockGateKeeperManager boolForKey:[OCMArg any]
                               defaultValue:NO]).andReturn(NO);

  [[_mockAppStates expect] addEvent:[OCMArg any] isImplicit:NO];

  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [partialMockAppEvents instanceLogEvent:_mockEventName
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

  [[_mockAppStates reject] addEvent:[OCMArg any] isImplicit:NO];

  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [partialMockAppEvents instanceLogEvent:_mockEventName
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

#pragma mark  Tests for update user properties

- (void)testGraphRequestWhenUpdateUserProperties
{
  [FBSDKAppEvents setUserID:_mockUserID];
  NSString *urlString = [NSString stringWithFormat:@"%@/user_properties", _mockAppID];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    XCTAssertNotNil(request);
    XCTAssertTrue([request.URL.absoluteString rangeOfString:urlString].location != NSNotFound);
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  [FBSDKAppEvents updateUserProperties:@{
                                         @"favorite_color" : @"blue",
                                         @"created" : [NSDate date].description,
                                         @"email" : @"someemail@email.com",
                                         @"some_id" : @"Custom:1",
                                         @"validated" : @YES,
                                         }
                               handler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
}

- (void)testUpdateUserPropertiesWithEmptyUserID
{
  [FBSDKAppEvents setUserID:@""];
  id mockLogger = [OCMockObject niceMockForClass:[FBSDKLogger class]];
  [[mockLogger expect] singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                logEntry:@"Missing [FBSDKAppEvents userID] for [FBSDKAppEvents updateUserProperties:]"];
  id mockBasicUtility = [OCMockObject niceMockForClass:[FBSDKBasicUtility class]];
  [[mockBasicUtility reject] dictionary:[OCMArg any] setObject:[FBSDKAppEvents userID] forKey:@"user_unique_id"];

  [FBSDKAppEvents updateUserProperties:@{
                                         @"favorite_color" : @"blue",
                                         @"created" : [NSDate date].description,
                                         @"email" : @"someemail@email.com",
                                         @"some_id" : @"Custom:1",
                                         @"validated" : @YES,
                                         }
                               handler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
  [mockLogger verify];
}

#pragma mark  Tests for log event

- (void)testLogEventWithValueToSum
{
  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:_mockEventName
                                                  valueToSum:_mockPurchaseAmount
                                                  parameters:@{}];
  [[[_mockAppEvents expect] andForwardToRealObject] logEvent:_mockEventName
                                                  valueToSum:@(_mockPurchaseAmount)
                                                  parameters:@{}
                                                 accessToken:nil];

  [FBSDKAppEvents logEvent:_mockEventName valueToSum:_mockPurchaseAmount];

  [_mockAppEvents verify];
}

- (void)testLogInternalEvents
{
  [[[_mockAppEvents expect] andForwardToRealObject] logInternalEvent:_mockEventName
                                                          parameters:@{}
                                                  isImplicitlyLogged:NO];
  [[[_mockAppEvents expect] andForwardToRealObject] logInternalEvent:_mockEventName
                                                          valueToSum:nil
                                                          parameters:@{}
                                                  isImplicitlyLogged:NO
                                                         accessToken:nil];

  [FBSDKAppEvents logInternalEvent:_mockEventName isImplicitlyLogged:NO];

  [_mockAppEvents verify];
}

- (void)testLogInternalEventsWithValue
{
  [[[_mockAppEvents expect] andForwardToRealObject] logInternalEvent:_mockEventName
                                                          valueToSum:_mockPurchaseAmount
                                                          parameters:@{}
                                                  isImplicitlyLogged:NO];
  [[[_mockAppEvents expect] andForwardToRealObject] logInternalEvent:_mockEventName
                                                          valueToSum:@(_mockPurchaseAmount)
                                                          parameters:@{}
                                                  isImplicitlyLogged:NO
                                                         accessToken:nil];

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  [_mockAppEvents verify];
}

- (void)testLogInternalEventWithAccessToken
{
  id mockAccessToken = [OCMockObject niceMockForClass:[FBSDKAccessToken class]];
  [[[_mockAppEvents expect] andForwardToRealObject] logInternalEvent:_mockEventName
                                                          valueToSum:nil
                                                          parameters:@{}
                                                  isImplicitlyLogged:NO
                                                         accessToken:mockAccessToken];
  [FBSDKAppEvents logInternalEvent:_mockEventName parameters:@{} isImplicitlyLogged:NO accessToken:mockAccessToken];
  [_mockAppEvents verify];
}

- (void)testInstanceLogEventWhenAutoLogAppEventsDisabled
{
  id mockSetting = [OCMockObject niceMockForClass:[FBSDKSettings class]];
  OCMStub([mockSetting isAutoLogAppEventsEnabled]).andReturn(NO);
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [[[partialMockAppEvents reject] andForwardToRealObject] instanceLogEvent:_mockEventName
                                                                valueToSum:@(_mockPurchaseAmount)
                                                                parameters:@{}
                                                        isImplicitlyLogged:NO
                                                               accessToken:nil];

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];
}

- (void)testInstanceLogEventWhenAutoLogAppEventsEnabled
{
  id mockSetting = [OCMockObject niceMockForClass:[FBSDKSettings class]];
  OCMStub([mockSetting isAutoLogAppEventsEnabled]).andReturn(YES);
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [[[partialMockAppEvents expect] andForwardToRealObject] instanceLogEvent:_mockEventName
                                                                valueToSum:@(_mockPurchaseAmount)
                                                                parameters:@{}
                                                        isImplicitlyLogged:NO
                                                               accessToken:nil];

  [FBSDKAppEvents logInternalEvent:_mockEventName valueToSum:_mockPurchaseAmount isImplicitlyLogged:NO];

  [partialMockAppEvents verify];
}

- (void)testLogImplicitEvent
{
  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];
  [[partialMockAppEvents expect] instanceLogEvent:_mockEventName
                                       valueToSum:@(_mockPurchaseAmount)
                                       parameters:@{}
                               isImplicitlyLogged:YES
                                      accessToken:nil];

  [FBSDKAppEvents logImplicitEvent:_mockEventName valueToSum:@(_mockPurchaseAmount) parameters:@{} accessToken:nil];

  [partialMockAppEvents verify];
}

@end
