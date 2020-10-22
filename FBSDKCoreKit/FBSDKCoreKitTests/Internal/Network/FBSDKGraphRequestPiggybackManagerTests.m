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

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKTestCase.h"

@interface FBSDKGraphRequestPiggybackManager (Testing)

+ (int)_tokenRefreshThresholdInSeconds;
+ (int)_tokenRefreshRetryInSeconds;
+ (BOOL)_safeForPiggyback:(FBSDKGraphRequest *)request;

@end

@interface FBSDKGraphRequestPiggybackManagerTests : FBSDKTestCase

@end

@implementation FBSDKGraphRequestPiggybackManagerTests

typedef FBSDKGraphRequestPiggybackManager Manager;

- (void)testRefreshThresholdInSeconds
{
  int oneDayInSeconds = 24 * 60 * 60;
  XCTAssertEqual(
    [Manager _tokenRefreshThresholdInSeconds],
    oneDayInSeconds,
    "There should be a well-known value for the token refresh threshold"
  );
}

- (void)testRefreshRetryInSeconds
{
  int oneHourInSeconds = 60 * 60;
  XCTAssertEqual(
    [Manager _tokenRefreshRetryInSeconds],
    oneHourInSeconds,
    "There should be a well-known value for the token refresh retry threshold"
  );
}

- (void)testAddingRequestsWithoutAppID
{
  [self stubAppID:@""];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:OCMArg.any]));
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:OCMArg.any]));

  [Manager addPiggybackRequests:SampleGraphRequestConnection.empty];
}

- (void)testSafeForAddingWithMatchingGraphVersionWithAttachment
{
  XCTAssertFalse(
    [Manager _safeForPiggyback:SampleGraphRequest.withAttachment],
    "A request with an attachment is not considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithMatchingGraphVersionWithoutAttachment
{
  XCTAssertTrue(
    [Manager _safeForPiggyback:SampleGraphRequest.valid],
    "A request without an attachment is considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithoutMatchingGraphVersionWithAttachment
{
  XCTAssertFalse(
    [Manager _safeForPiggyback:SampleGraphRequest.withOutdatedVersionWithAttachment],
    "A request with an attachment and outdated version is not considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithoutMatchingGraphVersionWithoutAttachment
{
  XCTAssertFalse(
    [Manager _safeForPiggyback:SampleGraphRequest.withOutdatedVersion],
    "A request with an outdated version is not considered safe for piggybacking"
  );
}

- (void)testAddingRequestsForConnectionWithSafeRequests
{
  [self stubAppID:@"abc123"];
  FBSDKGraphRequestConnection *connection = [SampleGraphRequestConnection withRequests:@[SampleGraphRequest.valid]];

  [Manager addPiggybackRequests:connection];

  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:connection]));
  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:connection]));
}

- (void)testAddingRequestsForConnectionWithUnsafeRequests
{
  [self stubAppID:@"abc123"];
  FBSDKGraphRequestConnection *connection = [SampleGraphRequestConnection withRequests:@[SampleGraphRequest.withAttachment]];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:connection]));
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:connection]));

  [Manager addPiggybackRequests:connection];
}

- (void)testAddingRequestsForConnectionWithSafeAndUnsafeRequests
{
  [self stubAppID:@"abc123"];
  FBSDKGraphRequestConnection *connection = [SampleGraphRequestConnection withRequests:@[
    SampleGraphRequest.valid,
    SampleGraphRequest.withAttachment
                                             ]];

  // No requests are piggybacked if any are invalid
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:connection]));
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:connection]));

  [Manager addPiggybackRequests:connection];
}

@end
