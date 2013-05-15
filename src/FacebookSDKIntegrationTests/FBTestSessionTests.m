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

#import "FBTestSessionTests.h"
#import "FBTEstSession.h"
#import "FBTestBlocker.h"
#import "FBRequest.h"
#import "FBAccessTokenData.h"
#import <CommonCrypto/CommonDigest.h>

#if defined(FACEBOOKSDK_SKIP_TEST_SESSION_TESTS)

#pragma message ("warning: Skipping FBTestSessionTests")

#else

@interface FBTestSessionTests ()

- (int)countTestUsers;

@end

@implementation FBTestSessionTests

- (int)countTestUsers 
{
    // Get the number of test users. Use an FBTestSession without a user (and thus no
    // access token), so we can specify our own access token.
    FBTestSession *fqlSession = [FBTestSession sessionWithSharedUserWithPermissions:nil];
    STAssertNil(fqlSession.accessTokenData, @"non-nil access token");
    
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    NSString *fqlQuery = [NSString stringWithFormat:@"SELECT id FROM test_account WHERE app_id = %@", fqlSession.testAppID];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                fqlQuery, @"q",
                                fqlSession.appAccessToken, @"access_token", 
                                nil];   
    
    __block int count = 0;
    FBRequest *request = [[[FBRequest alloc] initWithSession:fqlSession
                                                   graphPath:@"fql"
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];
    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"nil result");
        STAssertNil(error, @"non-nil error");
        STAssertTrue([result isKindOfClass:[NSDictionary class]], @"not dictionary");
        
        id data = [result objectForKey:@"data"];
        STAssertTrue([data isKindOfClass:[NSArray class]], @"not array");
        
        count = [data count];
        
        [blocker signal];
    }];
     
    [blocker wait];
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
    
    STAssertEquals(startingUserCount, endingUserCount, @"differing counts");
    [session close];
}

@end

#endif
