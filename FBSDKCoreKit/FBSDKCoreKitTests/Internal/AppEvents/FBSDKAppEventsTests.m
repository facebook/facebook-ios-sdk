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

#import "FBSDKAppEvents.h"
#import "FBSDKGraphRequestConnection.h"

@interface FBSDKAppEventsTests : XCTestCase
{
  id _mockAppEvents;
  id _mockGraphRequestConnection;
}
@end

@implementation FBSDKAppEventsTests

- (void)setUp
{
  _mockAppEvents = [OCMockObject niceMockForClass:[FBSDKAppEvents class]];
  _mockGraphRequestConnection = [OCMockObject niceMockForClass:[FBSDKGraphRequestConnection class]];
}

- (void)testLogPurchase
{
  double mockPurchaseAmount = 1.0;
  NSString *mockCurrency = @"USD";
  [[_mockAppEvents expect] logEvent:FBSDKAppEventNamePurchased valueToSum:@(mockPurchaseAmount) parameters:[OCMArg any] accessToken:[OCMArg any]];
  [FBSDKAppEvents logPurchase:mockPurchaseAmount currency:mockCurrency];
  [_mockAppEvents verify];
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
  [FBSDKAppEvents setUserEmail:@"em"
                     firstName:@"fn"
                      lastName:@"ln"
                         phone:@"123"
                   dateOfBirth:nil
                        gender:nil
                          city:nil
                         state:nil
                           zip:nil
                       country:nil];
  NSString *expectedUserData = @"{\"ln\":\"e545c2c24e6463d7c4fe3829940627b226c0b9be7a8c7dbe964768da48f1ab9d\",\"ph\":\"a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3\",\"em\":\"84a47f61dd341ce731390149a904abcd58a6044263071abf44a475cf91563029\",\"fn\":\"0f1e18bb4143dc4be22e61ea4deb0491c2bf7018c6504ad631038aed5ca4a0ca\"}";
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

@end
