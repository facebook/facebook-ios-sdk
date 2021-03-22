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

@import TestTools;
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginCompletion+Internal.h>
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
#else
 #import "FBSDKLoginCompletion+Internal.h"
 #import "FBSDKPermission.h"
#endif
#import "FBSDKLoginKitTests-Swift.h"

static NSString *const _fakeAppID = @"1234567";
static NSString *const _fakeChallence = @"some_challenge";

@interface FBSDKLoginURLCompleter (Testing)

@property (class, nonatomic, assign) id<FBSDKProfileProviding> profileFactory;

- (FBSDKLoginCompletionParameters *)parameters;
- (void)exchangeNonceForTokenWithGraphRequestConnectionProvider:(id<FBSDKGraphRequestConnectionProviding>)connection
                                                        handler:(FBSDKLoginCompletionParametersBlock)handler;

- (void)exchangeNonceForTokenWithHandler:(FBSDKLoginCompletionParametersBlock)handler;

- (void)fetchAndSetPropertiesForParameters:(nonnull FBSDKLoginCompletionParameters *)parameters
                                     nonce:(nonnull NSString *)nonce
                                   handler:(FBSDKLoginCompletionParametersBlock)handler;

+ (FBSDKProfile *)profileWithClaims:(FBSDKAuthenticationTokenClaims *)claims;

+ (void)reset;

+ (NSDateFormatter *)dateFormatter;

@end

@interface FBSDKAuthenticationTokenClaims (Testing)

- (instancetype)initWithJti:(NSString *)jti
                        iss:(NSString *)iss
                        aud:(NSString *)aud
                      nonce:(NSString *)nonce
                        exp:(long)exp
                        iat:(long)iat
                        sub:(NSString *)sub
                       name:(nullable NSString *)name
                      email:(nullable NSString *)email
                    picture:(nullable NSString *)picture
                userFriends:(nullable NSArray<NSString *> *)userFriends
               userBirthday:(nullable NSString *)userBirthday
               userAgeRange:(nullable NSDictionary *)userAgeRange;

@end

@interface FBSDKLoginCompletionTests : XCTestCase
{
  NSDictionary *_parameters;
}

@end

@interface FBSDKTestLoginURLCompleter : FBSDKLoginURLCompleter

@property int exchangeNonceCount;

@property int fetchAndSetAuthTokenCount;

@end

@implementation FBSDKTestLoginURLCompleter

- (void)exchangeNonceForTokenWithHandler:(FBSDKLoginCompletionParametersBlock)handler
{
  _exchangeNonceCount += 1;
}

- (void)fetchAndSetPropertiesForParameters:(nonnull FBSDKLoginCompletionParameters *)parameters
                                     nonce:(nonnull NSString *)nonce
                                   handler:(FBSDKLoginCompletionParametersBlock)handler
{
  _fetchAndSetAuthTokenCount += 1;
}

@end

@implementation FBSDKLoginCompletionTests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginURLCompleter reset];

  int secInDay = 60 * 60 * 24;
  _parameters = @{
    @"access_token" : @"some_access_token",
    @"id_token" : @"some_id_token",
    @"nonce" : @"some_nonce",
    @"granted_scopes" : @"public_profile,openid",
    @"denied_scopes" : @"email",
    @"signed_request" : @"some_signed_request",
    @"user_id" : @"123",
    @"expires" : [@(NSDate.date.timeIntervalSince1970 + secInDay * 60) stringValue],
    @"expires_at" : [@(NSDate.date.timeIntervalSince1970 + secInDay * 60) stringValue],
    @"expires_in" : [@(secInDay * 60) stringValue],
    @"data_access_expiration_time" : [@(NSDate.date.timeIntervalSince1970 + secInDay * 90) stringValue],
    @"state" : [NSString stringWithFormat:@"{\"challenge\":\"%@\"}", _fakeChallence],
    @"graph_domain" : @"facebook",
    @"error" : @"some_error",
    @"error_message" : @"some_error_message",
  };
}

- (void)tearDown
{
  [FBSDKLoginURLCompleter reset];

  [super tearDown];
}

// MARK: Creation

- (void)testDefaultProfileProvider
{
  NSObject *factory = (NSObject *)FBSDKLoginURLCompleter.profileFactory;
  XCTAssertEqualObjects(
    factory.class,
    FBSDKProfileFactory.class,
    "Should have the expected concrete profile provider"
  );
}

- (void)testSettingProfileProvider
{
  NSObject<FBSDKProfileProviding> *provider = [[TestProfileProvider alloc] initWithStubbedProfile:SampleUserProfiles.valid];
  FBSDKLoginURLCompleter.profileFactory = provider;

  XCTAssertEqualObjects(
    FBSDKLoginURLCompleter.profileFactory,
    provider,
    "Should be able to inject a profile provider"
  );
}

- (void)testInitWithAccessTokenWithIDToken
{
  NSMutableDictionary *parameters = self.parametersWithIDtoken.mutableCopy;
  [parameters addEntriesFromDictionary:self.parametersWithAccessToken];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithAccessToken
{
  NSDictionary *parameters = self.parametersWithAccessToken;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithNonce
{
  NSDictionary *parameters = self.parametersWithNonce;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithIDToken
{
  NSDictionary *parameters = self.parametersWithIDtoken;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithoutAccessTokenWithoutIDTokenWithoutNonce
{
  NSDictionary *parameters = self.parametersWithoutAccessTokenWithoutIDTokenWithoutNonce;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce
{
  NSDictionary *parameters = self.parametersWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyParameters
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:@{} appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithIDTokenAndNonce
{
  NSMutableDictionary *parameters = self.parametersWithIDtoken.mutableCopy;
  [parameters addEntriesFromDictionary:self.parametersWithNonce];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  XCTAssertNotNil(completer.parameters.error);
}

- (void)testInitWithError
{
  NSDictionary *parameters = self.parametersWithError;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  XCTAssertNotNil(completer.parameters.error);
}

- (void)testInitWithFuzzyParameters
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *parameters = [Fuzzer randomizeWithJson:_parameters];
    FBSDKLoginURLCompleter *_completer __unused = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];
  }
}

// MARK: - Nonce Exchange

- (void)testExchangeNonceForTokenWithMissingHandler
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:nil];
  XCTAssertNil(connection.capturedRequest, "Should not create a graph request if there's no handler to use the result");
}

- (void)testNonceExchangeWithoutNonce
{
  NSDictionary *parameters = self.rawParametersWithMissingNonce;

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    XCTAssertEqualObjects(
      completer.parameters,
      completionParams,
      "Should call the completion with the provided parameters"
    );
    XCTAssertEqual(completer.parameters.error.code, FBSDKErrorInvalidArgument, "Should provide an error with the expected code");
    completionWasInvoked = YES;
  };

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:handler];
  XCTAssertTrue(completionWasInvoked);
}

- (void)testNonceExchangeWithoutAppID
{
  NSString *appID = @"123";
  appID = nil;
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:appID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    XCTAssertEqualObjects(
      completer.parameters,
      completionParams,
      "Should call the completion with the provided parameters"
    );
    XCTAssertEqual(completer.parameters.error.code, FBSDKErrorInvalidArgument, "Should provide an error with the expected code");
    completionWasInvoked = YES;
  };

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:handler];
  XCTAssertTrue(completionWasInvoked);
  XCTAssertNil(connection.capturedRequest, "Should not create a graph request if there's no handler to use the result");
}

- (void)testNonceExchangeGraphRequestCreation
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:^(FBSDKLoginCompletionParameters *_Nonnull parameters) {
                                                               // not important here
                                                             }];
  FBSDKGraphRequest *capturedRequest = (FBSDKGraphRequest *)connection.capturedRequest;
  XCTAssertEqualObjects(
    capturedRequest.graphPath,
    @"oauth/access_token",
    "Should create a graph request with the expected graph path"
  );
  XCTAssertEqualObjects(
    [FBSDKTypeUtility dictionary:capturedRequest.parameters
                    objectForKey:@"grant_type"
                          ofType:NSString.class],
    @"fb_exchange_nonce",
    "Should create a graph request with the expected grant type parameter"
  );
  XCTAssertEqualObjects(
    [FBSDKTypeUtility dictionary:capturedRequest.parameters
                    objectForKey:@"fb_exchange_nonce"
                          ofType:NSString.class],
    completer.parameters.nonceString,
    "Should create a graph request with the expected nonce parameter"
  );
  XCTAssertEqualObjects(
    [FBSDKTypeUtility dictionary:capturedRequest.parameters
                    objectForKey:@"client_id"
                          ofType:NSString.class],
    _fakeAppID,
    "Should create a graph request with the expected app id parameter"
  );
  XCTAssertEqualObjects(
    [FBSDKTypeUtility dictionary:capturedRequest.parameters
                    objectForKey:@"fields"
                          ofType:NSString.class],
    @"",
    "Should create a graph request with the expected fields parameter"
  );
  XCTAssertEqual(
    capturedRequest.flags,
    FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
    | FBSDKGraphRequestFlagDisableErrorRecovery,
    "The graph request should not invalidate the token on error or disable error recovery"
  );
}

- (void)testNonceExchangeCompletionWithError
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    XCTAssertEqualObjects(
      completer.parameters,
      completionParams,
      "Should call the completion with the provided parameters"
    );
    XCTAssertEqualObjects(completer.parameters.error, self.sampleError, "Should pass through the error from the graph request");
    completionWasInvoked = YES;
  };

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:handler];
  connection.capturedCompletion(nil, nil, self.sampleError);
  XCTAssertTrue(completionWasInvoked);
}

- (void)testNonceExchangeCompletionWithAccessTokenString
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];
  NSDictionary *stubbedResult = @{ @"access_token" : self.name };

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    XCTAssertEqualObjects(
      completer.parameters,
      completionParams,
      "Should call the completion with the provided parameters"
    );
    XCTAssertEqualObjects(
      completer.parameters.accessTokenString,
      self.name,
      "Should set the access token string from the graph request's result"
    );
    completionWasInvoked = YES;
  };

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:handler];
  connection.capturedCompletion(nil, stubbedResult, nil);
  XCTAssertTrue(completionWasInvoked);
}

- (void)testNonceExchangeWithRandomResults
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:_parameters appID:_fakeAppID];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *factory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];

  NSDictionary *stubbedResult = @{
    @"access_token" : self.name,
    @"expires_in" : @"10000",
    @"data_access_expiration_time" : @1
  };

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    // Basically just making sure that nothing crashes here when we feed it garbage results
    completionWasInvoked = YES;
  };

  [completer exchangeNonceForTokenWithGraphRequestConnectionProvider:factory
                                                             handler:handler];

  for (int i = 0; i < 100; i++) {
    NSDictionary *params = [stubbedResult copy];
    NSDictionary *parameters = [Fuzzer randomizeWithJson:params];
    connection.capturedCompletion(nil, parameters, nil);
    XCTAssertTrue(completionWasInvoked);
    completionWasInvoked = NO;
  }
}

// MARK: Completion

- (void)testCompleteWithNonce
{
  FBSDKTestLoginURLCompleter *completer = [[FBSDKTestLoginURLCompleter alloc] initWithURLParameters:self.parametersWithNonce appID:_fakeAppID];
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };

  [completer completeLoginWithHandler:handler];

  XCTAssertNil(completer.parameters.error);
  XCTAssertEqual(completer.exchangeNonceCount, 1);
  XCTAssertEqual(completer.fetchAndSetAuthTokenCount, 0);
}

- (void)testCompleteWithAuthenticationTokenWithoutNonce
{
  FBSDKTestLoginURLCompleter *completer = [[FBSDKTestLoginURLCompleter alloc] initWithURLParameters:self.parametersWithIDtoken appID:_fakeAppID];
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };

  [completer completeLoginWithHandler:handler];

  XCTAssertNotNil(completer.parameters.error);
  XCTAssertEqual(completer.exchangeNonceCount, 0);
  XCTAssertEqual(completer.fetchAndSetAuthTokenCount, 0);
}

- (void)testCompleteWithAuthenticationTokenWithNonce
{
  FBSDKTestLoginURLCompleter *completer = [[FBSDKTestLoginURLCompleter alloc] initWithURLParameters:self.parametersWithIDtoken appID:_fakeAppID];
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };

  [completer completeLoginWithHandler:handler nonce:@"some_nonce"];

  XCTAssertNil(completer.parameters.error);
  XCTAssertEqual(completer.exchangeNonceCount, 0);
  XCTAssertEqual(completer.fetchAndSetAuthTokenCount, 1);
}

- (void)testCompleteWithAccessToken
{
  FBSDKTestLoginURLCompleter *completer = [[FBSDKTestLoginURLCompleter alloc] initWithURLParameters:self.parametersWithAccessToken appID:_fakeAppID];

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
  };

  [completer completeLoginWithHandler:handler nonce:@"some_nonce"];

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
  XCTAssertNil(completer.parameters.error);
  XCTAssertEqual(completer.exchangeNonceCount, 0);
  XCTAssertEqual(completer.fetchAndSetAuthTokenCount, 0);
}

- (void)testCompleteWithEmptyParameters
{
  FBSDKTestLoginURLCompleter *completer = [[FBSDKTestLoginURLCompleter alloc] initWithURLParameters:@{} appID:_fakeAppID];

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
  };

  [completer completeLoginWithHandler:handler nonce:@"some_nonce"];

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
  XCTAssertNil(completer.parameters.error);
  XCTAssertEqual(completer.exchangeNonceCount, 0);
  XCTAssertEqual(completer.fetchAndSetAuthTokenCount, 0);
}

// MARK: Profile

- (void)testCreateProfileWithClaims
{
  TestProfileProvider *factory = [[TestProfileProvider alloc] initWithStubbedProfile:SampleUserProfiles.valid];
  FBSDKLoginURLCompleter.profileFactory = factory;
  FBSDKAuthenticationTokenClaims *claim = [[FBSDKAuthenticationTokenClaims alloc] initWithJti:@"some_jti"
                                                                                          iss:@"some_iss"
                                                                                          aud:@"some_aud"
                                                                                        nonce:@"some_nonce"
                                                                                          exp:1234
                                                                                          iat:1234
                                                                                          sub:@"some_sub"
                                                                                         name:@"some_name"
                                                                                        email:@"example@example.com"
                                                                                      picture:@"www.facebook.com"
                                                                                  userFriends:@[@"123", @"456"]
                                                                                 userBirthday:@"01/01/1990"
                                                                                 userAgeRange:@{@"min" : @((long)21)}];
  [FBSDKLoginURLCompleter profileWithClaims:claim];
  XCTAssertEqualObjects(
    factory.capturedUserID,
    claim.sub,
    "Should request a profile with the claims sub as the user identifier"
  );
  XCTAssertEqualObjects(
    factory.capturedName,
    claim.name,
    "Should request a profile using the name from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedImageURL.absoluteString,
    claim.picture,
    "Should request an image URL from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedEmail,
    claim.email,
    "Should request a profile using the email from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedFriendIDs,
    claim.userFriends,
    "Should request a profile using the friend identifiers from the claims"
  );
  NSDateFormatter *formatter = NSDateFormatter.new;
  [formatter setDateFormat:@"MM/dd/yyyy"];
  XCTAssertEqualObjects(
    [formatter stringFromDate:factory.capturedBirthday],
    claim.userBirthday,
    "Should request a profile using the user birthday from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedAgeRange,
    [FBSDKUserAgeRange ageRangeFromDictionary:claim.userAgeRange],
    "Should request a profile using the user age range from the claims"
  );
  XCTAssertTrue(
    factory.capturedIsLimited,
    "Should request a profile with limited information"
  );
}

// MARK: Helpers

- (NSError *)sampleError
{
  return [NSError errorWithDomain:self.name code:0 userInfo:nil];
}

- (NSDictionary *)rawParametersWithMissingNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"nonce"]];
  return parameters;
}

- (NSDictionary *)parametersWithNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary *)parametersWithAccessToken
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary *)parametersWithIDtoken
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"access_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary *)parametersWithoutAccessTokenWithoutIDTokenWithoutNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary *)parametersWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"error", @"error_message"]];
  [parameters setValue:@"" forKey:@"access_token"];
  [parameters setValue:@"" forKey:@"id_token"];
  [parameters setValue:@"" forKey:@"nonce"];
  return parameters;
}

- (NSDictionary *)parametersWithError
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"nonce"]];
  return parameters;
}

- (void)verifyParameters:(FBSDKLoginCompletionParameters *)parameters urlParameter:(NSDictionary *)urlParameters
{
  XCTAssertEqualObjects(parameters.accessTokenString, urlParameters[@"access_token"]);
  XCTAssertEqualObjects(parameters.authenticationTokenString, urlParameters[@"id_token"]);
  XCTAssertEqualObjects(parameters.appID, _fakeAppID);
  XCTAssertEqualObjects(parameters.challenge, _fakeChallence);
  NSSet *permissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[urlParameters[@"granted_scopes"] componentsSeparatedByString:@","]]];
  XCTAssertEqualObjects(parameters.permissions, permissions);
  NSSet *declinedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[urlParameters[@"denied_scopes"] componentsSeparatedByString:@","]]];
  XCTAssertEqualObjects(parameters.declinedPermissions, declinedPermissions);
  XCTAssertEqualObjects(parameters.userID, urlParameters[@"user_id"]);
  XCTAssertEqualObjects(parameters.graphDomain, urlParameters[@"graph_domain"]);

  if (urlParameters[@"expires"] || urlParameters[@"expires_at"] || urlParameters[@"expires_in"]) {
    XCTAssertNotNil(parameters.expirationDate);
  }
  if (urlParameters[@"data_access_expiration_time"]) {
    XCTAssertNotNil(parameters.dataAccessExpirationDate);
  }
  XCTAssertEqualObjects(parameters.nonceString, urlParameters[@"nonce"]);
  XCTAssertNil(parameters.error);
}

- (void)verifyEmptyParameters:(FBSDKLoginCompletionParameters *)parameters
{
  XCTAssertNil(parameters.accessTokenString);
  XCTAssertNil(parameters.authenticationTokenString);
  XCTAssertNil(parameters.appID);
  XCTAssertNil(parameters.challenge);
  XCTAssertNil(parameters.permissions);
  XCTAssertNil(parameters.declinedPermissions);
  XCTAssertNil(parameters.userID);
  XCTAssertNil(parameters.graphDomain);
  XCTAssertNil(parameters.expirationDate);
  XCTAssertNil(parameters.dataAccessExpirationDate);
  XCTAssertNil(parameters.nonceString);
  XCTAssertNil(parameters.error);
}

@end
