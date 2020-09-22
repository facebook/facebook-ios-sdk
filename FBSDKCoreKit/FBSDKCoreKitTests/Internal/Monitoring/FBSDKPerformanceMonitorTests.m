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

#import "FBSDKCoreKit+Internal.h"

@interface FBSDKMonitor (Testing)

@property (class, nonatomic, readonly) NSMutableArray<id<FBSDKMonitorEntry>> *entries;

+ (void)disable;
+ (void)flush;

@end

@interface FBSDKPerformanceMonitorTests : XCTestCase
@end

@implementation FBSDKPerformanceMonitorTests

- (void)setUp
{
  [super setUp];

  [FBSDKMonitor enable];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKMonitor flush];
  [FBSDKMonitor disable];
}

- (void)testRecordingPerformance
{
  // Start one second ago
  NSDate *date = [[NSDate date] dateByAddingTimeInterval:-1];
  NSNumber *expectedStartTime = [NSNumber numberWithDouble:[date timeIntervalSince1970]];

  NSNumberFormatter *formatter = [NSNumberFormatter new];
  formatter.roundingMode = NSNumberFormatterRoundDown;

  [FBSDKPerformanceMonitor record:@"Foo" startTime:date];

  FBSDKPerformanceMonitorEntry *entry = (FBSDKPerformanceMonitorEntry *) FBSDKMonitor.entries.firstObject;

  XCTAssertEqualObjects(
    entry.dictionaryRepresentation[@"event_name"],
    @"Foo",
    @"Entry should contain the event name"
  );
  XCTAssertEqualObjects(
    entry.dictionaryRepresentation[@"time_start"],
    expectedStartTime,
    @"Entry should contain the start time of the metric"
  );
  XCTAssertEqualWithAccuracy(
    [entry.dictionaryRepresentation[@"time_spent"] doubleValue],
    [@1 doubleValue],
    0.1,
    @"Entry should contain the difference between the start and end-time of the metric"
  );
}

- (void)testRecordingPerformanceWithInvalidInterval
{
  // Start in future
  NSDate *date = [NSDate distantFuture];

  [FBSDKPerformanceMonitor record:@"Foo" startTime:date];

  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Should not add invalid entries to the monitor"
  );
}

@end
