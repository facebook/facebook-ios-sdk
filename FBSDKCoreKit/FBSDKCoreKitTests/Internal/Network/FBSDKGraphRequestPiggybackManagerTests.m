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
#import "SampleAccessToken.h"

@interface FBSDKAccessToken (Testing)
+ (void)resetCurrentAccessTokenCache;
@end

@interface FBSDKGraphRequestPiggybackManager (Testing)

+ (int)_tokenRefreshThresholdInSeconds;
+ (int)_tokenRefreshRetryInSeconds;
+ (BOOL)_safeForPiggyback:(FBSDKGraphRequest *)request;

@end

@interface FBSDKGraphRequestPiggybackManagerTests : FBSDKTestCase

@end

@implementation FBSDKGraphRequestPiggybackManagerTests

typedef FBSDKGraphRequestPiggybackManager Manager;

- (void)setUp
{
  [super setUp];

  [self resetCaches];
}

- (void)tearDown
{
  [super tearDown];

  [self resetCaches];
}

- (void)resetCaches
{
  [FBSDKAccessToken resetCurrentAccessTokenCache];
}

// MARK: - Defaults

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

// MARK: - Request Eligibility

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

// MARK: - Adding Requests

- (void)testAddingRequestsWithoutAppID
{
  [self stubAppID:@""];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:OCMArg.any]));
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:OCMArg.any]));

  [Manager addPiggybackRequests:SampleGraphRequestConnection.empty];
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

// MARK: - Adding Token Extension Piggyback

- (void)testAddsTokenExtensionRequest
{
  [self stubAppID:@"abc123"];
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  [Manager addRefreshPiggyback:connection permissionHandler:nil];

  FBSDKGraphRequestMetadata *metadata = connection.requests.firstObject;
  FBSDKGraphRequest *request = metadata.request;
  XCTAssertNotNil(request, "Adding a refresh piggyback to a connection should add a request for refreshing the access token");

  XCTAssertEqualObjects(
    request.graphPath,
    @"oauth/access_token",
    "Should add a request with the correct graph path for refreshing a token"
  );
  NSDictionary *expectedParameters = @{
    @"grant_type" : @"fb_extend_sso_token",
    @"fields" : @"",
    @"client_id" : SampleAccessToken.validToken.appID
  };
  XCTAssertTrue(
    [request.parameters isEqualToDictionary:expectedParameters],
    "Should add a request with the correct parameters for refreshing a token"
  );
  XCTAssertEqual(
    request.flags,
    FBSDKGraphRequestFlagDisableErrorRecovery,
    "Should add a request with the correct flags"
  );
}

- (void)testCompletingTokenExtensionRequestWithDefaultValues
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:nil];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedTokenString:SampleAccessToken.validToken.tokenString];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUpdatedEmptyTokenString
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"access_token" : @""}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj withExpectedTokenString:@""];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUpdatedWhitespaceOnlyTokenString
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"access_token" : @"    "}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj withExpectedTokenString:@"    "];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithInvalidExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"expires_at" : @"0"}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj];
        return true;
      }]]
    )
  );

  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"expires_at" : @"-1000"}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUnreasonableValidExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"expires_at" : @100}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:100];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj expectedExpirationDate:expectedExpirationDate];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithReasonableValidExpirationDate
{
  NSTimeInterval oneWeek = 60 * 60 * 24 * 7;
  NSDate *oneWeekFromNow = [NSDate dateWithTimeIntervalSinceNow:oneWeek];
  // This is an acceptable value but really should not be.
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken
                                   results:@{@"expires_at" : @(oneWeekFromNow.timeIntervalSince1970)}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:oneWeekFromNow.timeIntervalSince1970];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj expectedExpirationDate:expectedExpirationDate];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithInvalidDataExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"data_access_expiration_time" : @"0"}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj];
        return true;
      }]]
    )
  );

  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"data_access_expiration_time" : @"-1000"}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUnreasonableValidDataExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"data_access_expiration_time" : @100}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:100];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj expectedDataExpirationDate:expectedExpirationDate];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithReasonableValidDataExpirationDate
{
  NSTimeInterval oneWeek = 60 * 60 * 24 * 7;
  NSDate *oneWeekFromNow = [NSDate dateWithTimeIntervalSinceNow:oneWeek];
  // This is an acceptable value but really should not be.
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"data_access_expiration_time" : @(oneWeekFromNow.timeIntervalSince1970)}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:oneWeekFromNow.timeIntervalSince1970];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj expectedDataExpirationDate:expectedExpirationDate];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUpdatedEmptyGraphDomain
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"graph_domain" : @""}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj withExpectedGraphDomain:@""];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithUpdatedWhitespaceOnlyGraphDomain
{
  [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{@"graph_domain" : @"    "}];

  // Check that an access token with the expected field values was set
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj withExpectedGraphDomain:@"    "];
        return true;
      }]]
    )
  );
}

- (void)testCompletingTokenExtensionRequestWithFuzzyValues
{
  for (int i = 0; i < 1000; i++) {
    [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{
       @"access_token" : [Fuzzer random],
       @"expires_at" : [Fuzzer random],
       @"data_access_expiration_time" : [Fuzzer random],
       @"graph_domain" : [Fuzzer random]
     }];
  }
}

// MARK: - Helpers

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
{
  [self validateRefreshedToken:token
       withExpectedTokenString:expectedTokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
        expectedExpirationDate:(NSDate *)expectedExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:expectedExpirationDate
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:expectedDataExpirationDate
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedGraphDomain:(NSString *)expectedGraphDomain
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:expectedGraphDomain];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
           expectedRefreshDate:(NSDate *)expectedRefreshDate
        expectedExpirationDate:(NSDate *)expectedExpirationDate
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
           expectedGraphDomain:(NSString *)expectedGraphDomain
{
  XCTAssertEqualObjects(token.tokenString, expectedTokenString, "A refreshed token should have the expected token string");
  XCTAssertEqualWithAccuracy(token.refreshDate.timeIntervalSince1970, expectedRefreshDate.timeIntervalSince1970, 1, "A refreshed token should have the expected refresh date");
  XCTAssertEqualObjects(token.expirationDate, expectedExpirationDate, "A refreshed token should have the expected expiration date");
  XCTAssertEqualObjects(token.dataAccessExpirationDate, expectedDataExpirationDate, "A refreshed token should have the expected data access expiration date");
  XCTAssertEqualObjects(token.graphDomain, expectedGraphDomain, "A refreshed token should have the expected graph domain");
}

- (void)completeTokenRefreshForAccessToken:(FBSDKAccessToken *)token results:(NSDictionary *)results
{
  [self stubAppID:token.appID];
  [self stubCurrentAccessTokenWith:token];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  [Manager addRefreshPiggyback:connection permissionHandler:nil];

  FBSDKGraphRequestMetadata *metadata = connection.requests.firstObject;

  // The callback that sets the token ignores the first call to it
  // because it's waiting on the permissions call to complete first.
  // We can get around this for now by invoking the handler twice.
  metadata.completionHandler(connection, @{}, nil);
  metadata.completionHandler(connection, results, nil);
}

@end
