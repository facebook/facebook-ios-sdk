/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>

#import <XCTest/XCTest.h>

#import "FBAccessTokenData.h"
#import "FBIntegrationTests.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBTestUsersManager.h"

@interface FBTestUsersManagersIntegrationTests : FBIntegrationTests

@end

@implementation FBTestUsersManagersIntegrationTests

- (NSUInteger)countTestUsers
{
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];

    NSDictionary *parameters = @{
                                 @"access_token" : [NSString stringWithFormat:@"%@|%@", [self testAppId], [self testAppSecret]]
                                 };

    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:[NSString stringWithFormat:@"%@/accounts/test-users", [self testAppId]]
                                                 parameters:parameters
                                                 HTTPMethod:nil];

    __block NSUInteger count = 0;
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        XCTAssertNotNil(result, @"nil result");
        XCTAssertNil(error, @"non-nil error");
        XCTAssertTrue([result isKindOfClass:[NSDictionary class]], @"not dictionary");

        id data = [result objectForKey:@"data"];
        XCTAssertTrue([data isKindOfClass:[NSArray class]], @"not array");

        count = [data count];

        [blocker signal];
    }];

    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    [blocker release];
    [request release];
    return count;
}


#pragma mark - Tests
- (void)testTestUserManagerDoesntCreateUnnecessaryUsers
{
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    FBTestUsersManager *testAccountsManager = [FBTestUsersManager sharedInstanceForAppId:[self testAppId] appSecret:[self testAppSecret]];
    [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:nil
                                                        createIfNotFound:YES
                                                       completionHandler:^(NSArray *tokens, NSError *error) {
                                                   [blocker signal];

                                               }];
    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");
    [blocker release];

    NSUInteger startingUserCount = [self countTestUsers];

    blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:nil
                                                        createIfNotFound:YES
                                                       completionHandler:^(NSArray *tokens, NSError *error) {
                                                   [blocker signal];

                                               }];
    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");
    [blocker release];

    NSUInteger endingUserCount = [self countTestUsers];

    XCTAssertEqual(startingUserCount, endingUserCount, @"differing counts");
}

- (void)testTestUserManagerCreateNewUserAndDelete
{
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    FBTestUsersManager *testAccountsManager = [FBTestUsersManager sharedInstanceForAppId:[self testAppId] appSecret:[self testAppSecret]];
    // make sure there is no test user with user_likes, user_birthday, email, user_friends, read_stream
    NSArray *uniquePermissions = @[@"user_likes", @"user_birthday", @"email", @"user_friends", @"read_stream"];
    [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:@[uniquePermissions]
                                                        createIfNotFound:NO
                                                       completionHandler:^(NSArray *tokens, NSError *error) {
                                                   XCTAssertEqual([NSNull null], tokens[0], @"did not expect to fetch a user account %@. You should probably delete this test account or verify the createIfNotFound flag is respected", ((FBAccessTokenData *)tokens[0]).userID);
                                                   [blocker signal];
                                               }];
    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");
    [blocker release];

    // now allow the creation:
    blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    __block FBAccessTokenData* tokenData;
    [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:@[uniquePermissions]
                                                        createIfNotFound:YES
                                                       completionHandler:^(NSArray *tokens, NSError *error) {
                                                           XCTAssertNil(error);
                                                           XCTAssertNotEqual([NSNull null], tokens[0], @"should have created a new test user");
                                                           XCTAssertTrue([tokens[0] isKindOfClass:[FBAccessTokenData class]]);
                                                           tokenData = [tokens[0] retain];
                                                           [blocker signal];
                                                       }];
    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out fetching test user");
    [blocker release];
    XCTAssertTrue(tokenData.userID.length > 0, @"new test user doesn't have an id");

    //now delete it
    blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];


    [testAccountsManager removeTestAccount:tokenData.userID completionHandler:^(NSError *error) {
        NSString *appAccessToken = [NSString stringWithFormat:@"%@|%@", [self testAppId], [self testAppSecret]];
        //verify they no longer exist.
        [[FBRequest requestWithGraphPath:tokenData.userID
                              parameters:@{@"access_token" : appAccessToken }
                              HTTPMethod:nil]
         startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *verificationError) {
             XCTAssertNotNil(verificationError, @"expected error and not result %@", result);
             [blocker signal];
         }];
    }];

    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out deleting test user");
    [tokenData release];
    [blocker release];
}
@end
