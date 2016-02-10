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

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKTestUsersManager.h>

#import <XCTest/XCTest.h>

#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"

@interface FBSDKTestUsersManagersIntegrationTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKTestUsersManagersIntegrationTests

- (NSUInteger)countTestUsers
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"expected callback"];

  NSString *token = [NSString stringWithFormat:@"%@|%@", [self testAppID], [self testAppSecret]];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/accounts/test-users", [self testAppID]]
                                                                 parameters:@{ @"fields": @"id" }
                                                                tokenString:token
                                                                    version:nil
                                                                 HTTPMethod:nil];

  __block NSUInteger count = 0;
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNotNil(result, @"nil result");
    XCTAssertNil(error, @"non-nil error");
    XCTAssertTrue([result isKindOfClass:[NSDictionary class]], @"not dictionary");

    id data = [result objectForKey:@"data"];
    XCTAssertTrue([data isKindOfClass:[NSArray class]], @"not array");

    count = [data count];

    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  return count;
}


#pragma mark - Tests
- (void)testPermissionFetch
{
  __block FBSDKAccessToken *tokenWithLikes, *tokenWithEmail;
  XCTestExpectation *fetchUsersExpectation = [self expectationWithDescription:@"fetch test user"];
  FBSDKTestUsersManager *testAccountsManager = [FBSDKTestUsersManager sharedInstanceForAppID:[self testAppID] appSecret:[self testAppSecret]];
  [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:@[
                                                                             [NSSet setWithObject:@"user_likes"],
                                                                             [NSSet setWithObject:@"email"]                                                                            ]
                                                          createIfNotFound:YES
                                                         completionHandler:^(NSArray *tokens, NSError *error) {
                                                           tokenWithLikes = tokens[0];
                                                           tokenWithEmail = tokens[1];
                                                           [fetchUsersExpectation fulfill];
                                                         }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"failed to fetch test user");
  }];
  XCTestExpectation *verifyLikesPermissionExpectation = [self expectationWithDescription:@"verify user_likes"];
  XCTestExpectation *verifyEmailPermissionExpectation = [self expectationWithDescription:@"verify email"];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                     parameters:@{ @"fields" : @"permissions" }
                                    tokenString:tokenWithLikes.tokenString
                                        version:nil
                                     HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error);
    BOOL found = NO;
    for (NSDictionary *p in result[@"permissions"][@"data"]) {
      if ([p[@"permission"] isEqualToString:@"user_likes"] && [p[@"status"] isEqualToString:@"granted"]) {
        found = YES;
      }
    }
    XCTAssertTrue(found, @"Didn't find permission for %@", tokenWithLikes);
    [verifyLikesPermissionExpectation fulfill];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                     parameters:@{ @"fields" : @"permissions" }
                                    tokenString:tokenWithEmail.tokenString
                                        version:nil
                                     HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error);
    BOOL found = NO;
    for (NSDictionary *p in result[@"permissions"][@"data"]) {
      if ([p[@"permission"] isEqualToString:@"email"] && [p[@"status"] isEqualToString:@"granted"]) {
        found = YES;
      }
    }
    XCTAssertTrue(found, @"Didn't find permission for %@", tokenWithEmail);
    [verifyEmailPermissionExpectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"failed to verify test users' permissions for %@,%@", tokenWithLikes, tokenWithEmail);
  }];
}

- (void)testTestUserManagerDoesntCreateUnnecessaryUsers
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  FBSDKTestUsersManager *testAccountsManager = [FBSDKTestUsersManager sharedInstanceForAppID:[self testAppID] appSecret:[self testAppSecret]];
  [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:nil
                                                      createIfNotFound:YES
                                                     completionHandler:^(NSArray *tokens, NSError *error) {
                                                       XCTAssertNil(error);
                                                       [blocker signal];

                                                     }];
  XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");

  NSUInteger startingUserCount = [self countTestUsers];

  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:nil
                                                      createIfNotFound:YES
                                                     completionHandler:^(NSArray *tokens, NSError *error) {
                                                       XCTAssertNil(error);
                                                       [blocker signal];
                                                     }];
  XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");

  NSUInteger endingUserCount = [self countTestUsers];

  XCTAssertEqual(startingUserCount, endingUserCount, @"differing counts");
}

- (void)testTestUserManagerCreateNewUserAndDelete
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  FBSDKTestUsersManager *testAccountsManager = [FBSDKTestUsersManager sharedInstanceForAppID:[self testAppID] appSecret:[self testAppSecret]];
  // make sure there is no test user with user_likes, user_birthday, email, user_friends, read_stream
  NSSet *uniquePermissions = [NSSet setWithObjects:@"user_likes", @"user_birthday", @"email", @"user_friends", @"read_stream", nil];
  [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:@[uniquePermissions]
                                                      createIfNotFound:NO
                                                     completionHandler:^(NSArray *tokens, NSError *error) {
                                                       XCTAssertEqual([NSNull null], tokens[0], @"did not expect to fetch a user account %@. You should probably delete this test account or verify the createIfNotFound flag is respected", ((FBSDKAccessToken *)tokens[0]).userID);
                                                       [blocker signal];
                                                     }];
  XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");

  // now allow the creation:
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken* tokenData;
  [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:@[uniquePermissions]
                                                      createIfNotFound:YES
                                                     completionHandler:^(NSArray *tokens, NSError *error) {
                                                       XCTAssertNil(error);
                                                       XCTAssertNotEqual([NSNull null], tokens[0], @"should have created a new test user");
                                                       XCTAssertTrue([tokens[0] isKindOfClass:[FBSDKAccessToken class]]);
                                                       tokenData = tokens[0];
                                                       [blocker signal];
                                                     }];
  XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");
  XCTAssertTrue(tokenData.userID.length > 0, @"new test user doesn't have an id");

  //now delete it
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];

  [testAccountsManager removeTestAccount:tokenData.userID completionHandler:^(NSError *error) {
    NSString *appAccessToken = [NSString stringWithFormat:@"%@|%@", [self testAppID], [self testAppSecret]];
    //verify they no longer exist.
    [[[FBSDKGraphRequest alloc] initWithGraphPath:tokenData.userID
                                       parameters:@{@"access_token" : appAccessToken,
                                                    @"fields": @"id" }
      ]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *verificationError) {
       XCTAssertNotNil(verificationError, @"expected error and not result %@", result);
       [blocker signal];
     }];
  }];

  XCTAssertTrue([blocker waitWithTimeout:30], @"timed out deleting test user");
}
@end
