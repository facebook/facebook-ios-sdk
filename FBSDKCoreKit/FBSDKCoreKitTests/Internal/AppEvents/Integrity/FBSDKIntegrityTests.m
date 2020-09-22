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

#import "FBSDKIntegrityManager.h"
#import "FBSDKModelManager.h"

@interface FBSDKIntegrityTests : XCTestCase
{
  id _mockModelManager;
}

@end

@implementation FBSDKIntegrityTests

- (void)setUp
{
  [super setUp];
  [FBSDKIntegrityManager enable];
  _mockModelManager = OCMClassMock([FBSDKModelManager class]);
}

- (void)testProcessParameters1
{
  // Parameter contains restrictive data
  NSDictionary *parameters = @{
    @"address" : @"2301 N Highland Ave, Los Angeles, CA 90068", // address
    @"period_starts" : @"2020-02-03", // health
  };

  OCMStub([_mockModelManager processIntegrity:[OCMArg any]]).andReturn(YES);
  NSDictionary *processed = [FBSDKIntegrityManager processParameters:parameters];

  XCTAssertNil(processed[@"address"]);
  XCTAssertNil(processed[@"period_starts"]);
  XCTAssertNotNil(processed[@"_onDeviceParams"]);
  XCTAssertTrue([processed[@"_onDeviceParams"] containsString:@"address"]);
  XCTAssertTrue([processed[@"_onDeviceParams"] containsString:@"period_starts"]);
}

- (void)testProcessParameters2
{
  // Parameter does not contain any restrictive data
  NSDictionary *parameters = @{
    @"_valueToSum" : @1,
    @"_session_id" : @"12345",
  };
  OCMStub([_mockModelManager processIntegrity:[OCMArg any]]).andReturn(NO);
  NSDictionary *processed = [FBSDKIntegrityManager processParameters:parameters];

  XCTAssertNotNil(processed[@"_valueToSum"]);
  XCTAssertNotNil(processed[@"_session_id"]);
  XCTAssertNil(processed[@"_onDeviceParams"]);
}

@end
