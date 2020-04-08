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

@interface FBSDKMethodUsageMonitorEntryTests : XCTestCase
@end

@implementation FBSDKMethodUsageMonitorEntryTests {
  FBSDKMethodUsageMonitorEntry *entry;
}

- (void)testCreatingEntryWithMethodName
{
  NSString *expectedName = [NSString stringWithFormat:@"%@::%@", self.class, NSStringFromSelector(_cmd)];

  entry = [FBSDKMethodUsageMonitorEntry entryFromClass:self.class withMethod:_cmd];

  XCTAssertEqualObjects(entry.name, expectedName,
                        @"Should use the name of the class and method as the entry name");
}

- (void)testEncodingEntryWithMethodName
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];

  entry = [FBSDKMethodUsageMonitorEntry entryFromClass:self.class withMethod:_cmd];

  [entry encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"event_name"], NSStringFromSelector(_cmd),
                        @"Should use the name of the method as the event name for encoding");
  XCTAssertEqualObjects(coder.encodedObject[@"method_usage_class"], NSStringFromClass(self.class),
                        @"Should use the name of the class as the class name for encoding");
}

- (void)testDecodingEntryWithMethodName
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];

  entry = [[FBSDKMethodUsageMonitorEntry alloc] initWithCoder:coder];

  XCTAssertEqualObjects(coder.decodedObject[@"event_name"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the event name key");
  XCTAssertEqualObjects(coder.decodedObject[@"method_usage_class"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the defining class key");
}

@end
