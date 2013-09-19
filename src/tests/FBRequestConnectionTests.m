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

#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBAccessTokenData.h"
#import "FBRequestConnectionTests.h"
#import "FBTestSession.h"
#import "FBTestSession+Internal.h"
#import "FBRequestConnection.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequest.h"
#import "FBSession.h"
#import "FBTestBlocker.h"
#import "FBURLConnection.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBUtility.h"

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBSession (Testing)

- (BOOL)shouldExtendAccessToken;

@end

@interface FBRequestConnection (Testing)

- (FBURLConnection *)newFBURLConnection;

@end

@interface FBRequestConnectionTests() {
    id _mockFBUtility;
}
@end

@implementation FBRequestConnectionTests

- (void)setUp {
    [super setUp];
    _mockFBUtility = [[OCMockObject mockForClass:[FBUtility class]] retain];
    [[[_mockFBUtility stub] andReturn:nil] advertiserID];  //also stub advertiserID since that often hangs.
}

- (void)tearDown {
    [_mockFBUtility release];
    _mockFBUtility = nil;
    
    [super tearDown];
}

- (void)testWillNotPiggybackIfWouldExceedBatchSize
{
    // Get a swizzled session that will always want to extend its access token.
    FBSession *session = [self createAndOpenSessionWithMockToken];
    FBSession *swizzledSession = [OCMockObject partialMockForObject:session];
    BOOL yes = YES;
    [[[(id)swizzledSession stub] andReturnValue:OCMOCK_VALUE(yes)] shouldExtendAccessToken];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    // Swizzle the connection not actually send any requests; we don't care what happens to the requests.
    FBURLConnection *mockURLConnection = [OCMockObject niceMockForClass:[FBURLConnection class]];
    FBRequestConnection *swizzledConnection = [OCMockObject partialMockForObject:connection];
    [[[(id)swizzledConnection expect] andReturn:mockURLConnection] newFBURLConnection];
    
    const int batchSize = 50;
    for (int i = 0; i < batchSize; ++i) {
        FBRequest *request = [[[FBRequest alloc] initWithSession:swizzledSession graphPath:@"me"] autorelease];
        
        // Minimize traffic by just getting our id.
        [request.parameters setObject:@"id" forKey:@"fields"];
        
        [swizzledConnection addRequest:request completionHandler:[self handlerExpectingSuccessSignaling:nil]];
    }
    [swizzledConnection start];
    
    NSArray *requests = [swizzledConnection performSelector:@selector(requests)];
    STAssertTrue(requests.count == batchSize, @"piggybacked but shouldn't have");
    [connection release];
}

- (void)testNoRequests
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    STAssertThrows([connection start], @"should throw");
    [connection release];
}

// Simple test to verify FBRequestConnectionErrorBehaviorRetry.
- (void)testRetryBehavior
{
    __block int requestCount = 0;
    
    // Mock response to generate a retry attempt.
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake error object that will be categorized as Retry.
        NSData *data =  [@"{\"error\": {\"message\": \"Retry this\",\"code\": 190,\"error_subcode\": 65000}}" dataUsingEncoding:NSUTF8StringEncoding];
        
        requestCount++;
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:400
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorRetry;
    
    __block int handlerCount = 0;
    [connection addRequest:[FBRequest requestForMe] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertEquals(0, handlerCount++, @"user handler invoked more than once");
        [blocker signal];
    } ];
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:1], @"timed out waiting for request to return");
    STAssertEquals(2, requestCount, @"expected number of retries not met");
    
    [OHHTTPStubs removeAllRequestHandlers];
}

// happy path test for FBRequestConnectionErrorBehaviorReconnectSession
- (void)testReconnectBehavior
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]] autorelease];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil permissionsRefreshDate:[NSDate date]];
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    
    __block int requestCount = 0;
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake error object that will be categorized for reconnecting the session. Note this error is only for non-batched requests.
        // If there is a test failure, you should verify the requests.count == 1 and debug that if it's not; otherwise this error response will likely cause
        // an unrelated error to be surfaced. For example, the session init above set the permissionsRefreshDate to [NSDate date]. If it had not,
        // there could be piggy-backed permissions request which would then expect a batch response. So, this test doubles to verify there was no
        // piggybacked request when the permissionRefreshDate is set.
        NSData *data =  [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
        
        requestCount++;
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:400
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *request =[[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int handlerCount = 0;
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertEquals(0, handlerCount++, @"user handler invoked more than once");
        [blocker signal];
    } ];
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:1], @"timed out waiting for request to return");
    STAssertEquals(2, requestCount, @"expected number of retries not met");
    [OHHTTPStubs removeAllRequestHandlers];
}

// happy path test for FBRequestConnectionErrorBehaviorReconnectSession
// with 2 failed requests in a batch (make sure both are retried)
- (void)testReconnectBehaviorBatch
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil permissionsRefreshDate:[NSDate date]];
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    
    __block int requestCount = 0;

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake batch response with two errors that will be categorized for reconnecting the session
        NSString *errorBodyString = [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSData *data =  [[NSString stringWithFormat:@"["
                          "{\"code\":400,\"body\":\"%@\"},"
                          "{\"code\":400,\"body\":\"%@\"}"
                          "]",
                          errorBodyString,
                          errorBodyString]
                         dataUsingEncoding:NSUTF8StringEncoding];       
        requestCount++;
        
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:2];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *requestPermissions =[[[FBRequest alloc] initWithSession:session graphPath:@"me/permissions"] autorelease];
    FBRequest *requestFriends =[[[FBRequest alloc] initWithSession:session graphPath:@"me/friends"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int userHandlerPermissionsCount = 0;
    __block int userHandlerFriendsCount = 0;
    [connection addRequest:requestPermissions completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerPermissionsCount++;
        [blocker signal];
    } ];
    [connection addRequest:requestFriends completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerFriendsCount++;
        [blocker signal];
    } ];

    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:1], @"timed out waiting for request to return");
    STAssertEquals(2, requestCount, @"expected number of retries not met");
    STAssertEquals(1, userHandlerPermissionsCount, @"user handler was not invoked once.");
    STAssertEquals(1, userHandlerFriendsCount, @"user handler was not invoked once.");
    [OHHTTPStubs removeAllRequestHandlers];
}

// test for FBRequestConnectionErrorBehaviorReconnectSession
// with a batch request where 1 request succeeds.
- (void)testReconnectBehaviorBatchPartialSuccess
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil permissionsRefreshDate:[NSDate date]];
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    
    __block int requestCount = 0;
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake batch response with 1 success (permissions) and 1 failure.
        // Note this technically means the retried /friends request gets this stubbed
        // batch response as well which doesn't matter for this test in particular.
        NSString *errorBodyString = [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSData *data =  [[NSString stringWithFormat:@"["
                          "{\"code\":200,\"body\":\"%@\"},"
                          "{\"code\":400,\"body\":\"%@\"}"
                          "]",
                          [@"{\"data\":[ { \"installed\":1, \"basic_info\":1} ] }" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
                          errorBodyString]
                         dataUsingEncoding:NSUTF8StringEncoding];
        requestCount++;
        
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:2];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *requestPermissions =[[[FBRequest alloc] initWithSession:session graphPath:@"me/permissions"] autorelease];
    FBRequest *requestFriends =[[[FBRequest alloc] initWithSession:session graphPath:@"me/friends"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int userHandlerPermissionsCount = 0;
    __block int userHandlerFriendsCount = 0;
    [connection addRequest:requestPermissions completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerPermissionsCount++;
        // also make sure the permisisons request got the expected response from the stub above
        STAssertNotNil(result[@"data"][0][@"installed"], @"Didn't find permissions for installed");
        STAssertNotNil(result[@"data"][0][@"basic_info"], @"Didn't find permissions for basic_info");
        [blocker signal];
    } ];
    [connection addRequest:requestFriends completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerFriendsCount++;
        [blocker signal];
    } ];
    
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:2], @"timed out waiting for request to return");
    STAssertEquals(2, requestCount, @"expected number of retries not met");
    STAssertEquals(1, userHandlerPermissionsCount, @"user handler was not invoked once.");
    STAssertEquals(1, userHandlerFriendsCount, @"user handler was not invoked once.");
    [OHHTTPStubs removeAllRequestHandlers];
}

// test for FBRequestConnectionErrorBehaviorReconnectSession
// where the reconnect (aka reauthorize) is declined.
- (void)testReconnectBehaviorDeclineLogin
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]] autorelease];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil];
    session.disableReauthorize = YES;
    
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    
    __block int requestCount = 0;
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake error object that will be categorized for reconnecting the session
        NSData *data =  [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
        
        requestCount++;
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:400
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *request =[[[FBRequest alloc] initWithSession:session graphPath:@"me"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int handlerCount = 0;
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertEquals(0, handlerCount++, @"user handler invoked more than once");
        [blocker signal];
    } ];
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:1], @"timed out waiting for request to return");
    // Unlike the tests above, there should be no retry since the user declined the relogin;
    // therefore the error behavior should have immediately invoked the user handler to the fbrequest.
    STAssertEquals(1, requestCount, @"expected number of attempts not met");
    [OHHTTPStubs removeAllRequestHandlers];
}

// test to exercise FBRequestConnectionErrorBehaviorReconnectSession
// with a permissions refresh piggybacked and the original request fails (and should be retried).
- (void)testReconnectBehaviorBatchWithPermissionsRefresh
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil];
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    
    __block int requestCount = 0;
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        // Construct a fake batch response with 1 failure and 1 success (permissions piggyback).
        // Note this technically means the retried /friends request gets this stubbed
        // batch response as well which doesn't matter for this test in particular.
        NSString *errorBodyString = [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSData *data =  [[NSString stringWithFormat:@"["
                          "{\"code\":400,\"body\":\"%@\"},"
                          "{\"code\":200,\"body\":\"%@\"}"
                          "]",
                          errorBodyString,
                          [@"{\"data\":[ { \"installed\":1, \"basic_info\":1} ] }" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]]
                         dataUsingEncoding:NSUTF8StringEncoding];
        requestCount++;
        
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *requestFriends =[[[FBRequest alloc] initWithSession:session graphPath:@"me/friends"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int userHandlerFriendsCount = 0;
    [connection addRequest:requestFriends completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerFriendsCount++;
        [blocker signal];
    } ];
    
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:2], @"timed out waiting for request to return");
    STAssertEquals(2, requestCount, @"expected number of retries not met");
    STAssertEquals(1, userHandlerFriendsCount, @"user handler was not invoked once.");
    [OHHTTPStubs removeAllRequestHandlers];
    NSTimeInterval timeSincePermissionsRefresh = [session.accessTokenData.permissionsRefreshDate timeIntervalSinceNow];
    STAssertTrue(timeSincePermissionsRefresh > -3, @"permissions refresh date should be within a few seconds of now");
}

// test to exercise FBRequestConnectionErrorBehaviorReconnectSession
// with a permissions refresh piggybacked (which fails) and the original request succeeds.
// there should be no retry since the session should not be closed.
- (void)testReconnectBehaviorBatchWithPermissionsRefreshFailure
{
    // Create a fake session that is already open
    // Note we rely on FBTestSession automatically succeeding reauthorize.
    FBTestSession *session = [[FBTestSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceOnlyMe urlSchemeSuffix:nil tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:@"token" permissions:nil expirationDate:nil loginType:FBSessionLoginTypeFacebookViaSafari refreshDate:nil];
    [session openFromAccessTokenData:tokenData completionHandler:nil];
    STAssertEquals([NSDate distantPast], session.accessTokenData.permissionsRefreshDate, @"permissions refresh date was not initialized properly to distantPast");
    __block int requestCount = 0;
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *errorBodyString = [@"{\"error\": {\"message\": \"Reconnect this\",\"code\": 190,\"error_subcode\": 463}}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSData *data =  [[NSString stringWithFormat:@"["
                          "{\"code\":200,\"body\":\"%@\"},"
                          "{\"code\":400,\"body\":\"%@\"}"
                          "]",
                          [@"{\"data\":[ { \"name\":\"zuck\", \"id\":\"4\"} ] }" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
                          errorBodyString]
                         dataUsingEncoding:NSUTF8StringEncoding];
        requestCount++;
        
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];
    
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequest *requestFriends =[[[FBRequest alloc] initWithSession:session graphPath:@"me/friends"] autorelease];
    connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession;
    
    __block int userHandlerFriendsCount = 0;
    [connection addRequest:requestFriends completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        userHandlerFriendsCount++;
        STAssertTrue([@"zuck" isEqualToString:(result[@"data"][0][@"name"])], @"couldn't find friend");
        [blocker signal];
    } ];
    
    [connection start];
    
    STAssertTrue([blocker waitWithTimeout:2], @"timed out waiting for request to return");
    STAssertEquals(1, requestCount, @"there should have been no retry");
    STAssertEquals(1, userHandlerFriendsCount, @"user handler was not invoked once.");
    [OHHTTPStubs removeAllRequestHandlers];

    STAssertEquals([NSDate distantPast], session.accessTokenData.permissionsRefreshDate, @"permissions refresh date was unexpectedly updated");
}


@end
