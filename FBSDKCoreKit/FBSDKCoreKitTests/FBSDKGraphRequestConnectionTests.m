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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKTestCase.h"
#import "FBSDKURLSessionProxyFactory.h"

typedef NS_ENUM(NSUInteger, FBSDKGraphRequestConnectionState) {
  kStateCreated,
  kStateSerialized,
  kStateStarted,
  kStateCompleted,
  kStateCancelled,
};

@interface FBSDKGraphRequestConnection (Testing)

@property (nonatomic, strong) id<FBSDKURLSessionProxying> session;
@property (nonatomic, strong) id<FBSDKURLSessionProxyProviding> sessionProxyFactory;
@property (nonatomic, assign) FBSDKGraphRequestConnectionState state;

+ (BOOL)canMakeRequests;
+ (void)resetCanMakeRequests;
+ (void)resetDefaultConnectionTimeout;
- (instancetype)initWithURLSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)sessionProxyFactory;
- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout;
- (NSString *)accessTokenWithRequest:(FBSDKGraphRequest *)request;
- (NSString *)_overrideVersionPart;

@end

@interface FBSDKGraphRequestConnectionTests : FBSDKTestCase <FBSDKGraphRequestConnectionDelegate>

@property (nonatomic, strong) FakeURLSessionProxy *session;
@property (nonatomic, strong) FakeURLSessionProxyFactory *sessionFactory;
@property (nonatomic, strong) FBSDKGraphRequestConnection *connection;

@property (nonatomic, copy) void (^requestConnectionStartingCallback)(FBSDKGraphRequestConnection *connection);
@property (nonatomic, copy) void (^requestConnectionCallback)(FBSDKGraphRequestConnection *connection, NSError *error);
@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                             claims:(nullable FBSDKAuthenticationTokenClaims *)claims
                        graphDomain:(NSString *)graphDomain;

@end

@implementation FBSDKGraphRequestConnectionTests

- (void)setUp
{
  [super setUp];

  [self stubAppID:self.appID];
  [self stubCheckingFeatures];
  [self stubLoadingGateKeepers];
  [self stubAddingServerConfigurationPiggyback];

  [FBSDKGraphRequestConnection setCanMakeRequests];

  _session = [FakeURLSessionProxy new];
  _sessionFactory = [FakeURLSessionProxyFactory createWith:_session];
  _connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:_sessionFactory];
}

- (void)tearDown
{
  [FBSDKGraphRequestConnection resetDefaultConnectionTimeout];

  _session = nil;
  _sessionFactory = nil;
  _connection = nil;

  [FBSDKGraphRequestConnection resetCanMakeRequests];

  [super tearDown];
}

// MARK: - FBSDKGraphRequestConnectionDelegate

- (void)requestConnection:(FBSDKGraphRequestConnection *)connection didFailWithError:(NSError *)error
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, error);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionDidFinishLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, nil);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionWillBeginLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionStartingCallback) {
    self.requestConnectionStartingCallback(connection);
    self.requestConnectionStartingCallback = nil;
  }
}

// MARK: - Dependencies

- (void)testCreatingWithDefaultUrlSessionProxyFactory
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *sessionProvider = (NSObject *)connection.sessionProxyFactory;
  XCTAssertEqualObjects(
    sessionProvider.class,
    FBSDKURLSessionProxyFactory.class,
    "A graph request connection should have the correct concrete session provider by default"
  );
}

- (void)testCreatingWithCustomUrlSessionProxyFactory
{
  NSObject *sessionProvider = (NSObject *)self.connection.sessionProxyFactory;

  XCTAssertEqualObjects(
    sessionProvider.class,
    FakeURLSessionProxyFactory.class,
    "A graph request connection should persist the session provider it was created with"
  );
}

- (void)testDerivingSessionFromSessionProvider
{
  NSObject *session = (NSObject *)self.connection.session;

  XCTAssertEqualObjects(
    session,
    self.session,
    "A graph request connection should derive sessions from the session provider"
  );
}

// MARK: - Properties

- (void)testDefaultConnectionTimeout
{
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    60,
    "Should have a default connection timeout of 60 seconds"
  );
}

- (void)testOverridingDefaultConnectionTimeoutWithInvalidTimeout
{
  [FBSDKGraphRequestConnection setDefaultConnectionTimeout:-1];
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    60,
    "Should not be able to override the default connection timeout with an invalid timeout"
  );
}

- (void)testOverridingDefaultConnectionTimeoutWithValidTimeout
{
  [FBSDKGraphRequestConnection setDefaultConnectionTimeout:100];
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    100,
    "Should be able to override the default connection timeout"
  );
}

- (void)testDefaultOverriddenVersionPart
{
  XCTAssertNil(
    [self.connection _overrideVersionPart],
    "There should not be an overridden version part by default"
  );
}

- (void)testOverridingVersionPartWithInvalidVersions
{
  NSArray *strings = @[@"", @"abc", @"-5", @"1.1.1.1.1", @"v1.1.1.1"];
  for (NSString *string in strings) {
    [self.connection overrideGraphAPIVersion:string];
    XCTAssertEqualObjects(
      [self.connection _overrideVersionPart],
      string,
      "Should not be able to override the graph api version with %@ but you can",
      string
    );
  }
}

- (void)testOverridingVersionPartWithValidVersions
{
  NSArray *strings = @[@"1", @"1.1", @"1.1.1", @"v1", @"v1.1", @"v1.1.1"];
  for (NSString *string in strings) {
    [self.connection overrideGraphAPIVersion:string];
    XCTAssertEqualObjects(
      [self.connection _overrideVersionPart],
      string,
      "Should be able to override the graph api version with a valid version string"
    );
  }
}

- (void)testOverridingVersionCopies
{
  NSString *version = @"v1.0";
  [self.connection overrideGraphAPIVersion:version];
  version = @"foo";

  XCTAssertNotEqual(
    version,
    [self.connection _overrideVersionPart],
    "Should copy the version so that changes to the original string do not affect the stored value"
  );
}

- (void)testDefaultCanMakeRequests
{
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  XCTAssertFalse(
    [FBSDKGraphRequestConnection canMakeRequests],
    "Should not be able to make requests by default"
  );
}

// MARK: - Adding Requests

- (void)testAddingRequestWithoutBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *_connection, id result, NSError *error) {
              // Do nothing here
            }];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Adding a request without a batch entry name should not store batch parameters"
  );
}

- (void)testAddingRequestWithEmptyBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
               batchEntryName:@""
            completionHandler:^(FBSDKGraphRequestConnection *_connection, id result, NSError *error) {
              // Do nothing here
            }];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Should not store batch parameters for a request with an empty batch entry name"
  );
}

- (void)testAddingRequestWithValidBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
               batchEntryName:@"foo"
            completionHandler:^(FBSDKGraphRequestConnection *_connection, id result, NSError *error) {
              // Do nothing here
            }];
  NSDictionary *expectedParameters = @{ @"name" : @"foo" };
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertEqualObjects(
    metadata.batchParameters,
    expectedParameters,
    "Should create and store batch parameters for a request with a non-empty batch entry name"
  );
}

- (void)testAddingRequestWithBatchParameters
{
  NSArray *states = @[@(kStateStarted), @(kStateCancelled), @(kStateCompleted), @(kStateSerialized)];

  for (NSNumber *state in states) {
    self.connection.state = state.intValue;
    XCTAssertThrowsSpecificNamed(
      [self.connection addRequest:self.requestForMeWithEmptyFields
                  batchParameters:@{}
                completionHandler:^(FBSDKGraphRequestConnection *_connection, id result, NSError *error) {}],
      NSException,
      NSInternalInconsistencyException,
      "Should throw error on request addition when state has raw value: %@",
      state
    );
  }
  self.connection.state = kStateCreated;

  XCTAssertNoThrow(
    [self.connection addRequest:self.requestForMeWithEmptyFields
                batchParameters:@{}
              completionHandler:^(FBSDKGraphRequestConnection *_connection, id result, NSError *error) {}],
    "Should not throw an error on request addition when state is 'created'"
  );
}

// MARK: - Cancelling

- (void)testCancellingConnection
{
  NSArray *states = @[@(kStateCreated), @(kStateStarted), @(kStateCancelled), @(kStateCompleted), @(kStateSerialized)];

  int expectedInvalidationCallCount = 0;
  for (NSNumber *state in states) {
    self.connection.state = state.intValue;
    expectedInvalidationCallCount++;

    [self.connection cancel];

    XCTAssertEqual(
      self.connection.state,
      kStateCancelled,
      "Cancelling a connection should set the state to the expected value"
    );
    XCTAssertEqual(
      self.session.invalidateAndCancelCallCount,
      expectedInvalidationCallCount,
      "Cancelling a connetion should invalidate and cancel the session"
    );
  }
}

- (void)testStartingConnectionWithUninitializedSDK
{
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  NSString *msg = @"FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized.";
  NSError *expectedError = [FBSDKError unknownErrorWithMessage:msg];

  __block BOOL completionWasCalled = NO;
  __weak typeof(self) weakSelf = self;
  [self.connection addRequest:self.sampleRequest
            completionHandler:^(FBSDKGraphRequestConnection *_Nullable _connection, id _Nullable result, NSError *_Nullable error) {
              XCTAssertEqualObjects(
                error,
                expectedError,
                "Starting a graph request before the SDK is initialized should return an error"
              );
              XCTAssertEqual(
                weakSelf.connection.state,
                kStateCancelled,
                "Starting a graph request before the SDK is initialized should update the connection state"
              );
              completionWasCalled = YES;
            }];
  [self.connection start];

  XCTAssertTrue(completionWasCalled, "Sanity check");
}

// MARK: - Client Token

- (void)testClientToken
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  [self stubCurrentAccessTokenWith:nil];
  [self stubClientTokenWith:@"clienttoken"];

  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         // make sure there is no recovery info for client token failures.
         XCTAssertNil(error.localizedRecoverySuggestion);
         [expectation fulfill];
       }];
  [connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463, \"type\":\"OAuthException\"}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testClientTokenSkipped
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  [self stubCurrentAccessTokenWith:nil];
  [self stubClientTokenWith:@"clienttoken"];

  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  [connection addRequest:self.requestForMeWithEmptyFields completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion);
    [expectation fulfill];
  }];
  [connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(self.missingTokenData, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegate
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  __block int actualCallbacksCount = 0;
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
       }];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
       }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];

  NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" }, {\"code\":200,\"body\": \"%@\" } ]", meResponse, meResponse];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testNonErrorEmptyDictionaryOrNullResponse
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  __block int actualCallbacksCount = 0;
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
       }];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
       }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];

  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": null }, {\"code\":200,\"body\": {} } ]"];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegateWithNetworkError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error != nil, @"didFinishLoading shouldn't have been called");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];

  fakeSession.capturedCompletion(nil, nil, [NSError errorWithDomain:@"NSURLErrorDomain" code:-1009 userInfo:nil]);

  [self waitForExpectations:@[expectation] timeout:1];
}

// TODO: Fix this to avoid using class property for access token
// test to verify piggyback refresh token behavior.
- (void)testTokenPiggyback
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  // FBSDKAccessToken.currentAccessToken = nil;
  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];
  FBSDKAccessToken *tokenThatNeedsRefresh = [[FBSDKAccessToken alloc]
                                             initWithTokenString:@"token"
                                             permissions:@[]
                                             declinedPermissions:@[]
                                             expiredPermissions:@[]
                                             appID:@"appid"
                                             userID:@"userid"
                                             expirationDate:[NSDate distantPast]
                                             refreshDate:[NSDate distantPast]
                                             dataAccessExpirationDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenThatNeedsRefresh];
  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         XCTAssertEqualObjects(tokenThatNeedsRefresh.userID, result[@"id"]);
         [expectation fulfill];
       }];
  [connection start];

  NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *refreshResponse = [[NSString stringWithFormat:@"{ \"access_token\":\"123\", \"expires_at\":%.0f }", [NSDate dateWithTimeIntervalSinceNow:60].timeIntervalSince1970] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *permissionsResponse = [@"{ \"data\": [ { \"permission\" : \"public_profile\", \"status\" : \"granted\" },  { \"permission\" : \"email\", \"status\" : \"granted\" },  { \"permission\" : \"user_friends\", \"status\" : \"declined\" } ] }" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" },"
                              @"{\"code\":200,\"body\": \"%@\" },"
                              @"{\"code\":200,\"body\": \"%@\" } ]",
                              meResponse,
                              refreshResponse,
                              permissionsResponse];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];

  XCTAssertGreaterThan([[FBSDKAccessToken currentAccessToken].expirationDate timeIntervalSinceNow], 0);
  XCTAssertGreaterThan([[FBSDKAccessToken currentAccessToken].refreshDate timeIntervalSinceNow], -60);
  XCTAssertNotEqualObjects(tokenThatNeedsRefresh, [FBSDKAccessToken currentAccessToken]);
  XCTAssertTrue([[FBSDKAccessToken currentAccessToken].permissions containsObject:@"email"]);
  XCTAssertTrue([[FBSDKAccessToken currentAccessToken].declinedPermissions containsObject:@"user_friends"]);
  [FBSDKAccessToken setCurrentAccessToken:nil];
}

// test no piggyback if refresh date is today.
- (void)testTokenPiggybackSkipped
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  FBSDKAccessToken *tokenNoRefresh = [[FBSDKAccessToken alloc]
                                      initWithTokenString:@"token"
                                      permissions:@[]
                                      declinedPermissions:@[]
                                      expiredPermissions:@[]
                                      appID:@"appid"
                                      userID:@"userid"
                                      expirationDate:[NSDate distantPast]
                                      refreshDate:[NSDate date]
                                      dataAccessExpirationDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenNoRefresh];

  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         XCTAssertEqualObjects(tokenNoRefresh.userID, result[@"id"]);
         [expectation fulfill];
       }];
  [connection start];

  NSString *responseString = @"{ \"id\" : \"userid\"}";
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];

  XCTAssertEqualObjects(tokenNoRefresh, [FBSDKAccessToken currentAccessToken]);
}

- (void)testUnsettingAccessToken
{
  __block int tokenChangeCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          if (++tokenChangeCount == 2) {
                                                                            XCTAssertNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                            XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeOldKey]);
                                                                            return YES;
                                                                          }
                                                                          return NO;
                                                                        }];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         XCTAssertNil(result);
         XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
         [expectation fulfill];
       }];
  [connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testUnsettingAccessTokenSkipped
{
  // Setup expectations
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                          return YES;
                                                                        }];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{@"fields" : @""}
                                                                tokenString:@"notCurrentToken"
                                                                    version:nil
                                                                 HTTPMethod:@""];
  [connection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
    [expectation fulfill];
  }];
  [connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testUnsettingAccessTokenFlag
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                          return YES;
                                                                        }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError];
  [connection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
    [expectation fulfill];
  }];
  [connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testRequestWithUserAgentSuffix
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setUserAgentSuffix:@"UnitTest.1.0.0"];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  [connection start];

  NSString *userAgent = [fakeSession.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertTrue([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

- (void)testRequestWithoutUserAgentSuffix
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setUserAgentSuffix:nil];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  [connection start];

  NSString *userAgent = [fakeSession.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertFalse([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

// TODO: Use fuzzy testing
- (void)testNonDictionaryInError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         // should not crash when receiving something other than a dictionary within the response.
         [expectation fulfill];
       }];

  [connection start];

  NSData *data = [@"{\"error\": \"a-non-dictionary\"}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRequestWithBatchConstructionWithSingleGetRequest
{
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"with_suffix"}];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *_Nullable potentialConnection, id _Nullable result, NSError *_Nullable error) {}];
  NSURLRequest *request = [connection requestWithBatch:connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"me"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"GET");
  XCTAssertTrue(request.HTTPBody.length == 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

- (void)testRequestWithBatchConstructionWithSinglePostRequest
{
  NSDictionary *parameters = @{
    @"first_key" : @"first_value",
  };
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"activities" parameters:parameters HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *_Nullable potentialConnection, id _Nullable result, NSError *_Nullable error) {}];
  NSURLRequest *request = [connection requestWithBatch:connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"activities"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"POST");
  XCTAssertTrue(request.HTTPBody.length > 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

#pragma mark - accessTokenWithRequest

- (void)testAccessTokenWithRequest
{
  NSString *expectedToken = @"fake_token";
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{@"fields" : @""}
                                                                tokenString:expectedToken
                                                                 HTTPMethod:FBSDKHTTPMethodGET
                                                                      flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  NSString *token = [connection accessTokenWithRequest:request];

  XCTAssertEqualObjects(token, expectedToken);
}

- (void)testAccessTokenWithRequestWithFacebookClientToken
{
  NSString *clientToken = @"client_token";
  [self stubClientTokenWith:clientToken];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];

  NSString *token = [connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);

  [self stubClientTokenWith:nil];
}

- (void)testAccessTokenWithRequestWithGamingClientToken
{
  NSString *clientToken = @"client_token";
  [self stubClientTokenWith:clientToken];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  FBSDKAuthenticationToken *authToken = [[FBSDKAuthenticationToken alloc] initWithTokenString:@"token_string"
                                                                                        nonce:@"nonce"
                                                                                       claims:nil
                                                                                  graphDomain:@"gaming"];
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:authToken];

  NSString *token = [connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"GG|%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);

  [self stubClientTokenWith:nil];
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:nil];
}

#pragma mark - Error recovery.

- (void)testRetry
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxy *fakeSession2 = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWithSessions:@[fakeSession, fakeSession2]];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  __block int completionCallCount = 0;
  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         completionCallCount++;
         XCTAssertEqual(completionCallCount, 1, "The completion should only be called once");
         XCTAssertEqual(
           2,
           [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue],
           "The completion should be called with the expected error code"
         );
         [expectation fulfill];
       }];

  [connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  // The first captured completion will be invoked and cause the retry
  fakeSession.capturedCompletion(data, response, nil);

  // It's necessary to dispatch async to avoid the completion from being invoked before it is captured
  dispatch_async(dispatch_get_main_queue(), ^{
    NSData *secondData = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
    fakeSession2.capturedCompletion(secondData, response, nil);
  });

  [self waitForExpectations:@[expectation] timeout:100];
}

- (void)testRetryDisabled
{
  FBSDKSettings.graphErrorRecoveryEnabled = NO;

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self stubFetchingCachedServerConfiguration];
  FakeURLSessionProxy *fakeSession = [FakeURLSessionProxy new];
  FakeURLSessionProxyFactory *fakeProxyFactory = [FakeURLSessionProxyFactory createWith:fakeSession];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory];

  __block int completionCallCount = 0;
  [connection addRequest:self.requestForMeWithEmptyFields
       completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
         completionCallCount++;
         XCTAssertEqual(completionCallCount, 1, "The completion should only be called once");
         XCTAssertEqual(
           1,
           [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue],
           "The completion should be called with the expected error code"
         );

         [expectation fulfill];
       }];

  [connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  // The first captured completion will be invoked and cause the retry
  fakeSession.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];

  FBSDKSettings.graphErrorRecoveryEnabled = NO;
}

// MARK: - Helpers

- (FBSDKGraphRequest *)sampleRequest
{
  return self.requestForMeWithEmptyFields;
}

- (FBSDKGraphRequest *)requestForMeWithEmptyFields
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];
}

- (FBSDKGraphRequest *)requestForMeWithEmptyFieldsNoTokenString
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} tokenString:nil HTTPMethod:FBSDKHTTPMethodGET flags:FBSDKGraphRequestFlagNone];
}

- (NSData *)missingTokenData
{
  return [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
}

@end
