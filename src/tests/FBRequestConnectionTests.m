/*
 * Copyright 2012 Facebook
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

#import "FBRequestConnectionTests.h"
#import "FBTestSession.h"
#import "FBTestSession+Internal.h"
#import "FBRequestConnection.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"

#if defined(FBIOSSDK_SKIP_REQUEST_CONNECTION_TESTS)

#pragma message ("warning: Skipping FBRequestConnectionTests")

#else

@implementation FBRequestConnectionTests

- (void)testConcurrentRequests
{
    __block FBTestBlocker *blocker1 = [[FBTestBlocker alloc] init];
    __block FBTestBlocker *blocker2 = [[FBTestBlocker alloc] init];
    __block FBTestBlocker *blocker3 = [[FBTestBlocker alloc] init];
    
    [[FBRequest requestForMeWithSession:self.defaultTestSession] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker1]];
    [[FBRequest requestForMeWithSession:self.defaultTestSession] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker2]];
    [[FBRequest requestForMeWithSession:self.defaultTestSession] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker3]];

    [blocker1 wait];
    [blocker2 wait];
    [blocker3 wait];
    
    [blocker1 release];
    [blocker2 release];
    [blocker3 release];
}

- (void)testWillPiggybackTokenExtensionIfNeeded
{
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    // Note that we don't care if the actual token extension request succeeds or not.
    // We only care that we try it. 
    session.forceAccessTokenRefresh = YES;

    FBRequest *request = [FBRequest requestForMeWithSession:session];

    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:self.handlerExpectingSuccess];
    [connection start];
    // We don't need to wait for the requests to complete to determine success.

    NSArray *requests = [connection performSelector:@selector(requests)];
    STAssertTrue(requests.count == 2, @"didn't piggyback");
    
    [connection release];
}

- (void)testWillNotPiggybackIfWouldExceedBatchSize
{
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    session.forceAccessTokenRefresh = YES;

    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    const int batchSize = 50;
    for (int i = 0; i < batchSize; ++i) {
        FBRequest *request = [FBRequest requestForMeWithSession:session];
        
        // Minimize traffic by just getting our id.
        [request.parameters setObject:@"id" forKey:@"fields"];
        
        [connection addRequest:request completionHandler:self.handlerExpectingSuccess];
    }
    [connection start];
    // We don't need to wait for the requests to complete to determine success.
    
    NSArray *requests = [connection performSelector:@selector(requests)];
    STAssertTrue(requests.count == batchSize, @"piggybacked but shouldn't have");
    [connection release];
}
    
- (void)testNoRequests
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    STAssertThrows([connection start], @"should throw");
    [connection release];
}

- (void)testCachedRequests
{
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    session.forceAccessTokenRefresh = YES;
    
    // here we just want to seed the cache, by identifying the cache, and by choosing not to consult the cache
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];    
    FBRequest *request = [FBRequest requestForMeWithSession:session];
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:NO];
    
    [blocker wait];
    
    [connection release];
    [blocker release];
    
    __block BOOL completedWithoutBlocking = NO;
    
    // here we expect to complete on the cache, so we will confirm that
    connection = [[FBRequestConnection alloc] init];    
    request = [FBRequest requestForMeWithSession:session];
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"Expected a successful result");
        completedWithoutBlocking = YES;
    }];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:YES];
    
    // should have completed successfully by here
    STAssertTrue(completedWithoutBlocking, @"Should have called the handler, due to cache hit");
    [connection release];

}

@end

#endif
