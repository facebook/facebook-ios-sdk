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

@end
