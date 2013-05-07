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

#import "FBRequestConnectionIntegrationTests.h"
#import "FBTestSession.h"
#import "FBTestSession+Internal.h"
#import "FBRequestConnection.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBError.h"

#if defined(FACEBOOKSDK_SKIP_REQUEST_CONNECTION_TESTS)

#pragma message ("warning: Skipping FBRequestConnectionTests")

#else

@implementation FBRequestConnectionIntegrationTests

- (void)testCancelInvokesHandler {
    FBRequest *request = [[[FBRequest alloc] initWithSession:self.defaultTestSession graphPath:@"me"] autorelease];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block int count = 0;
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertEqualObjects(FBErrorOperationCancelled, error.code, @"Expected FBErrorOperationCancelled code for error:%@", error);
        STAssertEquals(++count, 1, @"Expected handler to only be called once");
        [blocker signal];
    }];
    [connection start];
    [connection cancel];
    
    STAssertTrue([blocker waitWithTimeout:10], @" handler was not invoked");
    
    [connection release];
}

- (void)testConcurrentRequests
{
    __block FBTestBlocker *blocker1 = [[FBTestBlocker alloc] init];
    __block FBTestBlocker *blocker2 = [[FBTestBlocker alloc] init];
    __block FBTestBlocker *blocker3 = [[FBTestBlocker alloc] init];
    [[[[FBRequest alloc] initWithSession:self.defaultTestSession graphPath:@"me"] autorelease] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker1]];
    [[[[FBRequest alloc] initWithSession:self.defaultTestSession graphPath:@"me"] autorelease] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker2]];
    [[[[FBRequest alloc] initWithSession:self.defaultTestSession graphPath:@"me"] autorelease] startWithCompletionHandler:[self handlerExpectingSuccessSignaling:blocker3]];
    
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
    session.forceAccessTokenRefresh = YES;
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection start];
    
    [blocker wait];
    [blocker release];
    
    NSArray *requests = [connection performSelector:@selector(requests)];
    STAssertTrue(requests.count == 2, @"didn't piggyback");
    
    [connection release];
}

- (void)testCachedRequests
{
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    
    // here we just want to seed the cache, by identifying the cache, and by choosing not to consult the cache
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:NO];
    
    [blocker wait];
    
    STAssertFalse(connection.isResultFromCache, @"Should not have cached, and should have fetched from server");
    
    [connection release];
    [blocker release];
    
    __block BOOL completedWithoutBlocking = NO;
    
    // here we expect to complete on the cache, so we will confirm that
    connection = [[FBRequestConnection alloc] init];    
    request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"Expected a successful result");
        completedWithoutBlocking = YES;
    }];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:YES];
    
    // should have completed successfully by here
    STAssertTrue(completedWithoutBlocking, @"Should have called the handler, due to cache hit");
    STAssertTrue(connection.isResultFromCache, @"Should not have fetched from server");
    [connection release];
}

- (void)testDelete
{
    // this is a longish test, here is the breakdown:
    // 1) three objects are created in one batch
    // 2) two objects are deleted with different approaches, and one object created in the next batch
    // 3) one object is deleted
    // 4) another object is deleted
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] initWithExpectedSignalCount:3] autorelease];
    
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                   graphPath:@"me/feed"]
                          autorelease];
    
    [request.parameters setObject:@"dummy status"
                           forKey:@"name"];
    [request.parameters setObject:@"http://www.facebook.com"
                           forKey:@"link"];
    [request.parameters setObject:@"dummy description"
                           forKey:@"description"];
    [request.parameters setObject:@"post"
                           forKey:@"method"];
    
    NSMutableArray *fbids = [NSMutableArray array];
    
    FBRequestHandler handler = ^(FBRequestConnection *connection, id<FBGraphObject> result, NSError *error) {
        // There's a lot going on in this test. To make failures easier to understand, giving each
        // of the handlers a number so we can tell what failed.
        STAssertNotNil(result, @"should have a result here: Handler 1");
        STAssertNil(error, @"should not have an error here: Handler 1");
        [fbids addObject: [[result objectForKey:@"id"] description]];
        [blocker signal];
    };
    
    // this creates three objects
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    [connection addRequest:request completionHandler:handler];
    [connection addRequest:request completionHandler:handler];
    [connection addRequest:request completionHandler:handler];
    [connection start];
    
    [blocker wait];
    
    if (fbids.count != 3) {
        STAssertTrue(fbids.count == 3, @"wrong number of fbids, aborting test");
        // Things are bad. Continuing isn't going to make them better, and might throw exceptions.
        return;
    }
    
    blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:3];
    
    connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *deleteRequest = [[FBRequest alloc] initWithSession:session
                                                        graphPath:[fbids objectAtIndex:fbids.count-1]
                                                       parameters:nil
                                                       HTTPMethod:@"delete"];
    [connection addRequest:deleteRequest
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertNotNil(result, @"should have a result here: Handler 2");
             STAssertNil(error, @"should not have an error here: Handler 2");
             STAssertTrue(0 != fbids.count, @"not enough fbids: Handler 2");
             [fbids removeObjectAtIndex:fbids.count-1];
             [blocker signal];             
         }];
    
    deleteRequest = [[FBRequest alloc] initWithSession:session
                                             graphPath:[fbids objectAtIndex:fbids.count-1]
                                            parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"delete", @"method",
                                                        nil]
                                            HTTPMethod:nil];
    [connection addRequest:deleteRequest
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertNotNil(result, @"should have a result here: Handler 3");
             STAssertNil(error, @"should not have an error here: Handler 3");
             STAssertTrue(0 != fbids.count, @"not enough fbids: Handler 3");
             [fbids removeObjectAtIndex:fbids.count-1];
             [blocker signal];             
         }];
    
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"should have a result here: Handler 4");
        STAssertNil(error, @"should not have an error here: Handler 4");
        if (result) {
            [fbids addObject: [[result objectForKey:@"id"] description]];
        }
        [blocker signal];
    }];
    
    // these deletes two and adds one
    [connection start];
    
    [blocker wait];
    if (fbids.count != 2) {
        STAssertTrue(fbids.count == 2, @"wrong number of fbids, aborting test");
        // Things are bad. Continuing isn't going to make them better, and might throw exceptions.
        return;
    }
    
    blocker = [[[FBTestBlocker alloc] initWithExpectedSignalCount:2] autorelease];
    
    // delete
    request = [[[FBRequest alloc] initWithSession:session
                                        graphPath:[fbids objectAtIndex:fbids.count-1]
                                       parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"delete", @"method",
                                                   nil]
                                       HTTPMethod:nil] autorelease];
    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         STAssertNotNil(result, @"should have a result here: Handler 5");
         STAssertNil(error, @"should not have an error here: Handler 5");
         STAssertTrue(0 != fbids.count, @"not enough fbids: Handler 5");
         [fbids removeObjectAtIndex:fbids.count-1];
         [blocker signal];
     }];
    // delete
    request = [[[FBRequest alloc] initWithSession:session
                                        graphPath:[fbids objectAtIndex:fbids.count-1] 
                                       parameters:nil 
                                       HTTPMethod:@"delete"] autorelease];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"should have a result here: Handler 6");
        STAssertNil(error, @"should not have an error here: Handler 6");
        STAssertTrue(0 != fbids.count, @"not enough fbids: Handler 6");
        [fbids removeObjectAtIndex:fbids.count-1];
        [blocker signal];
    }];
    
    [blocker wait];
    
    STAssertTrue(fbids.count == 0, @"Our fbid collection should be empty here");
}

- (void)testNilCompletionHandler {
    /*
     Need to test that nil completion handlers don't cause crashes, and also don't prevent the request from completing.
     We'll do this via the following steps:
     1. Create a post on me/feed with a valid handler and get the id.
     2. Delete the post without a handler
     3. Try delete the post again with a valid handler and make sure we get an error since Step #2 should have deleted
     */
    
    // Step 1
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:nil];
    
    FBRequest *postRequest = [[[FBRequest alloc] initWithSession:session
                                                       graphPath:@"me/feed"]
                              autorelease];
    
    [postRequest.parameters setObject:@"dummy status"
                               forKey:@"name"];
    [postRequest.parameters setObject:@"http://www.facebook.com"
                               forKey:@"link"];
    [postRequest.parameters setObject:@"dummy description"
                               forKey:@"description"];
    [postRequest.parameters setObject:@"post"
                               forKey:@"method"];
    
    NSMutableArray *fbids = [NSMutableArray array];
    
    [postRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(result, @"should have a result here: Post Request handler");
        STAssertNil(error, @"should not have an error here: Post Request handler");
        [fbids addObject: [[result objectForKey:@"id"] description]];
        [blocker signal];
    }];
    
    [blocker wait];
    [blocker release];
    
    
    // Step 2
    
    blocker = [[FBTestBlocker alloc] init];
    FBRequest *deleteRequest = [[[FBRequest alloc] initWithSession:session
                                                         graphPath:[fbids objectAtIndex:0]
                                                        parameters:nil
                                                        HTTPMethod:@"delete"] autorelease];
    [deleteRequest startWithCompletionHandler:nil];
    // Can't signal without a handler, so just wait 2 seconds.
    [blocker waitWithTimeout:2];
    [blocker release];
    
    
    // Step 3
    
    blocker = [[FBTestBlocker alloc] init];
    deleteRequest = [[[FBRequest alloc] initWithSession:session
                                              graphPath:[fbids objectAtIndex:0]
                                             parameters:nil
                                             HTTPMethod:@"delete"] autorelease];
    [deleteRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNil(result, @"should not have a result here: Dupe-Delete Handler");
        STAssertNotNil(error, @"should have an error here: Dupe-Delete Handler");
        [blocker signal];
    }];
    
    [blocker wait];
    [blocker release];
}

@end

#endif
