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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKLoginManager.h"
#import "FBSDKLoginManager+Internal.h"
#import "FBSDKLoginManagerLoginResult.h"
#import "FBSDKLoginUtilityTests.h"

static NSString *const kFakeAppID = @"7391628439";

static NSString *const kFakeChallenge = @"a =bcdef";

@interface FBSDKLoginManager (Testing)

- (NSDictionary *)logInParametersFromURL:(NSURL *)url;

@end

@interface FBSDKLoginManagerTests : XCTestCase

@end

@implementation FBSDKLoginManagerTests
{
  id _mockNSBundle;
}

- (void)setUp
{
  _mockNSBundle = [FBSDKLoginUtilityTests mainBundleMock];
  [FBSDKSettings setAppID:kFakeAppID];
}

- (NSURL *)authorizeURLWithParameters:(NSString *)parameters joinedBy:(NSString *)joinChar
{
  return [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@%@", kFakeAppID, joinChar, parameters]];
}

- (NSURL *)authorizeURLWithFragment:(NSString *)fragment challenge:(NSString *)challenge
{
  challenge = [FBSDKUtility URLEncode:challenge];
  fragment = [NSString stringWithFormat:@"%@%@state=%@",
              fragment,
              fragment.length > 0 ? @"&" : @"",
              [FBSDKUtility URLEncode:[NSString stringWithFormat:@"{\"challenge\":\"%@\"}", challenge]]
  ];
  return [self authorizeURLWithParameters:fragment joinedBy:@"#"];
}

- (NSURL *)authorizeURLWithFragment:(NSString *)fragment
{
  return [self authorizeURLWithFragment:fragment challenge:kFakeChallenge];
}

- (FBSDKLoginManager *)loginManagerExpectingChallenge
{
  FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
  id partialMock = (FBSDKLoginManager *)[OCMockObject partialMockForObject:loginManager];

  [[[partialMock stub] andReturn:kFakeChallenge] loadExpectedChallenge];

  return (FBSDKLoginManager *)partialMock;
}

// verify basic case of first login and getting granted and declined permissions (is not classified as cancelled)
- (void)testOpenURLAuth
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = [self loginManagerExpectingChallenge];
  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  __block FBSDKAccessToken *tokenAfterAuth;
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertFalse(result.isCancelled);
    tokenAfterAuth = [FBSDKAccessToken currentAccessToken];
    XCTAssertEqualObjects(tokenAfterAuth, result.token);
    XCTAssertTrue([tokenAfterAuth.userID isEqualToString:@"123"], @"failed to parse userID");
    XCTAssertTrue([tokenAfterAuth.permissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
    XCTAssertTrue([result.grantedPermissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
    NSSet *expectedDeclined = [NSSet setWithObjects:@"email", @"user_friends", nil];
    XCTAssertEqualObjects(tokenAfterAuth.declinedPermissions, expectedDeclined, @"unexpected permissions");
    XCTAssertEqualObjects(result.declinedPermissions, expectedDeclined, @"unexpected permissions");
    [expectation fulfill];
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];

  // now test a cancel and make sure the current token is not touched.
  url = [self authorizeURLWithParameters:@"error=access_denied&error_code=200&error_description=Permissions+error&error_reason=user_denied#_=_" joinedBy:@"?"];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  FBSDKAccessToken *actualTokenAfterCancel = [FBSDKAccessToken currentAccessToken];
  XCTAssertEqualObjects(tokenAfterAuth, actualTokenAfterCancel);
}

// verify basic case of first login and no declined permissions.
- (void)testOpenURLAuthNoDeclines
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = [self loginManagerExpectingChallenge];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  FBSDKAccessToken *actualToken = [FBSDKAccessToken currentAccessToken];
  XCTAssertTrue([actualToken.userID isEqualToString:@"123"], @"failed to parse userID");
  XCTAssertTrue([actualToken.permissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
  NSSet *expectedDeclined = [NSSet set];
  XCTAssertEqualObjects(actualToken.declinedPermissions, expectedDeclined, @"unexpected permissions");
}

// verify that recentlyDeclined is a subset of requestedPermissions (i.e., other declined permissions are not in recentlyDeclined)
- (void)testOpenURLRecentlyDeclined
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  // receive url with denied_scopes more than what was requested.
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=user_friends,user_likes&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertFalse(result.isCancelled);
    XCTAssertEqualObjects(result.declinedPermissions, [NSSet setWithObject:@"user_friends"]);
    NSSet *expectedDeclinedPermissions = [NSSet setWithObjects:@"user_friends", @"user_likes", nil];
    XCTAssertEqualObjects(result.token.declinedPermissions, expectedDeclinedPermissions);
    XCTAssertEqualObjects(result.grantedPermissions, [NSSet setWithObject:@"public_profile"]);
    [expectation fulfill];
  };
  FBSDKLoginManager *target = [self loginManagerExpectingChallenge];
  [target setRequestedPermissions:[NSSet setWithObject:@"user_friends"]];
  [target setHandler:handler];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

// verify that a reauth for already granted permissions is not treated as a cancellation.
- (void)testOpenURLReauthSamePermissionsIsNotCancelled
{
  // XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile", @"read_stream"]
                                                              declinedPermissions:@[]
                                                               expiredPermissions:@[]
                                                                            appID:@""
                                                                           userID:@""
                                                                   expirationDate:nil
                                                                      refreshDate:nil
                                                         dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:existingToken];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile,read_stream&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  // Use OCMock to verify the validateReauthentication: call and verify the result there.
  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];
  [[[target stub] andDo:^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKLoginManagerLoginResult *result;
    [invocation getArgument:&result atIndex:3];
    XCTAssertFalse(result.isCancelled);
    XCTAssertNotNil(result.token);
  }] validateReauthentication:[OCMArg any] withResult:[OCMArg any]];

  [target setRequestedPermissions:[NSSet setWithObjects:@"public_profile", @"read_stream", nil]];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  #pragma clang diagnostic pop

  [target verify];
}

// verify that a reauth for already granted permissions is not treated as a cancellation.
- (void)testOpenURLReauthNoPermissionsIsNotCancelled
{
  // XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile", @"read_stream"]
                                                              declinedPermissions:@[]
                                                               expiredPermissions:@[]
                                                                            appID:@""
                                                                           userID:@""
                                                                   expirationDate:nil
                                                                      refreshDate:nil
                                                         dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:existingToken];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile,read_stream&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  // Use OCMock to verify the validateReauthentication: call and verify the result there.
  id target = [OCMockObject partialMockForObject:[[FBSDKLoginManager alloc] init]];
  [[[target stub] andDo:^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKLoginManagerLoginResult *result;
    [invocation getArgument:&result atIndex:3];
    XCTAssertFalse(result.isCancelled);
    XCTAssertNotNil(result.token);
  }] validateReauthentication:[OCMArg any] withResult:[OCMArg any]];

  [target setRequestedPermissions:nil];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  #pragma clang diagnostic pop

  [target verify];
}

- (void)testOpenURLWithBadChallenge
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"
                                    challenge:@"someotherchallenge"];
  FBSDKLoginManager *target = [self loginManagerExpectingChallenge];
  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNotNil(error);
    XCTAssertNil(result.token);
    [expectation fulfill];
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

- (void)testOpenURLWithNoChallengeAndError
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithParameters:@"error=some_error&error_code=999&error_message=Errorerror_reason=foo#_=_" joinedBy:@"?"];

  FBSDKLoginManager *target = [self loginManagerExpectingChallenge];
  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNotNil(error);
    [expectation fulfill];
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

- (void)testLoginManagerRetainsItselfForLoginMethod
{
  // Mock some methods to force an error callback.
  id FBSDKInternalUtilityMock = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[FBSDKInternalUtilityMock stub] andDo:^(NSInvocation *invocation) {
    // Nothing
  }] validateURLSchemes];
  [[[FBSDKInternalUtilityMock stub] andReturnValue:@NO] isFacebookAppInstalled];
  NSError *URLError = [[NSError alloc] initWithDomain:FBSDKErrorDomain code:0 userInfo:nil];
  [[FBSDKInternalUtilityMock stub] appURLWithHost:OCMOCK_ANY
                                             path:OCMOCK_ANY
                                  queryParameters:OCMOCK_ANY
                                            error:((NSError __autoreleasing **)[OCMArg setTo:URLError])];

  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  FBSDKLoginManager *manager = [FBSDKLoginManager new];
  [manager logInWithPermissions:@[@"public_profile"] fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    [expectation fulfill];
  }];
  // This makes sure that FBSDKLoginManager is retaining itself for the duration of the call
  manager = nil;
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testCallingLoginWhileAnotherLoginHasNotFinishedNoOps
{
  // Mock some methods to force a SafariVC load
  id FBSDKInternalUtilityMock = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[FBSDKInternalUtilityMock stub] andDo:^(NSInvocation *invocation) {
    // Nothing
  }] validateURLSchemes];
  [[[FBSDKInternalUtilityMock stub] andReturnValue:@NO] isFacebookAppInstalled];

  __block int loginCount = 0;
  FBSDKLoginManager *manager = [OCMockObject partialMockForObject:[FBSDKLoginManager new]];
  [[[(id)manager stub] andDo:^(NSInvocation *invocation) {
    loginCount++;
  }] logIn];
  [manager logInWithPermissions:@[@"public_profile"] fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    // This will never be called
    XCTFail(@"Should not be called");
  }];

  [manager logInWithPermissions:@[@"public_profile"] fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    // This will never be called
    XCTFail(@"Should not be called");
  }];

  XCTAssertEqual(loginCount, 1);
}

- (void)testLoginParams
{
  id FBSDKInternalUtilityMock = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[FBSDKInternalUtilityMock stub] andDo:^(NSInvocation *invocation) {
    // Nothing
  }] validateURLSchemes];
  FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
  NSDictionary *params = [loginManager logInParametersWithPermissions:[NSSet setWithArray:@[@"public_profile", @"email"]] serverConfiguration:nil];
  long long cbt = [params[@"cbt"] longLongValue];
  long long currentMilliseconds = round(1000 * [NSDate date].timeIntervalSince1970);
  XCTAssertEqualWithAccuracy(cbt, currentMilliseconds, 500);
  XCTAssertEqualObjects(params[@"client_id"], @"7391628439");
  XCTAssertEqualObjects(params[@"response_type"], @"token_or_nonce,signed_request,graph_domain");
  XCTAssertEqualObjects(params[@"redirect_uri"], @"fbconnect://success");
  XCTAssertEqualObjects(params[@"display"], @"touch");
  XCTAssertEqualObjects(params[@"sdk"], @"ios");
  XCTAssertEqualObjects(params[@"return_scopes"], @"true");
  XCTAssertEqual(params[@"auth_type"], FBSDKLoginAuthTypeRerequest);
  XCTAssertEqualObjects(params[@"fbapp_pres"], @0);
  XCTAssertEqualObjects(params[@"ies"], [FBSDKSettings isAutoLogAppEventsEnabled] ? @1 : @0);
}

- (void)testlogInParametersFromURL
{
  NSURL *url = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22%7B%5C%22granted_scopes%5C%22%3A%5C%22public_profile%5C%22%2C%5C%22denied_scopes%5C%22%3A%5C%22%5C%22%2C%5C%22signed_request%5C%22%3A%5C%22ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0%5C%22%2C%5C%22nonce%5C%22%3A%5C%22someNonce%5C%22%2C%5C%22data_access_expiration_time%5C%22%3A%5C%221607374566%5C%22%2C%5C%22expires_in%5C%22%3A%5C%225183401%5C%22%7D%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];

  NSDictionary *params = [loginManager logInParametersFromURL:url];

  XCTAssertNotNil(params);
  XCTAssertEqualObjects(params[@"nonce"], @"someNonce");
  XCTAssertEqualObjects(params[@"granted_scopes"], @"public_profile");
  XCTAssertEqualObjects(params[@"denied_scopes"], @"");
}

- (void)testLogInWithURLFailWithInvalidLoginData
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSURL *urlWithInvalidLoginData = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22invalid%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    if (error) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [loginManager logInWithURL:urlWithInvalidLoginData handler:handler];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testLogInWithURLFailWithNoLoginData
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  NSURL *urlWithNoLoginData = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22some_param%22%3A%22some_value%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    if (error) {
      XCTAssertNil(result);
      [expectation fulfill];
    } else {
      XCTFail(@"Should have error");
    }
  };

  [loginManager logInWithURL:urlWithNoLoginData handler:handler];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

@end
