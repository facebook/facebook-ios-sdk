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

#import "FBRequestConnectionTests.h"
#import "FBTestSession.h"
#import "FBTestSession+Internal.h"
#import "FBRequestConnection.h"
#import "FBRequestConnection+Internal.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBURLConnection.h"

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBSession (Testing)

- (BOOL)shouldExtendAccessToken;

@end

@interface FBRequestConnection (Testing)

- (FBURLConnection *)newFBURLConnection;

@end

@implementation FBRequestConnectionTests

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

@end
