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
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKTestCase.h"

@interface FBSDKAccessToken (Testing)
+ (void)resetCurrentAccessTokenCache;
@end

@interface FBSDKGraphRequestPiggybackManager (Testing)

+ (int)_tokenRefreshThresholdInSeconds;
+ (int)_tokenRefreshRetryInSeconds;
+ (BOOL)_safeForPiggyback:(FBSDKGraphRequest *)request;
+ (void)_setLastRefreshTry:(NSDate *)date;

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
  [self stubFetchingCachedServerConfiguration];

  FBSDKGraphRequestConnection *connection = [SampleGraphRequestConnection withRequests:@[SampleGraphRequest.valid]];

  [Manager addPiggybackRequests:connection];

  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:connection]));
  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:connection]));
}

- (void)testAddingRequestsForConnectionWithUnsafeRequests
{
  [self stubAppID:@"abc123"];
  [self stubFetchingCachedServerConfiguration];
  FBSDKGraphRequestConnection *connection = [SampleGraphRequestConnection withRequests:@[SampleGraphRequest.withAttachment]];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggybackIfStale:connection]));
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addServerConfigurationPiggyback:connection]));

  [Manager addPiggybackRequests:connection];
}

- (void)testAddingRequestsForConnectionWithSafeAndUnsafeRequests
{
  [self stubAppID:@"abc123"];
  [self stubFetchingCachedServerConfiguration];
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
  for (int i = 0; i < 100; i++) {
    [self completeTokenRefreshForAccessToken:SampleAccessToken.validToken results:@{
       @"access_token" : [Fuzzer random],
       @"expires_at" : [Fuzzer random],
       @"data_access_expiration_time" : [Fuzzer random],
       @"graph_domain" : [Fuzzer random]
     }];
  }
}

// MARK: - Adding Permissions Refresh Piggyback

- (void)testAddsPermissionsRefreshRequest
{
  [self stubAppID:@"abc123"];
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  [Manager addRefreshPiggyback:connection permissionHandler:nil];

  FBSDKGraphRequestMetadata *metadata = connection.requests.lastObject;
  FBSDKGraphRequest *request = metadata.request;
  XCTAssertNotNil(request, "Adding a refresh piggyback to a connection should add a request for refreshing permissions");

  XCTAssertEqualObjects(
    request.graphPath,
    @"me/permissions",
    "Should add a request with the correct graph path for refreshing permissions"
  );

  NSDictionary *expectedParameters = @{@"fields" : @""};
  XCTAssertTrue(
    [request.parameters isEqualToDictionary:expectedParameters],
    "Should add a request with the correct parameters for refreshing permissions"
  );
  XCTAssertEqual(
    request.flags,
    FBSDKGraphRequestFlagDisableErrorRecovery,
    "Should add a request with the correct flags for refreshing permissions"
  );
}

- (void)testCompletingPermissionsRefreshRequestWithEmptyResults
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];

  [self completePermissionsRefreshForAccessToken:token results:nil];

  // Refreshed token clears permissions when there is no error
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:@[]
         expectedDeclinedPermissions:@[]
          expectedExpiredPermissions:@[]
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithEmptyResultsWithError
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];

  [self completePermissionsRefreshForAccessToken:token results:nil error:[NSError new]];

  // Refreshed token uses permissions from current access token when there is an error on permissions refresh
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:token.permissions.allObjects
         expectedDeclinedPermissions:token.declinedPermissions.allObjects
          expectedExpiredPermissions:token.expiredPermissions.allObjects
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithNewGrantedPermissions
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[@"foo"] declined:@[] expired:@[]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:@[@"foo"]
         expectedDeclinedPermissions:@[]
          expectedExpiredPermissions:@[]
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithNewDeclinedPermissions
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[] declined:@[@"foo"] expired:@[]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:@[]
         expectedDeclinedPermissions:@[@"foo"]
          expectedExpiredPermissions:@[]
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithNewExpiredPermissions
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];
  [self stubCurrentAccessTokenWith:token];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[] declined:@[] expired:@[@"foo"]];

  [self completePermissionsRefreshForAccessToken:SampleAccessToken.validToken results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:@[]
         expectedDeclinedPermissions:@[]
          expectedExpiredPermissions:@[@"foo"]
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithNewPermissions
{
  FBSDKAccessToken *token = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                     declinedPermissions:@[@"publish"]
                                                      expiredPermissions:@[@"friends"]];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                            declined:@[@"bar"]
                                                             expired:@[@"baz"]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  OCMVerify(
    ClassMethod(
      [self.accessTokenClassMock setCurrentAccessToken:[OCMArg checkWithBlock:^BOOL (id obj) {
        [self validateRefreshedToken:obj
             withExpectedPermissions:@[@"foo"]
         expectedDeclinedPermissions:@[@"bar"]
          expectedExpiredPermissions:@[@"baz"]
        ];
        return true;
      }]]
    )
  );
}

- (void)testCompletingPermissionsRefreshRequestWithPermissionsHandlerWithoutError
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];
  FBSDKAccessToken *expectedToken = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                             declinedPermissions:@[@"publish"]
                                                              expiredPermissions:@[@"friends"]];
  [self stubCurrentAccessTokenWith:expectedToken];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                            declined:@[@"bar"]
                                                             expired:@[@"baz"]];

  [self completePermissionsRefreshForAccessToken:SampleAccessToken.validToken
                                         results:results
                               permissionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                 XCTAssertEqualObjects(
                                   result,
                                   results,
                                   "Should pass the raw results to the provided permissions handler"
                                 );
                                 XCTAssertNil(
                                   error,
                                   "Should invoke the permissions handler regardless of error state"
                                 );
                                 [expectation fulfill];
                               }];

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testCompletingPermissionsRefreshRequestWithPermissionsHandlerWithError
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];
  FBSDKAccessToken *expectedToken = [SampleAccessToken validTokenWithPermissions:@[@"email"]
                                                             declinedPermissions:@[@"publish"]
                                                              expiredPermissions:@[@"friends"]];
  [self stubCurrentAccessTokenWith:expectedToken];

  NSDictionary *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                            declined:@[@"bar"]
                                                             expired:@[@"baz"]];
  NSError *expectedError = [NSError new];

  [self completePermissionsRefreshForAccessToken:SampleAccessToken.validToken
                                         results:results
                                           error:expectedError
                               permissionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                 XCTAssertEqualObjects(
                                   result,
                                   results,
                                   "Should pass the raw results to the provided permissions handler"
                                 );
                                 XCTAssertEqualObjects(
                                   error,
                                   expectedError,
                                   "Should pass the error through to the permissions handler"
                                 );
                                 [expectation fulfill];
                               }];

  [self waitForExpectations:@[expectation] timeout:1];
}

// MARK: - Refreshing if Stale

- (void)testRefreshIfStaleWithoutAccessToken
{
  [self stubCurrentAccessTokenWith:nil];

  // Shouldn't add the refresh if there's no access token
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];
}

- (void)testRefreshIfStaleWithAccessTokenWithoutRefreshDate
{
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];

  // Should not add the refresh if the access token is missing a refresh date
  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | true                           | true                           | true           |
- (void)testRefreshIfStaleWithOldRefreshWithOldTokenRefresh
{
  [self stubGraphRequestPiggybackManagerLastRefreshTryWith:NSDate.distantPast];
  [self stubCurrentAccessTokenWith:self.twoDayOldToken];

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];

  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | true                           | false                          | false          |
- (void)testRefreshIfStaleWithOldLastRefreshWithRecentTokenRefresh
{
  [self stubGraphRequestPiggybackManagerLastRefreshTryWith:NSDate.distantPast];
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | false                          | false                          | false          |
- (void)testRefreshIfStaleWithRecentLastRefreshWithRecentTokenRefresh
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
  [self stubGraphRequestPiggybackManagerLastRefreshTryWith:NSDate.distantFuture];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | false                          | true                           | false          |
- (void)testRefreshIfStaleWithRecentLastRefreshOldTokenRefresh
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
  [self stubGraphRequestPiggybackManagerLastRefreshTryWith:NSDate.distantFuture];
  [self stubCurrentAccessTokenWith:self.twoDayOldToken];

  OCMReject(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];
}

- (void)testRefreshIfStaleSideEffects
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
  [self stubGraphRequestPiggybackManagerLastRefreshTryWith:NSDate.distantPast];
  [self stubCurrentAccessTokenWith:self.twoDayOldToken];

  [Manager addRefreshPiggybackIfStale:SampleGraphRequestConnection.empty];

  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock addRefreshPiggyback:OCMArg.any permissionHandler:NULL]));
  // Should update last refresh try
  OCMVerify(ClassMethod([self.graphRequestPiggybackManagerMock _setLastRefreshTry:OCMArg.any]));
}

// MARK: - Server Configuration Piggyback

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationExpiredCache
{
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : self.twoDaysAgo
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];
  [self stubAppID:config.appID];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];
  FBSDKGraphRequestMetadata *requestMetadata = connection.requests.firstObject;
  FBSDKGraphRequest *expectedServerConfigurationRequest = [FBSDKServerConfigurationManager requestToLoadServerConfiguration:nil];

  [self validateServerConfigurationRequest:requestMetadata.request isEqualTo:expectedServerConfigurationRequest];
}

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationNonExpiredCache
{
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : NSDate.date
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.requests.count,
    1,
    "Should add a server configuration request for a default config with a non-expired cache"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationExpiredCache
{
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : self.twoDaysAgo
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.requests.count,
    1,
    "Should add a server configuration request for a default config with an expired cached"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationNonExpiredCache
{
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @NO,
                                        @"timestamp" : NSDate.date
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.requests.count,
    0,
    "Should not add a server configuration request for a custom configuration with a non-expired cache"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationMissingTimeout
{
  // Esoterica - the default timeout is nil in the default configuration
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @NO
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.requests.count,
    1,
    "Should add a server configuration request for a custom configuration with a missing cache timeout"
  );
}

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationMissingTimeout
{
  // Esoterica - the default timeout is nil in the default configuration
  FBSDKServerConfiguration *config = [FBSDKServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES
                                      }];
  [self stubCachedServerConfigurationWithServerConfiguration:config];

  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [Manager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.requests.count,
    1,
    "Should add a server configuration request for a default configuration with a missing cache timeout"
  );
}

// MARK: - Helpers

- (NSDate *)twoDaysAgo
{
  int twoDaysInSeconds = 60 * 60 * 48;
  return [NSDate dateWithTimeIntervalSinceNow:-twoDaysInSeconds];
}

- (FBSDKAccessToken *)twoDayOldToken
{
  return [SampleAccessToken validWithRefreshDate:self.twoDaysAgo];
}

- (void)validateServerConfigurationRequest:(FBSDKGraphRequest *)request isEqualTo:(FBSDKGraphRequest *)expectedRequest
{
  XCTAssertNotNil(request, "Adding a server configuration piggyback should add a request to fetch the server configuration");

  XCTAssertEqualObjects(
    request.graphPath,
    expectedRequest.graphPath,
    "Should add a request with the expected graph path for fetching a server configuration"
  );
  XCTAssertEqualObjects(
    request.parameters,
    expectedRequest.parameters,
    "Should add a request with the correct parameters for fetching a server configuration"
  );
  XCTAssertEqual(
    request.flags,
    expectedRequest.flags,
    "Should add a request with the correct flags for fetching a server configuration"
  );
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain
           expectedPermissions:[NSArray array]
   expectedDeclinedPermissions:[NSArray array]
    expectedExpiredPermissions:[NSArray array]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
{
  [self validateRefreshedToken:token
       withExpectedTokenString:expectedTokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain
           expectedPermissions:[NSArray array]
   expectedDeclinedPermissions:[NSArray array]
    expectedExpiredPermissions:[NSArray array]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
        expectedExpirationDate:(NSDate *)expectedExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:expectedExpirationDate
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain
           expectedPermissions:[NSArray array]
   expectedDeclinedPermissions:[NSArray array]
    expectedExpiredPermissions:[NSArray array]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:expectedDataExpirationDate
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain
           expectedPermissions:[NSArray array]
   expectedDeclinedPermissions:[NSArray array]
    expectedExpiredPermissions:[NSArray array]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedGraphDomain:(NSString *)expectedGraphDomain
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:expectedGraphDomain
           expectedPermissions:[NSArray array]
   expectedDeclinedPermissions:[NSArray array]
    expectedExpiredPermissions:[NSArray array]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedPermissions:(NSArray *)expectedPermissions
   expectedDeclinedPermissions:(NSArray *)expectedDeclinedPermissions
    expectedExpiredPermissions:(NSArray *)expectedExpiredPermissions
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessToken.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedGraphDomain:SampleAccessToken.validToken.graphDomain
           expectedPermissions:expectedPermissions
   expectedDeclinedPermissions:expectedDeclinedPermissions
    expectedExpiredPermissions:expectedExpiredPermissions];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
           expectedRefreshDate:(NSDate *)expectedRefreshDate
        expectedExpirationDate:(NSDate *)expectedExpirationDate
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
           expectedGraphDomain:(NSString *)expectedGraphDomain
           expectedPermissions:(NSArray *)expectedPermissions
   expectedDeclinedPermissions:(NSArray *)expectedDeclinedPermissions
    expectedExpiredPermissions:(NSArray *)expectedExpiredPermissions
{
  XCTAssertEqualObjects(token.tokenString, expectedTokenString, "A refreshed token should have the expected token string");
  XCTAssertEqualWithAccuracy(token.refreshDate.timeIntervalSince1970, expectedRefreshDate.timeIntervalSince1970, 1, "A refreshed token should have the expected refresh date");
  XCTAssertEqualObjects(token.expirationDate, expectedExpirationDate, "A refreshed token should have the expected expiration date");
  XCTAssertEqualObjects(token.dataAccessExpirationDate, expectedDataExpirationDate, "A refreshed token should have the expected data access expiration date");
  XCTAssertEqualObjects(token.graphDomain, expectedGraphDomain, "A refreshed token should have the expected graph domain");
  XCTAssertEqualObjects(token.permissions.allObjects, expectedPermissions, "A refreshed token should have the expected permissions");
  XCTAssertEqualObjects(token.declinedPermissions.allObjects, expectedDeclinedPermissions, "A refreshed token should have the expected declined permissions");
  XCTAssertEqualObjects(token.expiredPermissions.allObjects, expectedExpiredPermissions, "A refreshed token should have the expected expired permissions");
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

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary *)results
{
  [self completePermissionsRefreshForAccessToken:token results:results error:nil];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary *)results
                                           error:(NSError *)error
{
  [self completePermissionsRefreshForAccessToken:token results:results error:error permissionHandler:nil];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary *)results
                               permissionHandler:(FBSDKGraphRequestBlock)permissionHandler
{
  [self completePermissionsRefreshForAccessToken:token results:results error:nil permissionHandler:permissionHandler];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary *)results
                                           error:(NSError *)error
                               permissionHandler:(FBSDKGraphRequestBlock)permissionHandler
{
  [self stubAppID:token.appID];
  [self stubCurrentAccessTokenWith:token];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  [Manager addRefreshPiggyback:connection permissionHandler:permissionHandler];

  FBSDKGraphRequestMetadata *tokenRefreshRequestMetadata = connection.requests.firstObject;
  FBSDKGraphRequestMetadata *permissionsRequestMetadata = connection.requests.lastObject;

  tokenRefreshRequestMetadata.completionHandler(connection, nil, nil);
  permissionsRequestMetadata.completionHandler(connection, results, error);
}

@end
