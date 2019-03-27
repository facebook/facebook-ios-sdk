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

#import "FBSDKAccessToken.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKConstants.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKUtility.h"

// An extension that redeclares a private method so that it can be mocked
@interface FBSDKApplicationDelegate()
- (void)_logSDKInitialize;
@end

@interface FBSDKAppEvents ()
@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;
- (void)publishInstall;
- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)fetchServerConfiguration:(FBSDKCodeBlock)callback;
+ (FBSDKAppEvents *)singleton;
@end

@interface FBSDKAppEventsTests : XCTestCase
{
  id _mockAppEvents;
}
@end

@implementation FBSDKAppEventsTests

- (void)setUp
{
  _mockAppEvents = [OCMockObject niceMockForClass:[FBSDKAppEvents class]];
}

- (void)tearDown
{
  [_mockAppEvents stopMocking];
}

- (void)testLogPurchase
{
  double mockPurchaseAmount = 1.0;
  NSString *mockCurrency = @"USD";

  id partialMockAppEvents = [OCMockObject partialMockForObject:[FBSDKAppEvents singleton]];

  [[partialMockAppEvents expect] logEvent:FBSDKAppEventNamePurchased valueToSum:@(mockPurchaseAmount) parameters:[OCMArg any] accessToken:[OCMArg any]];
  [[partialMockAppEvents expect] flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];

  OCMStub([partialMockAppEvents flushBehavior]).andReturn(FBSDKAppEventsFlushReasonEagerlyFlushingEvent);

  [FBSDKAppEvents logPurchase:mockPurchaseAmount currency:mockCurrency];

  [partialMockAppEvents verify];
}

- (void)testLogProductItem
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

- (void)testSetAndClearUserID
{
  NSString *mockUserId = @"1";
  [FBSDKAppEvents setUserID:mockUserId];
  XCTAssertEqualObjects([FBSDKAppEvents userID], mockUserId);
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

  [[_mockAppEvents expect] logEvent:@"fb_mobile_obtain_push_token"];

  [FBSDKAppEvents setPushNotificationsDeviceTokenString:mockDeviceTokenString];

  [_mockAppEvents verify];

  XCTAssertEqualObjects([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString, mockDeviceTokenString);
}

- (void)testLogInitialize
{
  FBSDKApplicationDelegate *delegate = [FBSDKApplicationDelegate sharedInstance];
  id delegateMock = OCMPartialMock(delegate);

  [[_mockAppEvents expect] logEvent:@"fb_sdk_initialize"
                         valueToSum:nil
                         parameters:[OCMArg any]
                        accessToken:nil];

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

- (void)testLogPushNotificationOpen
{
  NSDictionary <NSString *, NSString *> *mockFacebookPayload = @{@"campaign" : @"test"};
  NSDictionary <NSString *, NSDictionary<NSString *, NSString*> *> *mockPayload = @{@"fb_push_payload" : mockFacebookPayload};

  [[_mockAppEvents expect] logEvent:@"fb_mobile_push_opened" parameters:[OCMArg any]];

  [FBSDKAppEvents logPushNotificationOpen:mockPayload];

  [_mockAppEvents verify];
}

@end
