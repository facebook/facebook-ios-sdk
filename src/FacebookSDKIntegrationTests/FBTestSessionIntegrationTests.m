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

#import <CommonCrypto/CommonDigest.h>

#import "FBAccessTokenData.h"
#import "FBIntegrationTests.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBTestSession.h"

#if defined(FACEBOOKSDK_SKIP_TEST_SESSION_TESTS)

#pragma message ("warning: Skipping FBTestSessionTests")

#else

@interface FBTestSessionIntegrationTests : FBIntegrationTests
@end

@implementation FBTestSessionIntegrationTests

- (int)countTestUsers 
{
    // Get the number of test users. Use an FBTestSession without a user (and thus no
    // access token), so we can specify our own access token.
    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:nil];
    XCTAssertNil(session.accessTokenData, @"non-nil access token");
    
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                session.appAccessToken, @"access_token",
                                nil];
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                   graphPath:[NSString stringWithFormat:@"%@/accounts/test-users", session.testAppID]
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];

    __block int count = 0;
    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
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
    
    return count;
}

- (void)testSharedUserDoesntCreateUnnecessaryUsers
{
    // Create a shared user
    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:nil];
    [self loginSession:session];
    [session close];
    
    int startingUserCount = [self countTestUsers];
    
    // Try getting another shared user.
    session = [FBTestSession sessionWithSharedUserWithPermissions:nil];
    [self loginSession:session];
    
    int endingUserCount = [self countTestUsers];
    
    XCTAssertEqual(startingUserCount, endingUserCount, @"differing counts");
    [session close];
}

@end

#endif
