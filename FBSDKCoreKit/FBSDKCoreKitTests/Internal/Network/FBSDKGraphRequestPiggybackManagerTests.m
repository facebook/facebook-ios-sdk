/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

@import TestTools;
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGraphRequestPiggybackManager+Internal.h"

@interface FBSDKGraphRequestPiggybackManagerTests : XCTestCase

@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) TestGraphRequestFactory *graphRequestFactory;
@property (nonatomic) TestServerConfigurationProvider *serverConfigurationProvider;

@end

@implementation FBSDKGraphRequestPiggybackManagerTests

- (void)setUp
{
  [super setUp];
  [self resetCaches];
  self.graphRequestFactory = [TestGraphRequestFactory new];
  self.serverConfigurationProvider = [[TestServerConfigurationProvider alloc] initWithConfiguration:ServerConfigurationFixtures.defaultConfig];
  self.settings = [TestSettings new];
  self.settings.appID = @"abc123";
  [FBSDKGraphRequestPiggybackManager configureWithTokenWallet:TestAccessTokenWallet.class
                                                     settings:self.settings
                                  serverConfigurationProvider:self.serverConfigurationProvider
                                          graphRequestFactory:self.graphRequestFactory];
}

- (void)tearDown
{
  [super tearDown];

  [self resetCaches];
}

- (void)resetCaches
{
  [TestAccessTokenWallet reset];
  [FBSDKGraphRequestPiggybackManager reset];
  [FBSDKSettings.sharedSettings reset];
}

// MARK: - Defaults

- (void)testDefaultTokenWallet
{
  [FBSDKGraphRequestPiggybackManager reset];
  XCTAssertNil(
    [FBSDKGraphRequestPiggybackManager tokenWallet],
    "Should not have an access token provider by default"
  );
}

- (void)testConfiguringWithTokenWallet
{
  XCTAssertEqualObjects(
    [FBSDKGraphRequestPiggybackManager tokenWallet],
    TestAccessTokenWallet.class,
    "Should be configurable with an access token provider"
  );
}

- (void)testRefreshThresholdInSeconds
{
  int oneDayInSeconds = 24 * 60 * 60;
  XCTAssertEqual(
    FBSDKGraphRequestPiggybackManager.tokenRefreshThresholdInSeconds,
    oneDayInSeconds,
    "There should be a well-known value for the token refresh threshold"
  );
}

- (void)testRefreshRetryInSeconds
{
  int oneHourInSeconds = 60 * 60;
  XCTAssertEqual(
    FBSDKGraphRequestPiggybackManager.tokenRefreshRetryInSeconds,
    oneHourInSeconds,
    "There should be a well-known value for the token refresh retry threshold"
  );
}

// MARK: - Request Eligibility

- (void)testSafeForAddingWithMatchingGraphVersionWithAttachment
{
  XCTAssertFalse(
    [FBSDKGraphRequestPiggybackManager isRequestSafeForPiggyback:SampleGraphRequests.withAttachment],
    "A request with an attachment is not considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithMatchingGraphVersionWithoutAttachment
{
  XCTAssertTrue(
    [FBSDKGraphRequestPiggybackManager isRequestSafeForPiggyback:SampleGraphRequests.valid],
    "A request without an attachment is considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithoutMatchingGraphVersionWithAttachment
{
  XCTAssertFalse(
    [FBSDKGraphRequestPiggybackManager isRequestSafeForPiggyback:SampleGraphRequests.withOutdatedVersionWithAttachment],
    "A request with an attachment and outdated version is not considered safe for piggybacking"
  );
}

- (void)testSafeForAddingWithoutMatchingGraphVersionWithoutAttachment
{
  XCTAssertFalse(
    [FBSDKGraphRequestPiggybackManager isRequestSafeForPiggyback:SampleGraphRequests.withOutdatedVersion],
    "A request with an outdated version is not considered safe for piggybacking"
  );
}

// MARK: - Adding Requests

- (void)testAddingRequestsWithoutAppID
{
  [self.settings setAppID:@""];

  [FBSDKGraphRequestPiggybackManager addPiggybackRequests:SampleGraphRequestConnections.empty];
  XCTAssertFalse(
    [TestAccessTokenWallet wasTokenRead],
    "Adding a request without an app identifier should attempt to refresh the access token"
  );
  XCTAssertFalse(self.serverConfigurationProvider.requestToLoadConfigurationCallWasCalled);
}

- (void)testAddingRequestsForConnectionWithSafeRequests
{
  [self.settings setAppID:@"abc123"];

  id<FBSDKGraphRequestConnecting> connection = [SampleGraphRequestConnections withRequests:@[SampleGraphRequests.valid]];
  TestAccessTokenWallet.currentAccessToken = self.twoDayOldToken;
  [FBSDKGraphRequestPiggybackManager addPiggybackRequests:connection];

  XCTAssertTrue(
    [TestAccessTokenWallet wasTokenRead],
    "Adding requests with an expired token should attempt to refresh the access token"
  );
  XCTAssertTrue(self.serverConfigurationProvider.requestToLoadConfigurationCallWasCalled);
}

- (void)testAddingRequestsForConnectionWithUnsafeRequests
{
  [self.settings setAppID:@"abc123"];
  id<FBSDKGraphRequestConnecting> connection = [SampleGraphRequestConnections withRequests:@[SampleGraphRequests.withAttachment]];

  TestAccessTokenWallet.currentAccessToken = self.twoDayOldToken;
  [FBSDKGraphRequestPiggybackManager addPiggybackRequests:connection];

  XCTAssertFalse(
    [TestAccessTokenWallet wasTokenRead],
    "Adding a request without an app identifier should attempt to refresh the access token"
  );
  XCTAssertFalse(self.serverConfigurationProvider.requestToLoadConfigurationCallWasCalled);
}

- (void)testAddingRequestsForConnectionWithSafeAndUnsafeRequests
{
  id<FBSDKGraphRequestConnecting> connection = [SampleGraphRequestConnections withRequests:@[
    SampleGraphRequests.valid,
    SampleGraphRequests.withAttachment
                                                ]];
  [FBSDKGraphRequestPiggybackManager addPiggybackRequests:connection];
  XCTAssertFalse(self.serverConfigurationProvider.requestToLoadConfigurationCallWasCalled);
}

// MARK: - Adding Token Extension Piggyback

- (void)testAddsTokenExtensionRequest
{
  self.settings.appID = @"abc123";
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];

  [FBSDKGraphRequestPiggybackManager addRefreshPiggyback:connection permissionHandler:nil];

  id<FBSDKGraphRequest> request = connection.capturedRequests.firstObject;
  XCTAssertNotNil(request, "Adding a refresh piggyback to a connection should add a request for refreshing the access token");

  XCTAssertEqualObjects(
    request.graphPath,
    @"oauth/access_token",
    "Should add a request with the correct graph path for refreshing a token"
  );
  NSDictionary<NSString *, id> *expectedParameters = @{
    @"grant_type" : @"fb_extend_sso_token",
    @"fields" : @"",
    @"client_id" : SampleAccessTokens.validToken.appID
  };

  XCTAssertTrue(
    [request.parameters isEqualToDictionary:expectedParameters],
    "Should add a request with the correct parameters for refreshing a token"
  );
}

- (void)testCompletingTokenExtensionRequestWithDefaultValues
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:nil];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedTokenString:SampleAccessTokens.validToken.tokenString];
}

- (void)testCompletingTokenExtensionRequestWithUpdatedEmptyTokenString
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"access_token" : @""}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedTokenString:@""];
}

- (void)testCompletingTokenExtensionRequestWithUpdatedWhitespaceOnlyTokenString
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"access_token" : @"    "}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedTokenString:@"    "];
}

- (void)testCompletingTokenExtensionRequestWithInvalidExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"expires_at" : @"0"}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken];

  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"expires_at" : @"-1000"}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken];
}

- (void)testCompletingTokenExtensionRequestWithUnreasonableValidExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"expires_at" : @100}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:100];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken expectedExpirationDate:expectedExpirationDate];
}

- (void)testCompletingTokenExtensionRequestWithReasonableValidExpirationDate
{
  NSTimeInterval oneWeek = 60 * 60 * 24 * 7;
  NSDate *oneWeekFromNow = [NSDate dateWithTimeIntervalSinceNow:oneWeek];
  // This is an acceptable value but really should not be.
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken
                                   results:@{@"expires_at" : @(oneWeekFromNow.timeIntervalSince1970)}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:oneWeekFromNow.timeIntervalSince1970];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
        expectedExpirationDate:expectedExpirationDate];
}

- (void)testCompletingTokenExtensionRequestWithInvalidDataExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{@"data_access_expiration_time" : @"0"}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken];

  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{@"data_access_expiration_time" : @"-1000"}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken];
}

- (void)testCompletingTokenExtensionRequestWithUnreasonableValidDataExpirationDate
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{@"data_access_expiration_time" : @100}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:100];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
    expectedDataExpirationDate:expectedExpirationDate];
}

- (void)testCompletingTokenExtensionRequestWithReasonableValidDataExpirationDate
{
  NSTimeInterval oneWeek = 60 * 60 * 24 * 7;
  NSDate *oneWeekFromNow = [NSDate dateWithTimeIntervalSinceNow:oneWeek];
  // This is an acceptable value but really should not be.
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{@"data_access_expiration_time" : @(oneWeekFromNow.timeIntervalSince1970)}];

  NSDate *expectedExpirationDate = [NSDate dateWithTimeIntervalSince1970:oneWeekFromNow.timeIntervalSince1970];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
    expectedDataExpirationDate:expectedExpirationDate];
}

- (void)testCompletingTokenExtensionRequestWithUpdatedEmptyGraphDomain
{
  [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{@"graph_domain" : @""}];

  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken];
}

- (void)testCompletingTokenExtensionRequestWithFuzzyValues
{
  for (int i = 0; i < 100; i++) {
    [self completeTokenRefreshForAccessToken:SampleAccessTokens.validToken results:@{
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
  [self.settings setAppID:@"abc123"];
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];

  [FBSDKGraphRequestPiggybackManager addRefreshPiggyback:connection permissionHandler:nil];

  TestGraphRequest *permissionRequest = self.graphRequestFactory.capturedRequests.lastObject;

  XCTAssertEqualObjects(
    permissionRequest.graphPath,
    @"me/permissions",
    "Should add a request with the correct graph path for refreshing permissions"
  );
  NSDictionary<NSString *, id> *expectedParameters = @{@"fields" : @""};
  XCTAssertTrue(
    [permissionRequest.parameters isEqualToDictionary:expectedParameters],
    "Should add a request with the correct parameters for refreshing permissions"
  );
}

- (void)testCompletingPermissionsRefreshRequestWithEmptyResults
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                  declinedPermissions:@[@"publish"]
                                                   expiredPermissions:@[@"friends"]];

  [self completePermissionsRefreshForAccessToken:token results:nil];

  // Refreshed token clears permissions when there is no error
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithEmptyResultsWithError
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                  declinedPermissions:@[@"publish"]
                                                   expiredPermissions:@[@"friends"]];

  [self completePermissionsRefreshForAccessToken:token results:nil error:[self createSampleError]];

  // Refreshed token uses permissions from current access token when there is an error on permissions refresh
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:token.permissions.allObjects
   expectedDeclinedPermissions:token.declinedPermissions.allObjects
    expectedExpiredPermissions:token.expiredPermissions.allObjects
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithNewGrantedPermissions
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                  declinedPermissions:@[@"publish"]
                                                   expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[@"foo"] declined:@[] expired:@[]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:@[@"foo"]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithNewDeclinedPermissions
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                  declinedPermissions:@[@"publish"]
                                                   expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[] declined:@[@"foo"] expired:@[]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:@[]
   expectedDeclinedPermissions:@[@"foo"]
    expectedExpiredPermissions:@[]
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithNewExpiredPermissions
{
  TestAccessTokenWallet.currentAccessToken = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                                   declinedPermissions:@[@"publish"]
                                                                    expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[] declined:@[] expired:@[@"foo"]];

  [self completePermissionsRefreshForAccessToken:SampleAccessTokens.validToken results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[@"foo"]
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithNewPermissions
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                  declinedPermissions:@[@"publish"]
                                                   expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                                            declined:@[@"bar"]
                                                                             expired:@[@"baz"]];

  [self completePermissionsRefreshForAccessToken:token results:results];

  // Refreshed token clears unspecified permissions when there are newly specified permissions in the response
  [self validateRefreshedToken:TestAccessTokenWallet.currentAccessToken
       withExpectedPermissions:@[@"foo"]
   expectedDeclinedPermissions:@[@"bar"]
    expectedExpiredPermissions:@[@"baz"]
  ];
}

- (void)testCompletingPermissionsRefreshRequestWithPermissionsHandlerWithoutError
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];
  TestAccessTokenWallet.currentAccessToken = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                                   declinedPermissions:@[@"publish"]
                                                                    expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                                            declined:@[@"bar"]
                                                                             expired:@[@"baz"]];

  [self completePermissionsRefreshForAccessToken:SampleAccessTokens.validToken
                                         results:results
                               permissionHandler:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
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
  TestAccessTokenWallet.currentAccessToken = [SampleAccessTokens createWithPermissions:@[@"email"]
                                                                   declinedPermissions:@[@"publish"]
                                                                    expiredPermissions:@[@"friends"]];

  NSDictionary<NSString *, id> *results = [SampleRawRemotePermissionList withGranted:@[@"foo"]
                                                                            declined:@[@"bar"]
                                                                             expired:@[@"baz"]];
  NSError *expectedError = [self createSampleError];

  [self completePermissionsRefreshForAccessToken:SampleAccessTokens.validToken
                                         results:results
                                           error:expectedError
                               permissionHandler:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
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
  // Shouldn't add the refresh if there's no access token
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

- (void)testRefreshIfStaleWithAccessTokenWithoutRefreshDate
{
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  // Should not add the refresh if the access token is missing a refresh date
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | true                           | true                           | true           |
- (void)testRefreshIfStaleWithOldRefreshWithOldTokenRefresh
{
  TestAccessTokenWallet.currentAccessToken = self.twoDayOldToken;
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantPast;
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];

  XCTAssertNotNil([self.graphRequestFactory capturedGraphPath]);
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | true                           | false                          | false          |
- (void)testRefreshIfStaleWithOldLastRefreshWithRecentTokenRefresh
{
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantPast;

  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | false                          | false                          | false          |
- (void)testRefreshIfStaleWithRecentLastRefreshWithRecentTokenRefresh
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantFuture;
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantFuture;
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

// | Last refresh try > an hour ago | Token refresh date > a day ago | should refresh |
// | false                          | true                           | false          |
- (void)testRefreshIfStaleWithRecentLastRefreshOldTokenRefresh
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`

  TestAccessTokenWallet.currentAccessToken = self.twoDayOldToken;
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantFuture;
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  XCTAssertNil([self.graphRequestFactory capturedGraphPath]);
}

- (void)testRefreshIfStaleSideEffects
{
  // Used for manipulating the initial value of the method scoped constant `lastRefreshTry`
  TestAccessTokenWallet.currentAccessToken = self.twoDayOldToken;
  FBSDKGraphRequestPiggybackManager.lastRefreshTry = NSDate.distantPast;
  [FBSDKGraphRequestPiggybackManager addRefreshPiggybackIfStale:SampleGraphRequestConnections.empty];
  XCTAssertNotNil([self.graphRequestFactory capturedGraphPath]);
}

// MARK: - Server Configuration Piggyback

- (void)testAddingServerConfigurationPiggybackWithoutAppID
{
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{ @"defaults" : @YES }];
  self.serverConfigurationProvider.stubbedServerConfiguration = config;
  self.settings.appID = nil;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    0,
    "Should not add a server configuration request without an app ID"
  );
}

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationExpiredCache
{
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : self.twoDaysAgo
                                      }];

  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  [self.settings setAppID:config.appID];

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];
  id<FBSDKGraphRequest> request = connection.capturedRequests.firstObject;
  FBSDKGraphRequest *expectedServerConfigurationRequest = [self.serverConfigurationProvider requestToLoadServerConfiguration:@""];

  [self validateServerConfigurationRequest:request
                                 isEqualTo:expectedServerConfigurationRequest];
}

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationNonExpiredCache
{
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : NSDate.date
                                      }];
  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    1,
    "Should add a server configuration request for a default config with a non-expired cache"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationExpiredCache
{
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES,
                                        @"timestamp" : self.twoDaysAgo
                                      }];
  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    1,
    "Should add a server configuration request for a default config with an expired cached"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationNonExpiredCache
{
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @NO,
                                        @"timestamp" : NSDate.date
                                      }];
  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    0,
    "Should not add a server configuration request for a custom configuration with a non-expired cache"
  );
}

- (void)testAddingServerConfigurationPiggybackWithCustomConfigurationMissingTimeout
{
  // Esoterica - the default timeout is nil in the default configuration
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @NO
                                      }];
  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    1,
    "Should add a server configuration request for a custom configuration with a missing cache timeout"
  );
}

- (void)testAddingServerConfigurationPiggybackWithDefaultConfigurationMissingTimeout
{
  // Esoterica - the default timeout is nil in the default configuration
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{
                                        @"defaults" : @YES
                                      }];
  FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:self.name];
  self.serverConfigurationProvider.stubbedRequestToLoadServerConfiguration = graphRequest;
  self.serverConfigurationProvider.stubbedServerConfiguration = config;

  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  [FBSDKGraphRequestPiggybackManager addServerConfigurationPiggyback:connection];

  XCTAssertEqual(
    connection.capturedRequests.count,
    1,
    "Should add a server configuration request for a default configuration with a missing cache timeout"
  );
}

// MARK: - Helpers

- (NSError *)createSampleError
{
  return [NSError errorWithDomain:@"foo" code:0 userInfo:@{}];
}

- (NSDate *)twoDaysAgo
{
  int twoDaysInSeconds = 60 * 60 * 48;
  return [NSDate dateWithTimeIntervalSinceNow:-twoDaysInSeconds];
}

- (FBSDKAccessToken *)twoDayOldToken
{
  return [SampleAccessTokens createWithRefreshDate:self.twoDaysAgo];
}

- (void)validateServerConfigurationRequest:(id<FBSDKGraphRequest>)request isEqualTo:(id<FBSDKGraphRequest>)expectedRequest
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
       withExpectedTokenString:SampleAccessTokens.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
{
  [self validateRefreshedToken:token
       withExpectedTokenString:expectedTokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
        expectedExpirationDate:(NSDate *)expectedExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessTokens.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:expectedExpirationDate
    expectedDataExpirationDate:NSDate.distantFuture
           expectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessTokens.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:expectedDataExpirationDate
           expectedPermissions:@[]
   expectedDeclinedPermissions:@[]
    expectedExpiredPermissions:@[]];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedPermissions:(NSArray *)expectedPermissions
   expectedDeclinedPermissions:(NSArray *)expectedDeclinedPermissions
    expectedExpiredPermissions:(NSArray *)expectedExpiredPermissions
{
  [self validateRefreshedToken:token
       withExpectedTokenString:SampleAccessTokens.validToken.tokenString
           expectedRefreshDate:[NSDate date]
        expectedExpirationDate:NSDate.distantFuture
    expectedDataExpirationDate:NSDate.distantFuture
           expectedPermissions:expectedPermissions
   expectedDeclinedPermissions:expectedDeclinedPermissions
    expectedExpiredPermissions:expectedExpiredPermissions];
}

- (void)validateRefreshedToken:(FBSDKAccessToken *)token
       withExpectedTokenString:(NSString *)expectedTokenString
           expectedRefreshDate:(NSDate *)expectedRefreshDate
        expectedExpirationDate:(NSDate *)expectedExpirationDate
    expectedDataExpirationDate:(NSDate *)expectedDataExpirationDate
           expectedPermissions:(NSArray *)expectedPermissions
   expectedDeclinedPermissions:(NSArray *)expectedDeclinedPermissions
    expectedExpiredPermissions:(NSArray *)expectedExpiredPermissions
{
  XCTAssertEqualObjects(token.tokenString, expectedTokenString, "A refreshed token should have the expected token string");
  XCTAssertEqualWithAccuracy(token.refreshDate.timeIntervalSince1970, expectedRefreshDate.timeIntervalSince1970, 1, "A refreshed token should have the expected refresh date");
  XCTAssertEqualObjects(token.expirationDate, expectedExpirationDate, "A refreshed token should have the expected expiration date");
  XCTAssertEqualObjects(token.dataAccessExpirationDate, expectedDataExpirationDate, "A refreshed token should have the expected data access expiration date");
  XCTAssertEqualObjects(token.permissions.allObjects, expectedPermissions, "A refreshed token should have the expected permissions");
  XCTAssertEqualObjects(token.declinedPermissions.allObjects, expectedDeclinedPermissions, "A refreshed token should have the expected declined permissions");
  XCTAssertEqualObjects(token.expiredPermissions.allObjects, expectedExpiredPermissions, "A refreshed token should have the expected expired permissions");
}

- (void)completeTokenRefreshForAccessToken:(FBSDKAccessToken *)token results:(NSDictionary<NSString *, id> *)results
{
  [self.settings setAppID:token.appID];
  TestAccessTokenWallet.currentAccessToken = token;
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];

  [FBSDKGraphRequestPiggybackManager addRefreshPiggyback:connection permissionHandler:nil];

  // The callback that sets the token ignores the first call to it
  // because it's waiting on the permissions call to complete first.
  // We can get around this for now by invoking the handler twice.
  connection.capturedCompletions.firstObject(connection, results, nil);
  connection.capturedCompletions.lastObject(connection, results, nil);
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary<NSString *, id> *)results
{
  [self completePermissionsRefreshForAccessToken:token results:results error:nil];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary<NSString *, id> *)results
                                           error:(NSError *)error
{
  [self completePermissionsRefreshForAccessToken:token results:results error:error permissionHandler:nil];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary<NSString *, id> *)results
                               permissionHandler:(FBSDKGraphRequestCompletion)permissionHandler
{
  [self completePermissionsRefreshForAccessToken:token results:results error:nil permissionHandler:permissionHandler];
}

- (void)completePermissionsRefreshForAccessToken:(FBSDKAccessToken *)token
                                         results:(NSDictionary<NSString *, id> *)results
                                           error:(NSError *)error
                               permissionHandler:(FBSDKGraphRequestCompletion)permissionHandler
{
  [self.settings setAppID:token.appID];
  TestAccessTokenWallet.currentAccessToken = token;
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];

  [FBSDKGraphRequestPiggybackManager addRefreshPiggyback:connection permissionHandler:permissionHandler];
  FBSDKGraphRequestCompletion tokenRefreshRequestCompletion = connection.capturedCompletions.firstObject;
  FBSDKGraphRequestCompletion permissionsRequestCompletion = connection.capturedCompletions.lastObject;

  tokenRefreshRequestCompletion(connection, nil, nil);
  if (permissionsRequestCompletion) {
    permissionsRequestCompletion(connection, results, error);
  }
}

@end
