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

#import <UIKit/UIKit.h>

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKLoginManager+Internal.h"
#import "FBSDKLoginManagerLoginResult.h"
#import "FBSDKLoginUtilityTests.h"

static NSString *const kFakeAppID = @"7391628439";

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

- (NSURL *)authorizeURLWithFragment:(NSString *)fragment
{
  return [self authorizeURLWithParameters:fragment joinedBy:@"#"];
}

// verify basic case of first login and getting granted and declined permissions (is not classified as cancelled)
- (void)testOpenURLAuth
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
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
  XCTAssertTrue([target application:nil openURL:url sourceApplication:nil annotation:nil]);
  FBSDKAccessToken *actualTokenAfterCancel = [FBSDKAccessToken currentAccessToken];
  XCTAssertEqualObjects(tokenAfterAuth, actualTokenAfterCancel);
}

// verify basic case of first login and no declined permissions.
- (void)testOpenURLAuthNoDeclines
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  FBSDKAccessToken *actualToken = [FBSDKAccessToken currentAccessToken];
  XCTAssertTrue([actualToken.userID isEqualToString:@"123"], @"failed to parse userID");
  XCTAssertTrue([actualToken.permissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
  NSSet *expectedDeclined = [NSSet set];
  XCTAssertEqualObjects(actualToken.declinedPermissions, expectedDeclined, @"unexpected permissions");
}

// verify a cancellation of reauth.
- (void)testOpenURLReauthCancel
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile"]
                                                              declinedPermissions:nil
                                                                            appID:nil
                                                                           userID:nil
                                                                   expirationDate:nil
                                                                      refreshDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:existingToken];
  // receive url with no additional granted scopes and a denial (as if they asked user_likes and user said no).
  // and verify it's treated as a cancellation.
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=user_likes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManagerRequestTokenHandler handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertTrue(result.isCancelled);
    [expectation fulfill];
  };
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
  [target setHandler:handler];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

// verify that recentlyDeclined is a subset of requestedPermissions (i.e., other declined permissions are not in recentlyDeclined)
- (void)testOpenURLRecentlyDeclined
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed auth"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  // receive url with denied_scopes more than what was requested.
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=user_friends,user_likes&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManagerRequestTokenHandler handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertFalse(result.isCancelled);
    XCTAssertEqualObjects(result.declinedPermissions, [NSSet setWithObject:@"user_friends"]);
    NSSet *expectedDeclinedPermissions = [NSSet setWithObjects:@"user_friends", @"user_likes", nil];
    XCTAssertEqualObjects(result.token.declinedPermissions, expectedDeclinedPermissions);
    XCTAssertEqualObjects(result.grantedPermissions, [NSSet setWithObject:@"public_profile"]);
    [expectation fulfill];
  };
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
  [target setRequestedPermissions:[NSSet setWithObject:@"user_friends"]];
  [target setHandler:handler];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

// verify that a reauth that returns other grants on the wire but not what was requested, is classified as a cancel.
- (void)testOpenURLReauthOtherGrantsButStillCancelled
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile"]
                                                              declinedPermissions:nil
                                                                            appID:nil
                                                                           userID:nil
                                                                   expirationDate:nil
                                                                      refreshDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:existingToken];
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile,read_stream&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
  [target setRequestedPermissions:[NSSet setWithObject:@"email"]];
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertTrue(result.isCancelled);
    XCTAssertEqualObjects(existingToken, [FBSDKAccessToken currentAccessToken]);
    [expectation fulfill];
  }];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

//verify that a reauth for already granted permissions is not treated as a cancellation.
- (void)testOpenURLReauthSamePermissionsIsNotCancelled
{
//  XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile", @"read_stream"]
                                                              declinedPermissions:nil
                                                                            appID:nil
                                                                           userID:nil
                                                                   expirationDate:nil
                                                                      refreshDate:nil];
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
  XCTAssertTrue([target application:nil openURL:url sourceApplication:nil annotation:nil]);
  [target verify];
}

- (void)testInvalidPermissions
{
  FBSDKLoginManager *target = [[FBSDKLoginManager alloc] init];
  NSArray *publishPermissions = @[@"publish_actions", @"manage_notifications"];
  NSArray *readPermissions = @[@"user_birthday", @"user_hometown"];
  XCTAssertThrowsSpecificNamed([target logInWithPublishPermissions:@[[publishPermissions componentsJoinedByString:@","]] handler:NULL],
                               NSException,
                               NSInvalidArgumentException);
  XCTAssertThrowsSpecificNamed([target logInWithPublishPermissions:readPermissions handler:NULL], NSException, NSInvalidArgumentException);
  XCTAssertThrowsSpecificNamed([target logInWithReadPermissions:@[[readPermissions componentsJoinedByString:@","]] handler:NULL],
                               NSException,
                               NSInvalidArgumentException);
  XCTAssertThrowsSpecificNamed([target logInWithReadPermissions:publishPermissions handler:NULL], NSException, NSInvalidArgumentException);
}

@end
