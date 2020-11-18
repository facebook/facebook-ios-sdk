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

#import <sys/utsname.h>

#import "FBSDKCoreKit+Internal.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitorNetworkerTests : XCTestCase

@property (nonatomic) id<FBSDKMonitorEntry> entry;

@end

@implementation FBSDKMonitorNetworkerTests
{
  id graphRequestMock;
}

- (void)setUp
{
  [super setUp];

  graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  [FBSDKSettings setAppID:@"abc123"];
  self.entry = [TestMonitorEntry testEntry];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings setAppID:nil];
  [graphRequestMock stopMocking];
}

- (void)testSendingEntryWithMissingAppID
{
  [FBSDKSettings setAppID:nil];
  self.entry = [TestMonitorEntry testEntry];

  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);

  OCMReject(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:[OCMArg any]
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  );

  [FBSDKMonitorNetworker sendEntries:@[self.entry]];
}

- (void)testSendingEntriesCreatesGraphRequest
{
  id<FBSDKMonitorEntry> entry2 = [TestMonitorEntry testEntry];
  NSArray<id<FBSDKMonitorEntry>> *entries = @[self.entry, entry2];

  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);

  BOOL (^verifyPath)(id) = ^BOOL (id path) {
    XCTAssertEqualObjects(
      path,
      @"/monitorings",
      @"Graph path should be a known string well known"
    );
    return YES;
  };

  BOOL (^verifyParameters)(id) = ^BOOL (id parameters) {
    [self assertAppIdInParameters:parameters];
    [self assertDeviceModelInParameters:parameters];
    [self assertOSVersionInParameters:parameters];
    [self assertBundleIdInParameters:parameters];
    [self assertParameters:parameters includeEntries:entries];
    return YES;
  };

  BOOL (^verifyHTTPMethod)(id) = ^BOOL (id method) {
    XCTAssertEqualObjects(
      method,
      FBSDKHTTPMethodPOST,
      @"Networker should use POST when sending entries"
    );
    return YES;
  };

  [FBSDKMonitorNetworker sendEntries:entries];

  OCMVerifyAll(
    [graphRequestMock initWithGraphPath:[OCMArg checkWithBlock:verifyPath]
                             parameters:[OCMArg checkWithBlock:verifyParameters]
                            tokenString:[OCMArg isNil]
                             HTTPMethod:[OCMArg checkWithBlock:verifyHTTPMethod]
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  );
}

- (void)testSendingEntriesStartsGraphRequest
{
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:[OCMArg any]
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  [FBSDKMonitorNetworker sendEntries:@[[TestMonitorEntry testEntry]]];

  OCMVerify([graphRequestMock startWithCompletionHandler:nil]);
}

// MARK: - Helpers

- (void)assertBundleIdInParameters:(NSDictionary *)parameters
{
  XCTAssertEqualObjects(
    parameters[@"unique_application_identifier"],
    NSBundle.mainBundle.bundleIdentifier,
    @"A monitor POST body should include the main bundle identifier."
  );
}

- (void)assertOSVersionInParameters:(NSDictionary *)parameters
{
  XCTAssertEqualObjects(
    parameters[@"device_os_version"],
    UIDevice.currentDevice.systemVersion,
    @"A monitor POST body should include the current device's os version."
  );
}

- (void)assertAppIdInParameters:(NSDictionary *)parameters
{
  XCTAssertEqualObjects(
    parameters[@"id"],
    [FBSDKSettings appID],
    @"A monitor POST body should include the current facebook app identifier."
  );
}

- (void)assertDeviceModelInParameters:(NSDictionary *)parameters
{
  XCTAssertEqualObjects(
    parameters[@"device_model"],
    [self.class deviceModel],
    @"A monitor POST body should include the current device model."
  );
}

- (void)assertParameters:(NSDictionary *)parameters includeEntries:(NSArray<id<FBSDKMonitorEntry>> *)entries
{
  // Networker should send the array of provided entries as a UTF8 encoded JSON string keyed under 'monitorings'
  NSString *capturedEntriesJSON = parameters[@"monitorings"];
  NSArray *capturedEntryDictionaries = [FBSDKBasicUtility objectForJSONString:capturedEntriesJSON error:nil];

  for (int i = 0; i < capturedEntryDictionaries.count; i++) {
    XCTAssertTrue([capturedEntryDictionaries[i] isEqualToDictionary:entries[i].dictionaryRepresentation]);
  }
}

+ (NSString *)deviceModel
{
  struct utsname systemInfo;
  uname(&systemInfo);

  return [NSString stringWithCString:systemInfo.machine
                            encoding:NSUTF8StringEncoding];
}

@end
