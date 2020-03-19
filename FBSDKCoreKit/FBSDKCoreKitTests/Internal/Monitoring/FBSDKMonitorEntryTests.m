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

#import <sys/utsname.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "FBSDKCoreKit+Internal.h"
#import "TestCoder.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitorEntryTests : XCTestCase

@property (nonatomic) FBSDKMonitorEntry *entry;

@end

@implementation FBSDKMonitorEntryTests

- (void)setUp
{
  [super setUp];

  [FBSDKSettings setAppID:@"abc123"];
  self.entry = [TestMonitorEntry testEntry];
}

- (void)tearDown
{
  [FBSDKSettings setAppID:nil];
}

- (void)testDirectInitialization
{
  XCTAssertNil([[FBSDKMonitorEntry alloc] init],
               @"Should not be able to directly initialize the base class for monitor entries");
}

- (void)testDictionaryRepresentation {
  UIDevice *deviceStub = OCMPartialMock(UIDevice.currentDevice);
  OCMStub(deviceStub.systemVersion).andReturn(@"foo");

  self.entry = [TestMonitorEntry testEntry];
  NSDictionary *dict = [self.entry dictionaryRepresentation];

  XCTAssertEqualObjects([dict objectForKey:@"appID"], @"abc123",
                        @"A monitor entry's appID should be gleaned from settings");
  XCTAssertEqualObjects([dict objectForKey:@"device_os_version"], @"foo",
                        @"An entry should store the current device's os version");
  XCTAssertEqualObjects([dict objectForKey:@"device_model"], [FBSDKMonitorEntryTests deviceModel],
                        @"An entry's device model should be available");
}

- (void)testCodability
{
  self.entry = [TestMonitorEntry testEntry];
  TestCoder *coder = [TestCoder new];

  [self.entry encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"appID"], @"abc123",
                        @"A monitor entry's appID should be gleaned from settings");
  XCTAssertEqualObjects(coder.encodedObject[@"device_os_version"], UIDevice.currentDevice.systemVersion,
                        @"An entry should store the current device's os version");
  XCTAssertEqualObjects(coder.encodedObject[@"device_model"], [FBSDKMonitorEntryTests deviceModel],
                        @"An entry's device model should be available");
}

- (void)testDecodability
{
  TestCoder *coder = [TestCoder new];
  self.entry = [[FBSDKMonitorEntry alloc] initWithCoder:coder];

  XCTAssertEqualObjects(coder.decodedObject[@"appID"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the app id key");
  XCTAssertEqualObjects(coder.decodedObject[@"device_os_version"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the system version key");
  XCTAssertEqualObjects(coder.decodedObject[@"device_model"], [NSString class],
                        @"Initializing from a decoder should attempt to decode a String for the device model key");
}

- (void)testInitWithArchiver
{
  FBSDKMonitorEntry *entry = [TestMonitorEntry testEntry];

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:entry];

  // Making sure the appID is actually unarchived and not computed from current settings
  [FBSDKSettings setAppID:@"other"];

  FBSDKMonitorEntry *unarchivedEntry = [NSKeyedUnarchiver unarchiveObjectWithData:data];

  XCTAssertTrue([unarchivedEntry.dictionaryRepresentation isEqualToDictionary:entry.dictionaryRepresentation],
                @"Archiving and unarchiving an entry should not change its properties");
}

// MARK: Helpers

+ (NSString *)deviceModel
{
  struct utsname systemInfo;
  uname(&systemInfo);

  return [NSString stringWithCString:systemInfo.machine
                            encoding:NSUTF8StringEncoding];
}

@end
