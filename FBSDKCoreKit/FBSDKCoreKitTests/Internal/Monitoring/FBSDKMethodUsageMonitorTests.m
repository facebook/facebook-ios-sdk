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
#import "FBSDKTestCase.h"

@interface FBSDKMonitor (Testing)

@property (class, nonatomic, readonly) NSMutableArray<id<FBSDKMonitorEntry>> *entries;

+ (void)disable;
+ (void)flush;

@end

@interface FBSDKMethodUsageMonitorTests : FBSDKTestCase
@end

@implementation FBSDKMethodUsageMonitorTests

- (void)setUp
{
  [super setUp];

  // This should be removed when these tests are updated to check the actual requests that are created
  [self stubAllocatingGraphRequestConnection];

  [FBSDKMonitor enable];
}

- (void)tearDown
{
  [FBSDKMonitor flush];
  [FBSDKMonitor disable];

  [super tearDown];
}

- (void)testRecordingMethodUsage
{
  NSString *expectedName = [NSString stringWithFormat:@"%@::%@", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];

  [FBSDKMethodUsageMonitor recordMethod:_cmd inClass:self.class];

  FBSDKMethodUsageMonitorEntry *entry = (FBSDKMethodUsageMonitorEntry *) FBSDKMonitor.entries.firstObject;

  XCTAssertEqualObjects(
    entry.dictionaryRepresentation[@"event_name"],
    expectedName,
    @"Entry should contain the captured method name"
  );
}

@end
