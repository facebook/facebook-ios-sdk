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
#import "TestCoder.h"

@interface FBSDKMethodUsageMonitorEntryTests : XCTestCase
@end

@implementation FBSDKMethodUsageMonitorEntryTests {
  FBSDKMethodUsageMonitorEntry *entry;
}

- (void)setUp
{
  [super setUp];

  [FBSDKSettings setAppID:@"abc123"];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings setAppID:nil];
}

- (void)testCreatingEntryWithMethodName
{
  entry = [FBSDKMethodUsageMonitorEntry entryWithMethod:@selector(viewDidLoad)];

  NSDictionary *actual = [entry dictionaryRepresentation];

  XCTAssertEqualObjects([actual objectForKey:@"appID"], @"abc123",
                        @"Should include the superclass' dictionary representation");
  XCTAssertEqualObjects([actual objectForKey:@"event_name"], @"viewDidLoad",
                        @"Should use the name of the method as the event name");
}

- (void)testEncodingEntryWithMethodName
{
  TestCoder *coder = [TestCoder new];

  entry = [FBSDKMethodUsageMonitorEntry entryWithMethod:@selector(viewDidLoad)];

  [entry encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"appID"], @"abc123",
                        @"Should include the superclass' encoding");
  XCTAssertEqualObjects(coder.encodedObject[@"event_name"], @"viewDidLoad",
                        @"Should use the name of the method as the event name for encoding");
}

- (void)testDecodingEntryWithMethodName
{
  TestCoder *coder = [TestCoder new];

  entry = [[FBSDKMethodUsageMonitorEntry alloc] initWithCoder:coder];

  XCTAssertEqualObjects(coder.decodedObject[@"appID"], [NSString class],
                        @"Initializing from a decoder should include the superclass' decoding");
  XCTAssertEqualObjects(coder.decodedObject[@"event_name"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the event name key");
}

@end
