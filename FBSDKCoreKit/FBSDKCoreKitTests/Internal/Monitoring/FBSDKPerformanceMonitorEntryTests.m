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
#import "FBSDKTestCoder.h"

@interface FBSDKPerformanceMonitorEntryTests : XCTestCase

@end

@implementation FBSDKPerformanceMonitorEntryTests {
  FBSDKPerformanceMonitorEntry *entry;
}

- (void)testCreatingEntryWithIdenticalStartAndEndTimes
{
  NSDate *startTime = [NSDate date];

  entry = [FBSDKPerformanceMonitorEntry entryWithName:@"Foo"
                                            startTime:startTime
                                              endTime:startTime];

  XCTAssertNil(entry, @"Should not create a performance entry if there is no time to measure");
}

- (void)testCreatingEntryWithInvalidRange
{
  entry = [FBSDKPerformanceMonitorEntry entryWithName:@"Foo"
                                            startTime:[NSDate date]
                                              endTime:[[NSDate date] dateByAddingTimeInterval:-10]];

  XCTAssertNil(entry, @"Should not create a performance entry that ends before it starts");
}

- (void)testCreatingEntryWithValidRange
{
  NSDate *startTime = [NSDate date];
  NSNumber *expectedStartTime = [NSNumber numberWithDouble:[startTime timeIntervalSince1970]];

  entry = [FBSDKPerformanceMonitorEntry entryWithName:@"Foo"
                                            startTime:startTime
                                              endTime:[startTime dateByAddingTimeInterval:1]];

  NSDictionary *actual = [entry dictionaryRepresentation];

  XCTAssertEqualObjects(actual[@"event_name"], @"Foo",
                        @"Should use the entry name as the event name");
  XCTAssertEqualObjects(actual[@"time_start"], expectedStartTime,
                        @"Should use unix time for the start time of the metric");
  XCTAssertEqualObjects(actual[@"time_spent"], @1,
                        @"Should capture the difference between the start and end-time of the metric");
}

- (void)testEntryName
{
  entry = [FBSDKPerformanceMonitorEntry entryWithName:@"Foo"
                                            startTime:[NSDate date]
                                              endTime:[[NSDate date] dateByAddingTimeInterval:1]];

  XCTAssertEqualObjects(entry.name, @"Foo",
                        @"The entry name should be easily accessible");
}

- (void)testEncodingEntry
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  NSDate *startTime = [NSDate date];

  entry = [FBSDKPerformanceMonitorEntry entryWithName:@"Foo"
                                            startTime:startTime
                                              endTime:[startTime dateByAddingTimeInterval:1]];

  [entry encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"event_name"], @"Foo",
                        @"Should use the entry name as the event name for encoding");
  XCTAssertEqualObjects(coder.encodedObject[@"time_start"], startTime,
                        @"Should use unix time for encoding the start time of the metric");
  XCTAssertEqualObjects(coder.encodedObject[@"time_end"], [startTime dateByAddingTimeInterval:1],
                        @"Should encode the difference between the start and end-time of the metric");
}

- (void)testDecodingEntry
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];

  entry = [[FBSDKPerformanceMonitorEntry alloc] initWithCoder:coder];

  XCTAssertEqualObjects(coder.decodedObject[@"event_name"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the event name key");
  XCTAssertEqualObjects(coder.decodedObject[@"time_start"], [NSDate class],
                        @"Initializing from a decoder should attempt to decode a number for the time start key");
  XCTAssertEqualObjects(coder.decodedObject[@"time_end"], [NSDate class],
                        @"Initializing from a decoder should attempt to decode a number for the time spent key");
}

@end
