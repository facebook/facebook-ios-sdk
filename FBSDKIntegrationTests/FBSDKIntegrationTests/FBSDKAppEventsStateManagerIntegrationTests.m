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

#import "FBSDKCoreKit+Internal.h"

@interface FBSDKAppEventsStateManagerIntegrationTests : XCTestCase

@end

@implementation FBSDKAppEventsStateManagerIntegrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPersistence {
  [FBSDKAppEventsStateManager clearPersistedAppEventsStates];
  XCTAssertEqual(0, [FBSDKAppEventsStateManager retrievePersistedAppEventsStates].count);

  FBSDKAppEventsState *eventState = [[FBSDKAppEventsState alloc] initWithToken:@"token" appID:@"appid"];
  [eventState addEvent:@{ @"event" : @1 } isImplicit:NO];
  [FBSDKAppEventsStateManager persistAppEventsData:eventState];

  FBSDKAppEventsState *eventState2 = [[FBSDKAppEventsState alloc] initWithToken:@"token2" appID:@"appid"];
  [eventState2 addEvent:@{ @"event2" : @2 } isImplicit:YES];
  [FBSDKAppEventsStateManager persistAppEventsData:eventState2];

  NSArray *savedArray = [FBSDKAppEventsStateManager retrievePersistedAppEventsStates];
  XCTAssertEqual(2, savedArray.count);
  XCTAssertFalse([savedArray[0] areAllEventsImplicit]);
  XCTAssertTrue([savedArray[1] areAllEventsImplicit]);

  NSString *zero = [savedArray[0] JSONStringForEvents:YES];
  NSString *one = [savedArray[1] JSONStringForEvents:YES];
  XCTAssertNotEqualObjects(zero, one);
  XCTAssertFalse([savedArray[0] areAllEventsImplicit]);
  XCTAssertTrue([savedArray[1] areAllEventsImplicit]);

  XCTAssertEqual(0, [FBSDKAppEventsStateManager retrievePersistedAppEventsStates].count);
}

@end
