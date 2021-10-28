/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import TestTools;
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginCompletion+Internal.h>
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
#else
 #import "FBSDKPermission.h"
#endif
#import "FBSDKLoginKitTests-Swift.h"

static NSString *const _fakeAppID = @"1234567";
static NSString *const _fakeChallence = @"some_challenge";

@interface FBSDKLoginURLCompleter (Testing)

@property (class, nonatomic, assign) id<FBSDKProfileCreating> profileFactory;

- (FBSDKLoginCompletionParameters *)parameters;

+ (FBSDKProfile *)profileWithClaims:(FBSDKAuthenticationTokenClaims *)claims;

+ (void)reset;

+ (NSDateFormatter *)dateFormatter;

@end

@interface FBSDKAuthenticationTokenClaims (Testing)

- (nullable instancetype)initWithJti:(nonnull NSString *)jti
                                 iss:(nonnull NSString *)iss
                                 aud:(nonnull NSString *)aud
                               nonce:(nonnull NSString *)nonce
                                 exp:(NSTimeInterval)exp
                                 iat:(NSTimeInterval)iat
                                 sub:(nonnull NSString *)sub
                                name:(nullable NSString *)name
                           givenName:(nullable NSString *)givenName
                          middleName:(nullable NSString *)middleName
                          familyName:(nullable NSString *)familyName
                               email:(nullable NSString *)email
                             picture:(nullable NSString *)picture
                         userFriends:(nullable NSArray<NSString *> *)userFriends
                        userBirthday:(nullable NSString *)userBirthday
                        userAgeRange:(nullable NSDictionary<NSString *, id> *)userAgeRange
                        userHometown:(nullable NSDictionary<NSString *, id> *)userHometown
                        userLocation:(nullable NSDictionary<NSString *, id> *)userLocation
                          userGender:(nullable NSString *)userGender
                            userLink:(nullable NSString *)userLink;

@end

@interface FBSDKLoginCompletionTests : XCTestCase

@property (nonatomic) NSDictionary<NSString *, id> *parameters;

@property (nonatomic) TestGraphRequestConnection *graphConnection;

@property (nonatomic) TestAuthenticationTokenFactory *authenticationTokenFactory;

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
    @"expires" : @(NSDate.date.timeIntervalSince1970 + secInDay * 60),
    @"expires_at" : @(NSDate.date.timeIntervalSince1970 + secInDay * 60),
    @"expires_in" : @(secInDay * 60),
    @"data_access_expiration_time" : @(NSDate.date.timeIntervalSince1970 + secInDay * 90),
    @"state" : [NSString stringWithFormat:@"{\"challenge\":\"%@\"}", _fakeChallence],
    @"graph_domain" : @"facebook",
    @"error" : @"some_error",
    @"error_message" : @"some_error_message",
  };

  _graphConnection = [TestGraphRequestConnection new];
  _authenticationTokenFactory = [TestAuthenticationTokenFactory new];
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
  NSObject<FBSDKProfileCreating> *provider = [[TestProfileFactory alloc] initWithStubbedProfile:SampleUserProfiles.valid];
  FBSDKLoginURLCompleter.profileFactory = provider;

  XCTAssertEqualObjects(
    FBSDKLoginURLCompleter.profileFactory,
    provider,
    "Should be able to inject a profile provider"
  );
}

- (void)testInitWithAccessTokenWithIDToken
{
  NSMutableDictionary<NSString *, id> *parameters = [self.parametersWithIDtoken mutableCopy];
  [parameters addEntriesFromDictionary:self.parametersWithAccessToken];
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters expectedParameters:parameters];
}

- (void)testInitWithAccessToken
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithAccessToken;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters expectedParameters:parameters];
}

- (void)testInitWithNonce
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithNonce;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters expectedParameters:parameters];
}

- (void)testInitWithIDToken
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithIDtoken;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters expectedParameters:parameters];
}

- (void)testInitWithStringExpirations
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithStringExpirations;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters expectedParameters:parameters];
}

- (void)testInitWithoutAccessTokenWithoutIDTokenWithoutNonce
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithoutAccessTokenWithoutIDTokenWithoutNonce;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyParameters
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:@{} appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithIDTokenAndNonce
{
  NSMutableDictionary<NSString *, id> *parameters = [self.parametersWithIDtoken mutableCopy];
  [parameters addEntriesFromDictionary:self.parametersWithNonce];
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  XCTAssertNotNil(completer.parameters.error);
}

- (void)testInitWithError
{
  NSDictionary<NSString *, id> *parameters = self.parametersWithError;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:parameters appID:_fakeAppID];

  XCTAssertNotNil(completer.parameters.error);
}

- (void)testInitWithFuzzyParameters
{
  for (int i = 0; i < 100; i++) {
    NSDictionary<NSString *, id> *parameters = [Fuzzer randomizeWithJson:_parameters];
    FBSDKLoginURLCompleter *_completer __unused = [self loginCompleterWithParameters:parameters appID:_fakeAppID];
  }
}

// MARK: Completion

- (void)testCompleteWithMissingHandler
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:_parameters appID:_fakeAppID];

  FBSDKLoginCompletionParametersBlock handler = nil;
  [completer completeLoginWithHandler:handler];

  XCTAssertNil(_graphConnection.capturedRequest, "Should not create a graph request if there's no handler to use the result");
}

- (void)testCompleteWithoutAppID
{
  NSString *appID = nil;
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:_parameters appID:appID];

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

  [completer completeLoginWithHandler:handler];
  XCTAssertTrue(completionWasInvoked);
  XCTAssertNil(_graphConnection.capturedRequest, "Should not create a graph request if there's no handler to use the result");
}

- (void)testCompleteWithNonceGraphRequestCreation
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithNonce appID:_fakeAppID];
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };

  [completer completeLoginWithHandler:handler];

  XCTAssertNil(completer.parameters.error);
  XCTAssertNil(_authenticationTokenFactory.capturedTokenString);
  FBSDKGraphRequest *capturedRequest = (FBSDKGraphRequest *)_graphConnection.capturedRequest;
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
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithNonce appID:_fakeAppID];

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

  [completer completeLoginWithHandler:handler];
  _graphConnection.capturedCompletion(nil, nil, self.sampleError);
  XCTAssertTrue(completionWasInvoked);
}

- (void)testNonceExchangeCompletionWithAccessTokenString
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithNonce appID:_fakeAppID];
  NSDictionary<NSString *, id> *stubbedResult = @{ @"access_token" : self.name };

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

  [completer completeLoginWithHandler:handler];
  _graphConnection.capturedCompletion(nil, stubbedResult, nil);
  XCTAssertTrue(completionWasInvoked);
}

- (void)testNonceExchangeCompletionWithAccessTokenStringAndAuthenticationTokenString
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithNonce appID:_fakeAppID];
  NSString *nonce = @"some_nonce";
  NSString *id_token = @"some_id_token";
  NSDictionary<NSString *, id> *stubbedResult = @{
    @"access_token" : self.name,
    @"id_token" : id_token
  };
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    // not important
  };

  [completer completeLoginWithHandler:handler nonce:nonce];
  _graphConnection.capturedCompletion(nil, stubbedResult, nil);

  XCTAssertEqualObjects(
    completer.parameters.accessTokenString,
    self.name,
    "Should set the access token string from the graph request's result"
  );
  XCTAssertEqualObjects(
    completer.parameters.authenticationTokenString,
    id_token,
    "Should set the authentication token string from the graph request's result"
  );
  XCTAssertEqual(
    _authenticationTokenFactory.capturedTokenString,
    id_token,
    "Should call AuthenticationTokenFactory with the expected token string"
  );
  XCTAssertEqual(
    _authenticationTokenFactory.capturedNonce,
    nonce,
    "Should call AuthenticationTokenFactory with the expected nonce"
  );
}

- (void)testNonceExchangeWithRandomResults
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithNonce appID:_fakeAppID];

  NSDictionary<NSString *, id> *stubbedResult = @{
    @"access_token" : self.name,
    @"expires_in" : @"10000",
    @"data_access_expiration_time" : @1
  };

  __block BOOL completionWasInvoked = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *_Nonnull completionParams) {
    // Basically just making sure that nothing crashes here when we feed it garbage results
    completionWasInvoked = YES;
  };

  [completer completeLoginWithHandler:handler];

  for (int i = 0; i < 100; i++) {
    NSDictionary<NSString *, id> *params = [stubbedResult copy];
    NSDictionary<NSString *, id> *parameters = [Fuzzer randomizeWithJson:params];
    _graphConnection.capturedCompletion(nil, parameters, nil);
    XCTAssertTrue(completionWasInvoked);
    completionWasInvoked = NO;
  }
}

- (void)testCompleteWithAuthenticationTokenWithoutNonce
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithIDtoken appID:_fakeAppID];
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };

  [completer completeLoginWithHandler:handler];

  XCTAssertNotNil(completer.parameters.error);
  XCTAssertNil(_graphConnection.capturedRequest);
  XCTAssertNil(_authenticationTokenFactory.capturedTokenString);
}

- (void)testCompleteWithAuthenticationTokenWithNonce
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithIDtoken appID:_fakeAppID];

  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    // do nothing
  };
  NSString *nonce = @"some_nonce";

  [completer completeLoginWithHandler:handler nonce:nonce];

  XCTAssertNil(completer.parameters.error);
  XCTAssertNil(_graphConnection.capturedRequest);
  XCTAssertEqualObjects(
    _authenticationTokenFactory.capturedTokenString,
    self.parametersWithIDtoken[@"id_token"],
    "Should call AuthenticationTokenFactory with the expected token string"
  );
  XCTAssertEqualObjects(
    _authenticationTokenFactory.capturedNonce,
    nonce,
    "Should call AuthenticationTokenFactory with the expected nonce"
  );
}

- (void)testAuthenticationTokenCreationCompleteWithEmptyResult
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithIDtoken appID:_fakeAppID];
  NSString *nonce = @"some_nonce";

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
    XCTAssertNotNil(parameters.error);
    XCTAssertNil(parameters.authenticationToken);
  };

  [completer completeLoginWithHandler:handler nonce:nonce];
  _authenticationTokenFactory.capturedCompletion(nil);

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
}

- (void)testAuthenticationTokenCreationCompleteWithToken
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithIDtoken appID:_fakeAppID];
  NSString *nonce = @"some_nonce";

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
    XCTAssertNil(completer.parameters.error);
    XCTAssertEqualObjects(parameters.authenticationToken.tokenString, self.parametersWithIDtoken[@"id_token"]);
    XCTAssertEqualObjects(parameters.authenticationToken.nonce, nonce);
  };

  [completer completeLoginWithHandler:handler nonce:nonce];
  _authenticationTokenFactory.capturedCompletion([[FBSDKAuthenticationToken alloc] initWithTokenString:self.parametersWithIDtoken[@"id_token"] nonce:nonce]);

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
}

- (void)testCompleteWithAccessToken
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:self.parametersWithAccessToken appID:_fakeAppID];

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
    [self verifyParameters:parameters expectedParameters:self.parametersWithAccessToken];
  };

  [completer completeLoginWithHandler:handler nonce:@"some_nonce"];

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
  XCTAssertNil(completer.parameters.error);
  XCTAssertNil(_graphConnection.capturedRequest);
  XCTAssertNil(_authenticationTokenFactory.capturedTokenString);
}

- (void)testCompleteWithEmptyParameters
{
  FBSDKLoginURLCompleter *completer = [self loginCompleterWithParameters:@{} appID:_fakeAppID];

  __block BOOL wasCalled = NO;
  FBSDKLoginCompletionParametersBlock handler = ^(FBSDKLoginCompletionParameters *parameters) {
    wasCalled = YES;
  };

  [completer completeLoginWithHandler:handler nonce:@"some_nonce"];

  XCTAssert(wasCalled, @"Handler should be invoked syncronously");
  XCTAssertNil(completer.parameters.error);
  XCTAssertNil(_graphConnection.capturedRequest);
  XCTAssertNil(_authenticationTokenFactory.capturedTokenString);
}

// MARK: Profile

- (void)testCreateProfileWithClaims
{
  TestProfileFactory *factory = [[TestProfileFactory alloc] initWithStubbedProfile:SampleUserProfiles.valid];
  FBSDKLoginURLCompleter.profileFactory = factory;
  FBSDKAuthenticationTokenClaims *claim = [[FBSDKAuthenticationTokenClaims alloc] initWithJti:@"some_jti"
                                                                                          iss:@"some_iss"
                                                                                          aud:@"some_aud"
                                                                                        nonce:@"some_nonce"
                                                                                          exp:1234
                                                                                          iat:1234
                                                                                          sub:@"some_sub"
                                                                                         name:@"some_name"
                                                                                    givenName:@"first"
                                                                                   middleName:@"middle"
                                                                                   familyName:@"last"
                                                                                        email:@"example@example.com"
                                                                                      picture:@"www.facebook.com"
                                                                                  userFriends:@[@"123", @"456"]
                                                                                 userBirthday:@"01/01/1990"
                                                                                 userAgeRange:@{@"min" : @(21)}
                                                                                 userHometown:@{@"id" : @"112724962075996", @"name" : @"Martinez, California"}
                                                                                 userLocation:@{@"id" : @"110843418940484", @"name" : @"Seattle, Washington"}
                                                                                   userGender:@"male"
                                                                                     userLink:@"facebook.com"];
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
    factory.capturedFirstName,
    claim.givenName,
    "Should request a profile using the first name from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedMiddleName,
    claim.middleName,
    "Should request a profile using the middle name from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedLastName,
    claim.familyName,
    "Should request a profile using the last name from the claims"
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
  // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.dateFormat = @"MM/dd/yyyy";
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
  XCTAssertEqualObjects(
    factory.capturedHometown,
    [FBSDKLocation locationFromDictionary:claim.userHometown],
    "Should request a profile using the user hometown from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedLocation,
    [FBSDKLocation locationFromDictionary:claim.userLocation],
    "Should request a profile using the user location from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedGender,
    claim.userGender,
    "Should request a profile using the gender from the claims"
  );
  XCTAssertEqualObjects(
    factory.capturedLinkURL,
    [NSURL URLWithString:claim.userLink],
    "Should request a profile using the link from the claims"
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

- (NSDictionary<NSString *, id> *)rawParametersWithMissingNonce
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"nonce"]];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithNonce
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithAccessToken
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"id_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithIDtoken
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"access_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithoutAccessTokenWithoutIDTokenWithoutNonce
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"nonce", @"error", @"error_message"]];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"error", @"error_message"]];
  [parameters setValue:@"" forKey:@"access_token"];
  [parameters setValue:@"" forKey:@"id_token"];
  [parameters setValue:@"" forKey:@"nonce"];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithStringExpirations
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"error", @"error_message"]];
  [parameters setValue:[_parameters[@"expires"] stringValue] forKey:@"expires"];
  [parameters setValue:[_parameters[@"expires_at"] stringValue] forKey:@"expires_at"];
  [parameters setValue:[_parameters[@"expires_in"] stringValue] forKey:@"expires_in"];
  [parameters setValue:[_parameters[@"data_access_expiration_time"] stringValue] forKey:@"data_access_expiration_time"];
  return parameters;
}

- (NSDictionary<NSString *, id> *)parametersWithError
{
  NSMutableDictionary<NSString *, id> *parameters = [_parameters mutableCopy];
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"nonce"]];
  return parameters;
}

- (void)verifyParameters:(FBSDKLoginCompletionParameters *)parameters expectedParameters:(NSDictionary<NSString *, id> *)expectedParameters
{
  XCTAssertEqualObjects(parameters.accessTokenString, expectedParameters[@"access_token"]);
  XCTAssertEqualObjects(parameters.authenticationTokenString, expectedParameters[@"id_token"]);
  XCTAssertEqualObjects(parameters.appID, _fakeAppID);
  XCTAssertEqualObjects(parameters.challenge, _fakeChallence);
  NSSet<FBSDKPermission *> *permissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[expectedParameters[@"granted_scopes"] componentsSeparatedByString:@","]]];
  XCTAssertEqualObjects(parameters.permissions, permissions);
  NSSet<FBSDKPermission *> *declinedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[expectedParameters[@"denied_scopes"] componentsSeparatedByString:@","]]];
  XCTAssertEqualObjects(parameters.declinedPermissions, declinedPermissions);
  XCTAssertEqualObjects(parameters.userID, expectedParameters[@"user_id"]);
  XCTAssertEqualObjects(parameters.graphDomain, expectedParameters[@"graph_domain"]);

  if (expectedParameters[@"expires"]) {
    XCTAssertEqualWithAccuracy(parameters.expirationDate.timeIntervalSince1970, [FBSDKTypeUtility doubleValue:expectedParameters[@"expires"]], 100);
  }
  if (expectedParameters[@"expires_at"] || expectedParameters[@"expires_in"]) {
    XCTAssertEqualWithAccuracy(parameters.expirationDate.timeIntervalSince1970, [FBSDKTypeUtility doubleValue:expectedParameters[@"expires_at"]], 100);
  }
  if (expectedParameters[@"expires_in"]) {
    XCTAssertEqualWithAccuracy(parameters.expirationDate.timeIntervalSinceNow, [FBSDKTypeUtility doubleValue:expectedParameters[@"expires_in"]], 100);
  }
  if (expectedParameters[@"data_access_expiration_time"]) {
    XCTAssertEqualWithAccuracy(parameters.dataAccessExpirationDate.timeIntervalSince1970, [FBSDKTypeUtility doubleValue:expectedParameters[@"data_access_expiration_time"]], 100);
  }

  XCTAssertEqualObjects(parameters.nonceString, expectedParameters[@"nonce"]);
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

- (FBSDKLoginURLCompleter *)loginCompleterWithParameters:(NSDictionary<NSString *, id> *)parameters
                                                   appID:(NSString *)appID
{
  TestGraphRequestConnectionFactory *graphConnectionFactory = [TestGraphRequestConnectionFactory createWithStubbedConnection:_graphConnection];
  return [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters
                                                         appID:appID
                                 graphRequestConnectionFactory:graphConnectionFactory
                                    authenticationTokenCreator:_authenticationTokenFactory];
}

@end
