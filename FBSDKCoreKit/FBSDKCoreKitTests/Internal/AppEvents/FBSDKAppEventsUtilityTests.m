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

#import <UIKit/UIKit.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKSettings.h"

@interface FBSDKAppEventsUtilityTests : XCTestCase
{
  id _mockAppEventsUtility;
}

@end

@implementation FBSDKAppEventsUtilityTests

- (void)setUp
{
  [super setUp];
  _mockAppEventsUtility = OCMClassMock([FBSDKAppEventsUtility class]);
  [[[_mockAppEventsUtility stub] andReturn:[[NSUUID UUID] UUIDString]] advertiserID];
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testLogNotification
{
  [self expectationForNotification:FBSDKAppEventsLoggingResultNotification object:nil handler:nil];

  [FBSDKAppEventsUtility logAndNotify:@"test"];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];
}

- (void)testValidation
{
  XCTAssertFalse([FBSDKAppEventsUtility validateIdentifier:@"x-9adc++|!@#"]);
  XCTAssertTrue([FBSDKAppEventsUtility validateIdentifier:@"4simple id_-3"]);
  XCTAssertTrue([FBSDKAppEventsUtility validateIdentifier:@"_4simple id_-3"]);
  XCTAssertFalse([FBSDKAppEventsUtility validateIdentifier:@"-4simple id_-3"]);
}

- (void)testParamsDictionary
{
  NSDictionary *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                implicitEventsOnly:NO
                                                         shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNotNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);
}


- (void)testParamsDictionary2
{
  [FBSDKSettings setLimitEventAndDataUsage:NO];
  NSDictionary *dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event"
                                                                implicitEventsOnly:YES
                                                         shouldAccessAdvertisingID:YES];
  XCTAssertEqualObjects(@"event", dict[@"event"]);
  XCTAssertNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"1", dict[@"application_tracking_enabled"]);

  [FBSDKSettings setLimitEventAndDataUsage:YES];
  dict = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"event2"
                                                  implicitEventsOnly:NO
                                           shouldAccessAdvertisingID:NO];
  XCTAssertEqualObjects(@"event2", dict[@"event"]);
  XCTAssertNil(dict[@"advertiser_id"]);
  XCTAssertEqualObjects(@"0", dict[@"application_tracking_enabled"]);
  [FBSDKSettings setLimitEventAndDataUsage:NO];
}

- (void)testLogImplicitEventsExists
{
  Class FBSDKAppEventsClass = NSClassFromString(@"FBSDKAppEvents");
  SEL logEventSelector = NSSelectorFromString(@"logImplicitEvent:valueToSum:parameters:accessToken:");
  XCTAssertTrue([FBSDKAppEventsClass respondsToSelector:logEventSelector]);
}

@end
