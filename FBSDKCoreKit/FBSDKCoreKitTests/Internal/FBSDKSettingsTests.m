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

#import "FBSDKCoreKit.h"
#import "FBSDKSettings.h"
#import "FBSDKSettings+Internal.h"

@interface FBSDKSettings ()
+ (NSString *)userAgentSuffix;
+ (void)setUserAgentSuffix:(NSString *)suffix;
@end

@interface FBSDKSettingsTests : XCTestCase
{
  id _mockSDKSettings;
}
@end

@implementation FBSDKSettingsTests

- (void)testSetGraphErrorRecoveryEnabled
{
  [FBSDKSettings setGraphErrorRecoveryEnabled:YES];
  XCTAssertTrue([FBSDKSettings isGraphErrorRecoveryEnabled]);

  [FBSDKSettings setGraphErrorRecoveryEnabled:NO];
  XCTAssertFalse([FBSDKSettings isGraphErrorRecoveryEnabled]);
}

- (void)testSetCodelessDebugLogEnabled
{
  [FBSDKSettings setCodelessDebugLogEnabled:YES];
  XCTAssertTrue([FBSDKSettings isCodelessDebugLogEnabled]);

  [FBSDKSettings setCodelessDebugLogEnabled:NO];
  XCTAssertFalse([FBSDKSettings isCodelessDebugLogEnabled]);
}

- (void)testSetAutoLogAppEventsEnabled
{
  [FBSDKSettings setAutoLogAppEventsEnabled:YES];
  XCTAssertTrue([FBSDKSettings isAutoLogAppEventsEnabled]);

  [FBSDKSettings setAutoLogAppEventsEnabled:NO];
  XCTAssertFalse([FBSDKSettings isAutoLogAppEventsEnabled]);
}

- (void)testSetAdvertiserIDCollectionEnabled
{
  [FBSDKSettings setAdvertiserIDCollectionEnabled:YES];
  XCTAssertTrue([FBSDKSettings isAdvertiserIDCollectionEnabled]);

  [FBSDKSettings setAdvertiserIDCollectionEnabled:NO];
  XCTAssertFalse([FBSDKSettings isAdvertiserIDCollectionEnabled]);
}

- (void)testSetLimitEventAndDataUsage
{
  [FBSDKSettings setLimitEventAndDataUsage:YES];
  XCTAssertTrue([FBSDKSettings shouldLimitEventAndDataUsage]);

  [FBSDKSettings setLimitEventAndDataUsage:NO];
  XCTAssertFalse([FBSDKSettings shouldLimitEventAndDataUsage]);

  //test when NSUserDefaults does not contain FBSDKSettingsLimitEventAndDataUsage
  id mockUserDefaults = [OCMockObject niceMockForClass:[NSUserDefaults class]];
  OCMStub([[mockUserDefaults standardUserDefaults] objectForKey:[OCMArg any]]).andReturn(nil);
  [FBSDKSettings setLimitEventAndDataUsage:YES];
  XCTAssertFalse([FBSDKSettings shouldLimitEventAndDataUsage]);
}

- (void)testSetDataProecssingOptions
{
  [FBSDKSettings setDataProcessingOptions:@[@"LDU"] country:1 state:1000];
  NSDictionary<NSString *, id> *dataProcessingOptions = [FBSDKSettings dataProcessingOptions];
  NSSet *actualSet = [NSSet setWithArray:dataProcessingOptions[DATA_PROCESSING_OPTIONS]];
  NSSet *expectedSet = [NSSet setWithArray:@[@"LDU"]];
  XCTAssertTrue([expectedSet isEqualToSet:actualSet]);
}

- (void)testLoggingBehaviors
{
  NSSet<FBSDKLoggingBehavior> *mockLoggingBehaviors =
  [NSSet setWithObjects:FBSDKLoggingBehaviorAppEvents, FBSDKLoggingBehaviorNetworkRequests, nil];

  [FBSDKSettings setLoggingBehaviors:mockLoggingBehaviors];
  XCTAssertEqualObjects(mockLoggingBehaviors, [FBSDKSettings loggingBehaviors]);

  //test enable logging behavior
  [FBSDKSettings enableLoggingBehavior: FBSDKLoggingBehaviorInformational];
  XCTAssertTrue([[FBSDKSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorInformational]);

  //test disable logging behavior
  [FBSDKSettings disableLoggingBehavior: FBSDKLoggingBehaviorInformational];
  XCTAssertFalse([[FBSDKSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorInformational]);
}

#pragma mark - test for internal functions

- (void)testSetUserAgentSuffix
{
  NSString *mockUserAgentSuffix = @"mockUserAgentSuffix";
  [FBSDKSettings setUserAgentSuffix:mockUserAgentSuffix];
  XCTAssertEqualObjects(mockUserAgentSuffix, [FBSDKSettings userAgentSuffix]);
}

- (void)testSetGraphAPIVersion
{
  NSString *mockGraphAPIVersion = @"mockGraphAPIVersion";
  [FBSDKSettings setGraphAPIVersion:mockGraphAPIVersion];
  XCTAssertEqualObjects(mockGraphAPIVersion, [FBSDKSettings graphAPIVersion]);

  [FBSDKSettings setGraphAPIVersion:nil];
  XCTAssertEqualObjects(FBSDK_TARGET_PLATFORM_VERSION, [FBSDKSettings graphAPIVersion]);
}

- (void)testIsDataProcessingRestricted
{
  [FBSDKSettings setDataProcessingOptions:@[@"LDU"]];
  XCTAssertTrue([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:@[]];
  XCTAssertFalse([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:@[@"ldu"]];
  XCTAssertTrue([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:nil];
  XCTAssertFalse([FBSDKSettings isDataProcessingRestricted]);
}

@end
