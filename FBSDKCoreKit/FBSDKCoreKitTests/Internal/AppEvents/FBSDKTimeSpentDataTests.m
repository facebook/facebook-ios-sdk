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

#import "FBSDKTimeSpentData.h"

static NSString *const _mockApplication = @"mockApplication";

@interface FBSDKTimeSpentData ()

+ (NSString *)getSourceApplication;
+ (void)resetSourceApplication;
- (NSDictionary<NSString *, id> *)appEventsParametersForDeactivate;

@end

@interface FBSDKTimeSpentDataTests : XCTestCase

@end

@implementation FBSDKTimeSpentDataTests

- (void)testSetSourceApplication
{
  [FBSDKTimeSpentData setSourceApplication:_mockApplication isFromAppLink:YES];

  NSString *sourceApplication = [FBSDKTimeSpentData getSourceApplication];
  XCTAssertEqualObjects(sourceApplication, @"AppLink(mockApplication)");

  [FBSDKTimeSpentData resetSourceApplication];
  sourceApplication = [FBSDKTimeSpentData getSourceApplication];
  XCTAssertEqualObjects(sourceApplication, @"Unclassified");
}

- (void)testAppEventsParametersForDeactivate
{
  [FBSDKTimeSpentData setSourceApplication:_mockApplication isFromAppLink:YES];
  FBSDKTimeSpentData *timeSpentData = [[FBSDKTimeSpentData alloc] init];
  NSDictionary<NSString *, NSString *> *params = [timeSpentData appEventsParametersForDeactivate];
  XCTAssertNotNil(params[@"_session_id"]);
  XCTAssertNotNil(params[@"fb_mobile_app_interruptions"]);
  XCTAssertNotNil(params[@"fb_mobile_launch_source"]);
  XCTAssertNotNil(params[@"fb_mobile_time_between_sessions"]);
}

@end
