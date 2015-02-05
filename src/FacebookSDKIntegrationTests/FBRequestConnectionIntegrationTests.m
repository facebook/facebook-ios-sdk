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

#import "FBAccessTokenData.h"
#import "FBError.h"
#import "FBIntegrationTests.h"
#import "FBRequest.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequestConnection.h"
#import "FBSession+Internal.h"
#import "FBTestBlocker.h"
#import "FBTestUserSession.h"

#if defined(FACEBOOKSDK_SKIP_REQUEST_CONNECTION_TESTS)

#pragma message ("warning: Skipping FBRequestConnectionIntegrationTests")

#else

@interface FBRequestConnectionDelegateProgressTest : NSObject <FBRequestConnectionDelegate>
@property (nonatomic) NSUInteger beginLoadingInvocationCount;
@property (nonatomic) NSUInteger finishLoadingInvocationCount;
@property (nonatomic, copy, readonly) NSArray *errors;

@property (nonatomic) NSUInteger progressInvocationCount;
@property (nonatomic, getter=isComplete) BOOL complete;

@property (nonatomic, getter=isCached) BOOL cached;
@end

@implementation FBRequestConnectionDelegateProgressTest {
@private
    FBTestBlocker *_blocker;
    NSMutableArray *_errors;
}

- (instancetype)initWithBlocker:(FBTestBlocker *)blocker {
    if ((self = [super init]) != nil) {
        _blocker = [blocker retain];
        _errors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_blocker release];
    [_errors release];
    [super dealloc];
}

- (void)requestConnectionWillBeginLoading:(FBRequestConnection *)connection
                                fromCache:(BOOL)isCached {
    _cached = isCached;
    _beginLoadingInvocationCount++;
}

- (void)requestConnectionDidFinishLoading:(FBRequestConnection *)connection
                                fromCache:(BOOL)isCached {

    NSAssert(self.isCached == isCached, @"The start and end cache parameters should be the same.");

    _finishLoadingInvocationCount++;
    [_blocker signal];
}

- (void)requestConnection:(FBRequestConnection *)connection
         didFailWithError:(NSError *)error {
    [_errors addObject:error ? : [NSNull null]];
}

- (void)     requestConnection:(FBRequestConnection *)connection
willRetryWithRequestConnection:(FBRequestConnection *)retryConnection {
}

- (void)requestConnection:(FBRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    _progressInvocationCount++;
    _complete = totalBytesWritten == totalBytesExpectedToWrite;
}
@end

#pragma mark -

@interface FBRequestConnectionIntegrationTests : FBIntegrationTests
@end

@implementation FBRequestConnectionIntegrationTests

- (void)testCancelInvokesHandler {
    FBRequest *request = [[[FBRequest alloc] initWithSession:self.defaultTestSession graphPath:@"me"] autorelease];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block int count = 0;
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        XCTAssertEqual(FBErrorOperationCancelled, error.code, @"Expected FBErrorOperationCancelled code for error:%@", error);
        XCTAssertEqual(++count, 1, @"Expected handler to only be called once");
        [blocker signal];
    }];
    [connection start];
    [connection cancel];
    
    XCTAssertTrue([blocker waitWithTimeout:10], @" handler was not invoked");
    
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
    FBTestUserSession *session = [self defaultTestSession];
    session.forceAccessTokenExtension = YES;
    // Invoke shouldRefreshPermissions which has the side affect of disabling permissions refresh piggybacking for an hour.
    [session shouldRefreshPermissions];
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection start];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    [blocker release];
    
    NSArray *requests = [connection performSelector:@selector(requests)];

    // Therefore, only expect the the token refresh piggyback in addition to the original request for /me
    NSUInteger count = requests.count;
    XCTAssertEqual(2u, count, @"unexpected number of piggybacks");
    
    [connection release];
}

- (void)testWillPiggybackPermissionsRefresh
{
    FBTestUserSession *session = [self defaultTestSession];
    session.forceAccessTokenExtension = YES;
    // verify session's permissions refresh date is initially in the past.
    XCTAssertEqual([NSDate distantPast], session.accessTokenData.permissionsRefreshDate, @"session permission refresh date does not match");
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection start];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    [blocker release];
    
    NSArray *requests = [connection performSelector:@selector(requests)];

    // Expect the token refresh and permission refresh to be piggybacked.
    NSUInteger count = requests.count;
    XCTAssertEqual(3u, count, @"unexpected number of piggybacks");
    
    [connection release];
    
    XCTAssertTrue([session.accessTokenData.permissionsRefreshDate timeIntervalSinceNow]> -3, @"session permission refresh date should be within a few seconds of now");
}

// a test to make sure the permissions refresh request will no-op
// if the session had been closed.
- (void)testPiggybackPermissionsRefreshNoopForClosedSession
{
    id session = [OCMockObject partialMockForObject:[self defaultTestSession]];
    [session setTreatReauthorizeAsCancellation:YES];

    //partial mock the session so we can make sure session is closed and `handleRefreshPermissions` should do nothing.
    [[[session stub] andDo:^(NSInvocation *invocation) {
        XCTAssertFalse([session isOpen], @"session should not be open at this point!");
    }] handleRefreshPermissions:[OCMArg any]];

    // verify session's permissions refresh date is initially in the past.
    XCTAssertEqual([NSDate distantPast], [session accessTokenData].permissionsRefreshDate, @"session permission refresh date does not match");

    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];

    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        XCTAssertTrue(!error, @"got unexpected error");
        XCTAssertNotNil(result, @"didn't get expected result");
        [blocker signal];
        // Close the session, which should result in the piggyback handlers doing nothing!
        [session closeAndClearTokenInformation];
    }];
    [connection start];

    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    [blocker release];
    [connection release];

    XCTAssertTrue([[session accessTokenData].permissionsRefreshDate timeIntervalSinceNow]> -3, @"session permission refresh date should be within a few seconds of now");
}

- (void)testCachedRequests
{
    FBTestBlocker *blocker1 = [[FBTestBlocker alloc] init];
    FBTestBlocker *blocker2 = [[FBTestBlocker alloc] init];

    
    FBSession *session = [self defaultTestSession];
    
    // here we just want to seed the cache, by identifying the cache, and by choosing not to consult the cache
    FBRequestConnectionDelegateProgressTest *progress = [[FBRequestConnectionDelegateProgressTest alloc] initWithBlocker:blocker2];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];    
    FBRequest *request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];

    connection.delegate = progress;
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker1]];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:NO];
    
    [blocker1 wait];
    XCTAssertTrue([blocker2 waitWithTimeout:3], @"blocker timed out -- should have been fast... only waiting for the run loop to turn");
    
    XCTAssertFalse(connection.isResultFromCache, @"Should not have cached, and should have fetched from server");

    XCTAssertTrue(progress.beginLoadingInvocationCount == 1, @"delegate's begin method not called exactly once");
    XCTAssertTrue(progress.finishLoadingInvocationCount == 1, @"delegate's finish method not called exactly once");
    XCTAssertTrue(progress.errors.count == 0, @"unexpected error(s) in connection :%@", progress.errors);
    XCTAssertFalse(progress.isCached, @"The first request in the cache test should not be a cached result.");

    connection.delegate = nil;
    [progress release];
    [connection release];
    [blocker1 release];
    [blocker2 release];
    
    __block BOOL completedWithoutBlocking = NO;

    blocker1 = [[FBTestBlocker alloc] init];
    blocker2 = [[FBTestBlocker alloc] init];

    // here we expect to complete on the cache, so we will confirm that
    progress = [[FBRequestConnectionDelegateProgressTest alloc] initWithBlocker:blocker2];
    connection = [[FBRequestConnection alloc] init];
    request = [[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];

    connection.delegate = progress;
    [request.parameters setObject:@"id,first_name" forKey:@"fields"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        XCTAssertNotNil(result, @"Expected a successful result");
        completedWithoutBlocking = YES;
        [blocker1 signal];
    }];
    [connection startWithCacheIdentity:@"FBUnitTests"
                 skipRoundtripIfCached:YES];
    
    // Note despite the skipping of round trip, the completion handler is still dispatched async since we
    // started using the Task framework in FBRequestConnection.
    XCTAssertTrue([blocker1 waitWithTimeout:3], @"blocker timed out");
    XCTAssertTrue([blocker2 waitWithTimeout:3], @"blocker timed out -- should have been fast... only waiting for the run loop to turn");

    XCTAssertTrue(progress.beginLoadingInvocationCount == 1, @"delegate's begin method not called exactly once");
    XCTAssertTrue(progress.finishLoadingInvocationCount == 1, @"delegate's finish method not called exactly once");
    XCTAssertTrue(progress.errors.count == 0, @"unexpected error(s) in connection :%@", progress.errors);
    XCTAssertTrue(progress.isCached, @"The second request in the cache test should be a cached result.");

    // should have completed successfully by here
    XCTAssertTrue(completedWithoutBlocking, @"Should have called the handler, due to cache hit");
    XCTAssertTrue(connection.isResultFromCache, @"Should not have fetched from server");
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
    
    FBSession *session = [self loginSession:[self getTestSessionWithPermissions:@[@"read_stream",@"publish_actions"]]];
    
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
        XCTAssertNotNil(result, @"should have a result here: Handler 1");
        XCTAssertNil(error, @"should not have an error here: Handler 1");
        [fbids addObject: [[result objectForKey:@"id"] description]];
        [blocker signal];
    };
    
    // this creates three objects
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    [connection addRequest:request completionHandler:handler];
    [connection addRequest:request completionHandler:handler];
    [connection addRequest:request completionHandler:handler];
    [connection start];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    
    if (fbids.count != 3) {
        XCTAssertTrue(fbids.count == 3, @"wrong number of fbids, aborting test");
        // Things are bad. Continuing isn't going to make them better, and might throw exceptions.
        return;
    }
    
    blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:3];
    
    connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *deleteRequest = [[FBRequest alloc] initWithSession:session
                                                        graphPath:fbids[2]
                                                       parameters:nil
                                                       HTTPMethod:@"delete"];
    [connection addRequest:deleteRequest
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             XCTAssertNotNil(result, @"should have a result here: Handler 2");
             XCTAssertNil(error, @"should not have an error here: Handler 2");
             [blocker signal];             
         }];
    
    deleteRequest = [[FBRequest alloc] initWithSession:session
                                             graphPath:fbids[1]
                                            parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"delete", @"method",
                                                        nil]
                                            HTTPMethod:nil];
    [connection addRequest:deleteRequest
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             XCTAssertNotNil(result, @"should have a result here: Handler 3");
             XCTAssertNil(error, @"should not have an error here: Handler 3");
             [blocker signal];             
         }];
    
    __block NSString *newfbid = nil;
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        XCTAssertNotNil(result, @"should have a result here: Handler 4");
        XCTAssertNil(error, @"should not have an error here: Handler 4");
        if (result) {
            newfbid = [(NSString *)[result objectForKey:@"id"] retain];
        }
        [blocker signal];
    }];
    
    // these deletes two and adds one
    [connection start];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    // update the fbids array from the batch (deleting the 2 and adding the one).
    [fbids removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]];
    [fbids addObject:newfbid];
    [newfbid release];

    if (fbids.count != 2) {
        XCTAssertTrue(fbids.count == 2, @"wrong number of fbids, aborting test");
        // Things are bad. Continuing isn't going to make them better, and might throw exceptions.
        return;
    }
    
    blocker = [[[FBTestBlocker alloc] initWithExpectedSignalCount:2] autorelease];
    
    // delete
    request = [[[FBRequest alloc] initWithSession:session
                                        graphPath:fbids[0]
                                       parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"delete", @"method",
                                                   nil]
                                       HTTPMethod:nil] autorelease];
    [request startWithCompletionHandler:
     ^(FBRequestConnection *innerConnection, id result, NSError *error) {
         XCTAssertNotNil(result, @"should have a result here: Handler 5");
         XCTAssertNil(error, @"should not have an error here: Handler 5");
         [blocker signal];
     }];
    // delete
    request = [[[FBRequest alloc] initWithSession:session
                                        graphPath:fbids[1]
                                       parameters:nil 
                                       HTTPMethod:@"delete"] autorelease];
    [request startWithCompletionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        XCTAssertNotNil(result, @"should have a result here: Handler 6");
        XCTAssertNil(error, @"should not have an error here: Handler 6");
        [blocker signal];
    }];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
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
    
    FBSession *session = [self loginSession:[self getTestSessionWithPermissions:@[@"publish_actions"]]];
    
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
        XCTAssertNotNil(result, @"should have a result here: Post Request handler");
        XCTAssertNil(error, @"should not have an error here: Post Request handler");
        [fbids addObject: [[result objectForKey:@"id"] description]];
        [blocker signal];
    }];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
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
        XCTAssertNil(result, @"should not have a result here: Dupe-Delete Handler");
        XCTAssertNotNil(error, @"should have an error here: Dupe-Delete Handler");
        [blocker signal];
    }];
    
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
    [blocker release];
}

- (void)testMultipleSelectionWithDependenciesBatch {
    NSArray *sessions = [self getTestSessionsWithPermissions:@[] count:2];
    FBSession *session1 = [self loginSession:sessions[0]];
    FBSession *session2 = [self loginSession:sessions[1]];

    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:2];

    NSString *graphPath = [NSString stringWithFormat:@"?ids=%@,%@&fields=id",
                           session1.accessTokenData.userID,
                           session2.accessTokenData.userID];
    FBRequest *parent = [[[FBRequest alloc] initWithSession:session1 graphPath:graphPath] autorelease];
    [connection addRequest:parent
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             XCTAssertNil(error, @"unexpected error in parent request :%@", error);
             [blocker signal];
         } batchEntryName:@"getactions"];

    FBRequest *child = [[[FBRequest alloc] initWithSession:session1 graphPath:@"?ids={result=getactions:$.*.id}"] autorelease];
    [connection addRequest:child
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             XCTAssertNil(error, @"unexpected error in child request :%@", error);
             XCTAssertNotNil(result, @"expected results");
             [blocker signal];
         } batchEntryName:nil];
    [connection start];
    [connection release];

    XCTAssertTrue([blocker waitWithTimeout:60], @"blocker timed out");
}

- (void)testProgressReporting {
    FBTestUserSession *session = [self defaultTestSession];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    FBTestBlocker *blocker1 = [[FBTestBlocker alloc] init];
    FBTestBlocker *blocker2 = [[FBTestBlocker alloc] init];

    FBRequestConnectionDelegateProgressTest *progress = [[FBRequestConnectionDelegateProgressTest alloc] initWithBlocker:blocker2];
    connection.delegate = progress;

    FBRequest *request = [[FBRequest alloc] initWithSession:session graphPath:@"me"];
    [connection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:blocker1]];
    [connection start];

    [blocker1 wait];
    XCTAssertTrue([blocker2 waitWithTimeout:2], @"blocker timed out -- should have been fast... only waiting for the run loop to turn");

    XCTAssertTrue(progress.beginLoadingInvocationCount == 1, @"delegate's begin method not called exactly once");
    XCTAssertTrue(progress.finishLoadingInvocationCount == 1, @"delegate's finish method not called exactly once");
    XCTAssertTrue(progress.errors.count == 0, @"unexpected error(s) in connection :%@", progress.errors);

    XCTAssertTrue(progress.progressInvocationCount > 0, @"delegate not sent any progress callbacks");
    XCTAssertTrue(progress.complete, @"connection completed but didn't notify delegate");

    [connection setDelegate:nil];
    [request release];
    [progress release];
    [blocker2 release];
    [blocker1 release];
    [connection release];
}

- (void)testInvalidUTF8Response {
    // there is nothing in this byte sequence that is valid UTF-8
    const unsigned char invalidCharacters[] = {
        0xF0, 0x82, 0x82, 0xAC, // overlong Euro character
        0xC0, 0xF5,             // invalid bytes
        0x00,                   // NUL
        0xE8, 0x40, 0x41        // three byte sequence without continuation bytes
    };
    [self verifyInvalidUTF8ResponseFails:invalidCharacters length:sizeof(invalidCharacters)];

    // mostly valid JSON, but \350 (i.e. 0xE8) begins a 3-byte sequence but has no continuation characters
    const char *invalidJSON = "{ body: \"\350test\" }";
    [self verifyInvalidUTF8ResponseFails:invalidJSON length:strlen(invalidJSON)];
}

- (void)verifyInvalidUTF8ResponseFails:(const void *)bytes length:(NSUInteger)length {
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    NSData *data = [NSData dataWithBytes:bytes length:length];

    NSError *error = nil;
    NSArray *response = [connection parseJSONResponse:data error:&error statusCode:200];

    XCTAssertEqual([error code], FBErrorUnexpectedResponse, "The byte sequence above should be unexpected.");
    XCTAssertNil(response, @"The data passed was not valid JSON.");

    [connection release];
}

@end

#endif
