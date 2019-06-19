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

#import "FBSDKAppEventsState.h"
#import "FBSDKBasicUtility+Internal.h"

#define FBSDK_APPEVENTSSTATE_MAX_EVENTS 1000

@interface FBSDKAppEventsStateTests : XCTestCase
@end

@implementation FBSDKAppEventsStateTests

- (void)testAppEventsStateAddSimple
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  XCTAssertEqual(0, target.events.count);
  XCTAssertEqual(0, target.numSkipped);
  XCTAssertTrue([target areAllEventsImplicit]);

  [target addEvent:@{ @"event1" : @1 } isImplicit:YES];
  XCTAssertEqual(1, target.events.count);
  XCTAssertEqual(0, target.numSkipped);
  XCTAssertTrue([target areAllEventsImplicit]);

  [target addEvent:@{ @"event2" : @2 } isImplicit:NO];
  XCTAssertEqual(2, target.events.count);
  XCTAssertEqual(0, target.numSkipped);
  XCTAssertFalse([target areAllEventsImplicit]);

  NSString *expectedJSON = @"[{\"event1\":1},{\"event2\":2}]";
  XCTAssertEqualObjects(expectedJSON, [target JSONStringForEvents:YES]);

  FBSDKAppEventsState *copy = [target copy];
  [copy addEvent:@{ @"copy1" : @3 } isImplicit:YES];
  XCTAssertEqual(2, target.events.count);
  XCTAssertEqual(3, copy.events.count);

  [target addEventsFromAppEventState:copy];
  XCTAssertEqual(5, target.events.count);
  XCTAssertFalse([target areAllEventsImplicit]);
}

- (void)testisCompatibleWithAppEventsState1
{
  FBSDKAppEventsState *eventState = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  FBSDKAppEventsState *target1 = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  XCTAssertTrue([eventState isCompatibleWithAppEventsState:target1]);

  FBSDKAppEventsState *target2 = [[FBSDKAppEventsState alloc] initWithToken:@"token1" appID:@"app"];
  XCTAssertFalse([eventState isCompatibleWithAppEventsState:target2]);
}

- (void)testIsCompatibleWithAppEventsState2
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];

  FBSDKAppEventsState *testTarget1 = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:nil];
  FBSDKAppEventsState *testTarget2 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:@"app"];
  FBSDKAppEventsState *testTarget3 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:nil];
  FBSDKAppEventsState *testTarget4 = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];

  XCTAssertFalse([target isCompatibleWithAppEventsState: testTarget1]);
  XCTAssertFalse([target isCompatibleWithAppEventsState: testTarget2]);
  XCTAssertFalse([target isCompatibleWithAppEventsState: testTarget3]);
  XCTAssertTrue([target isCompatibleWithAppEventsState: testTarget4]);
}

- (void)testAddEvent
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  for(size_t i = 0; i < FBSDK_APPEVENTSSTATE_MAX_EVENTS; ++i) {
    [target addEvent:@{} isImplicit:NO];
  }
  [target addEvent:@{} isImplicit:NO];
  XCTAssertEqual(1, target.numSkipped);
}

- (void)testAddEventsFromAppEventState
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  for(size_t i = 0; i < FBSDK_APPEVENTSSTATE_MAX_EVENTS * 2; ++i) {
    [target addEvent:@{} isImplicit:NO];
  }
  FBSDKAppEventsState *event = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  [event addEvent:@{} isImplicit:NO];
  [target addEventsFromAppEventState:event];

  XCTAssertEqual(FBSDK_APPEVENTSSTATE_MAX_EVENTS + 1, target.numSkipped);
  XCTAssertEqual(FBSDK_APPEVENTSSTATE_MAX_EVENTS, target.events.count);
}

- (void)testExtractReceiptData
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  [target addEvent:@{@"receipt_data":@"some_data"} isImplicit:NO];
  NSString* extractString = [target extractReceiptData];
  XCTAssertTrue([extractString isEqualToString: @"receipt_1::some_data;;;"]);
}

- (void)testJSONStringForEvents
{
  FBSDKAppEventsState *target = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"app"];
  NSDictionary<NSString*, NSString*>* someEvent = @{  @"receipt_data":@"some_receipt_data",@"data":@"mock_data"};
  [target addEvent:someEvent isImplicit:YES];
  NSString* jsonString = [target JSONStringForEvents:YES];
  NSString* expectedString = [FBSDKBasicUtility JSONStringForObject:@[@{@"data":@"mock_data"}] error:nil invalidObjectHandler:nil];
  XCTAssertTrue([jsonString isEqualToString:expectedString]);
}

@end
