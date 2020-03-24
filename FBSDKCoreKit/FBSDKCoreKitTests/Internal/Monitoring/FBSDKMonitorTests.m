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

#import "FBSDKCoreKit+Internal.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitor (Testing)

@property (class, nonatomic) Class graphRequestClass;

+ (NSMutableArray<id<FBSDKMonitorEntry>> *)entries;
+ (void)disable;
+ (void)flush;

@end

@interface FBSDKMonitorTests : XCTestCase

@property (nonatomic) id<FBSDKMonitorEntry> entry;

@end

@implementation FBSDKMonitorTests {
  int flushLimit;
}

- (void)setUp
{
  [super setUp];

  flushLimit = 100;
  [FBSDKSettings setAppID:@"fbabc123"];
  self.entry = [TestMonitorEntry testEntry];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKMonitor flush];
  [FBSDKMonitor disable];
}

- (void)testRecordingWhenDisabled {
  [FBSDKMonitor record:self.entry];

  XCTAssertEqual(FBSDKMonitor.entries.count, 0,
                 @"Should not record entries before monitor is enabled");
}

- (void)testEnabling
{
  [FBSDKMonitor enable];

  [FBSDKMonitor record:self.entry];

  XCTAssertEqualObjects(FBSDKMonitor.entries, @[self.entry],
                        @"Should record entries when monitor is enabled");
}

- (void)testFlushing
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [FBSDKMonitor flush];

  XCTAssertEqual(FBSDKMonitor.entries.count, 0,
                 @"Flushing should clear all entries");
}

- (void)testFlushingInvokesNetworker
{
  id<FBSDKMonitorEntry> entry2 = [TestMonitorEntry testEntryWithName:@"entry2"];
  NSArray<id<FBSDKMonitorEntry>> *expectedEntries = @[self.entry, entry2];

  id networkerMock = OCMStrictClassMock([FBSDKMonitorNetworker class]);

  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];
  [FBSDKMonitor record:entry2];
  [FBSDKMonitor flush];

  OCMVerify(ClassMethod([networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL(id obj) {
    XCTAssertEqualObjects(obj, expectedEntries);
    return YES;
  }]]));

  [networkerMock stopMocking];
}

- (void)testRecordingAtOneBelowFlushLimit
{
  [FBSDKMonitor enable];
  NSMutableArray<id<FBSDKMonitorEntry>> *expectedEntries = [NSMutableArray array];

  // Should not invoke networker if the threshold is not met
  id networkerMock = OCMStrictClassMock([FBSDKMonitorNetworker class]);
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  for (int i = 0; i < flushLimit - 1; i++) {
    [expectedEntries addObject:[TestMonitorEntry testEntry]];
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(expectedEntries.count, flushLimit - 1,
                 @"Sanity check failed");

  [networkerMock stopMocking];
}

- (void)testRecordingAtFlushLimit
{
  [FBSDKMonitor enable];
  NSMutableArray<id<FBSDKMonitorEntry>> *expectedEntries = [NSMutableArray array];

  id networkerMock = OCMStrictClassMock([FBSDKMonitorNetworker class]);

  for (int i = 0; i < flushLimit; i++) {
    [expectedEntries addObject:[TestMonitorEntry testEntry]];
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(expectedEntries.count, flushLimit,
                 @"Sanity check failed");

  OCMVerify(ClassMethod([networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL(id obj) {
    XCTAssertEqual([obj count], expectedEntries.count,
                   @"Should send the correct number of entries when the flush limit is reached");
    return YES;
  }]]));

  [networkerMock stopMocking];
}

- (void)testRecordingPastFlushLimit
{
  [FBSDKMonitor enable];

  for (int i = 0; i < flushLimit; i++) {
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(FBSDKMonitor.entries.count, 0,
                 @"Should flush entries after reaching threshold");

  [FBSDKMonitor record:self.entry];

  XCTAssertEqual(FBSDKMonitor.entries.count, 1,
                 @"Should continue to record entries after surpassing the flush limit");
}

@end
