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

#import "FBTests.h"

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBAccessTokenData+Internal.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"

NSString *kTestToken = @"This is a token";
NSString *kTestAppId = @"AnAppId";

@implementation FBTests

- (void)tearDown
{
    [OHHTTPStubs removeAllRequestHandlers];
    [super tearDown];
}

#pragma mark Handlers

- (FBRequestHandler)handlerExpectingSuccessSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        XCTAssertTrue(!error, @"got unexpected error");
        XCTAssertNotNil(result, @"didn't get expected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

- (FBRequestHandler)handlerExpectingFailureSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        XCTAssertNotNil(error, @"didn't get expected error");
        XCTAssertTrue(!result, @"got unexpected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

#pragma mark - Session mocking

- (FBAccessTokenData *)createValidMockToken {

    FBAccessTokenData *token = [FBAccessTokenData  createTokenFromString:kTestToken
                                                             permissions:nil
                                                          expirationDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                                                               loginType:FBSessionLoginTypeNone
                                                             refreshDate:nil];

    FBAccessTokenData *mockToken = [OCMockObject partialMockForObject:token];
    return mockToken;
}


- (FBSession *)createAndOpenSessionWithMockToken {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];

    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];

    [session openWithCompletionHandler:nil];

    return session;

}

- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithExpiredToken {
    FBAccessTokenData *token = [FBAccessTokenData  createTokenFromString:kTestToken
                                                             permissions:nil
                                                          expirationDate:[NSDate dateWithTimeIntervalSince1970:0]
                                                               loginType:FBSessionLoginTypeNone
                                                             refreshDate:nil];
    return [self createMockTokenCachingStrategyWithToken:token];
}

- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithValidToken {
    FBAccessTokenData *token = [self createValidMockToken];
    return [self createMockTokenCachingStrategyWithToken:token];
}

- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithToken:(FBAccessTokenData *)token {
    FBSessionTokenCachingStrategy *strategy = [OCMockObject mockForClass:[FBSessionTokenCachingStrategy class]];

    [[[(id)strategy stub] andReturn:token] fetchFBAccessTokenData];

    return strategy;
}

- (void)waitForMainQueueToFinish {
    FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [blocker signal];
    });

    [blocker wait];

    [blocker release];
}

#pragma mark - HTTP stubbing helpers

- (void)stubAllResponsesWithResult:(id)result
{
    [self stubAllResponsesWithResult:result statusCode:200];
}

- (void)stubAllResponsesWithResult:(id)result
                        statusCode:(int)statusCode
{
    [self stubAllResponsesWithResult:result statusCode:statusCode callback:nil];
}

- (void)stubAllResponsesWithResult:(id)result
                        statusCode:(int)statusCode
                          callback:(HTTPStubCallback)callback
{
    return [self stubMatchingRequestsWithResponses:@{@"" : result}
                                        statusCode:statusCode
                                          callback:callback];
}

- (void)stubMatchingRequestsWithResponses:(NSDictionary *)requestsAndResponses
                               statusCode:(int)statusCode
                                 callback:(HTTPStubCallback)callback
{
    id (^matchingKey)(NSString *) = ^id (NSString *urlString) {
        for (NSString *substring in requestsAndResponses.allKeys) {
            // The first @"" always matches
            if (substring.length == 0 ||
                [urlString rangeOfString:substring].location != NSNotFound) {
                return substring;
            }
        }
        return nil;
    };

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        if (callback) {
            callback(request);
        }

        return matchingKey(request.URL.absoluteString) != nil;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        id result = requestsAndResponses[matchingKey(request.URL.absoluteString)];
        NSData *data = [[FBUtility simpleJSONEncode:result] dataUsingEncoding:NSUTF8StringEncoding];

        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:statusCode
                                        responseTime:0
                                             headers:nil];
    }];
}

@end
