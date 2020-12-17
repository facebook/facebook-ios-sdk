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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginCompletion+Internal.h>
#else
 #import "FBSDKLoginCompletion+Internal.h"
#endif

static NSString *const _fakeAppID = @"1234567";
static NSString *const _fakeChallence = @"some_challenge";

@interface FBSDKLoginURLCompleter (Testing)

- (FBSDKLoginCompletionParameters *)parameters;

@end

@interface FBSDKLoginCompletionTests : XCTestCase
{
  NSDictionary *_parameters;
}

@end

@implementation FBSDKLoginCompletionTests

- (void)setUp
{
  [super setUp];

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

// MARK: Creation

- (void)testInitWithAccessTokenWithIDToken
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"nonce", @"error", @"error_message"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithAccessToken
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"nonce", @"error", @"error_message"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"id_token", @"access_token", @"error", @"error_message"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithIDToken
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"access_token", @"expires", @"expires_at", @"expires_in", @"data_access_expiration_time", @"graph_domain", @"nonce", @"error", @"error_message"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyParameters:completer.parameters urlParameter:parameters];
}

- (void)testInitWithoutAccessTokenWithoutIDTokenWithoutNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"access_token", @"id_token", @"nonce", @"error", @"error_message"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"error", @"error_message"]];
  [parameters setValue:@"" forKey:@"access_token"];
  [parameters setValue:@"" forKey:@"id_token"];
  [parameters setValue:@"" forKey:@"nonce"];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithEmptyParameters
{
  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:@{} appID:_fakeAppID];

  [self verifyEmptyParameters:completer.parameters];
}

- (void)testInitWithError
{
  NSMutableDictionary *parameters = _parameters.mutableCopy;
  [parameters removeObjectsForKeys:@[@"access_token", @"id_token", @"nonce"]];

  FBSDKLoginURLCompleter *completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters appID:_fakeAppID];

  XCTAssertNotNil(completer.parameters.error);
}

// MARK: Helpers

- (void)verifyParameters:(FBSDKLoginCompletionParameters *)parameters urlParameter:(NSDictionary *)urlParameters
{
  XCTAssertEqualObjects(parameters.accessTokenString, urlParameters[@"access_token"]);
  XCTAssertEqualObjects(parameters.authenticationTokenString, urlParameters[@"id_token"]);
  XCTAssertEqualObjects(parameters.appID, _fakeAppID);
  XCTAssertEqualObjects(parameters.challenge, _fakeChallence);
  NSSet *permissions = [NSSet setWithArray:[urlParameters[@"granted_scopes"] componentsSeparatedByString:@","]];
  XCTAssertEqualObjects(parameters.permissions, permissions);
  NSSet *declinedPermissions = [NSSet setWithArray:[urlParameters[@"denied_scopes"] componentsSeparatedByString:@","]];
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
