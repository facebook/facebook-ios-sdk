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

#import "FBURLConnectionTests.h"
#import "FBURLConnection.h"
#import "FBTestBlocker.h"
#import "FBDataDiskCache.h"
#import "FBError.h"

#import <OHHTTPStubs/OHHTTPStubs.h>

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBURLConnection (Internal)

@property (nonatomic) BOOL skipRoundtripIfCached;
- (void)invokeHandler:(FBURLConnectionHandler)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData;
- (FBDataDiskCache *)getCache;
- (BOOL)shouldShortCircuitRedirectResponse:(NSURLResponse *)redirectResponse;
- (void)logMessage:(NSString *)message;

@end

// For the most part we rely on FBURLConnection calling its handler to determine success or
// failure of test cases, but a couple of them test behavior without a handler at all, and
// we want a way to signal a blocker when there is no handler.
@interface TestFBURLConnection : FBURLConnection

@property (nonatomic, retain) FBTestBlocker *blockerToSignalOnCompletion;
@property (nonatomic, copy) FBURLConnectionHandler handler;
@property (nonatomic, retain) FBDataDiskCache *dataDiskCache;
@property (nonatomic) BOOL actAsRedirect;
@property (nonatomic, retain) NSMutableString *accumulatedLog;

@end

@implementation TestFBURLConnection

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
               skipRoundTripIfCached:(BOOL)skipRoundtripIfCached
                   completionHandler:(FBURLConnectionHandler)handler
                       dataDiskCache:(FBDataDiskCache *)theDataDiskCache {
    self.dataDiskCache = theDataDiskCache;

    return [super initWithRequest:request
            skipRoundTripIfCached:skipRoundtripIfCached
                completionHandler:handler];
}

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
               skipRoundTripIfCached:(BOOL)skipRoundtripIfCached
                   completionHandler:(FBURLConnectionHandler)handler
                       dataDiskCache:(FBDataDiskCache *)theDataDiskCache
                       actAsRedirect:(BOOL)redirect {
    self.dataDiskCache = theDataDiskCache;
    self.actAsRedirect = redirect;

    return [super initWithRequest:request
            skipRoundTripIfCached:skipRoundtripIfCached
                completionHandler:handler];
}

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
               skipRoundTripIfCached:(BOOL)skipRoundtripIfCached
         blockerToSignalOnCompletion:(FBTestBlocker *)blocker
                       dataDiskCache:(FBDataDiskCache *)theDataDiskCache {
    self.dataDiskCache = theDataDiskCache;
    self.blockerToSignalOnCompletion = blocker;

    return [super initWithRequest:request
            skipRoundTripIfCached:skipRoundtripIfCached
                completionHandler:nil];
}

- (void)invokeHandler:(FBURLConnectionHandler)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData {
    [super invokeHandler:handler error:error response:response responseData:responseData];
    [_blockerToSignalOnCompletion signal];
}

- (void)cancel {
    [super cancel];
    [_blockerToSignalOnCompletion signal];
}

- (FBDataDiskCache *)getCache {
    if (self.dataDiskCache != nil) {
        return self.dataDiskCache;
    }
    // Use a no-op one
    return [OCMockObject niceMockForClass:[FBDataDiskCache class]];
}

- (BOOL)shouldShortCircuitRedirectResponse:(NSURLResponse *)redirectResponse {
    if (self.actAsRedirect) {
        return YES;
    }
    return [super shouldShortCircuitRedirectResponse:redirectResponse];
}

- (void)logMessage:(NSString *)message {
    [super logMessage:message];
    if (self.accumulatedLog == nil) {
        self.accumulatedLog = [[[NSMutableString alloc] init] autorelease];
    }
    [self.accumulatedLog appendString:message];
}

@end

#pragma mark - Test suite

@implementation FBURLConnectionTests {
    FBTestBlocker *_blocker;
    BOOL _handlerCalled;
    FBURLConnectionHandler _handler;
}

- (void)setUp {
    _blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    _handlerCalled = NO;
    _handler = nil;
}

- (void)tearDown {
    [_blocker release];
    _blocker = nil;
    [_handler release];
    _handler = nil;

    [OHHTTPStubs removeAllRequestHandlers];
}

#pragma mark Test cases

- (void)testHandlerIsCalledOnSuccessfulCall {
    [self setupHTTPStubWithStatus:200 andString:nil delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:200 andString:nil];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    assertThatBool(_handlerCalled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testHandlerGetsExpectedDataOnSuccessfulCall {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    [connection release];
    [request release];
}

- (void)testURLIsLogged {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    assertThat(connection.accumulatedLog, containsString(@"URL"));
    assertThat(connection.accumulatedLog, containsString(request.URL.absoluteString));

    [connection release];
    [request release];
}

- (void)testDurationAndSizeAreLoggedOnSuccess {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    assertThat(connection.accumulatedLog, containsString(@"Duration"));
    assertThat(connection.accumulatedLog, containsString(@"Response Size"));

    [connection release];
    [request release];
}

- (void)testJavascriptResponseAreLogged {
    __block NSString *javascript = @"This isn't really Javascript";
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *data = [javascript dataUsingEncoding:NSUTF8StringEncoding];

        NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"text/javascript", @"Content-Type",
                                 nil];
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0
                                             headers:headers];
    }];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:200 andString:nil];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    assertThat(connection.accumulatedLog, containsString(javascript));

    [connection release];
    [request release];
}

- (void)testHandlerGetsErrorOnFailedCall {
    NSError *error = [NSError errorWithDomain:@"An error" code:100 userInfo:nil];
    [self setupHTTPStubWithError:error];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingError:error];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    [connection release];
    [request release];
}

- (void)testErrorIsLogged {
    NSError *error = [NSError errorWithDomain:@"An error" code:100 userInfo:nil];
    [self setupHTTPStubWithError:error];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingError:error];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [_blocker waitWithTimeout:0.2];

    assertThat(connection.accumulatedLog, containsString(@"Error"));

    [connection release];
    [request release];
}

- (void)testCanExecuteWithoutHandler {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:nil];

    [connection setBlockerToSignalOnCompletion:_blocker];

    BOOL signaled = [_blocker waitWithTimeout:0.2];
    assertThatBool(signaled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testCancellingGeneratesError {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:5];

    NSURLRequest *request = [self newRequest];

    NSError *error = [NSError errorWithDomain:FacebookSDKDomain code:FBErrorOperationCancelled userInfo:nil];
    [self setHandlerExpectingError:error];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler];

    [connection cancel];

    [_blocker waitWithTimeout:0.2];

    [connection release];
    [request release];
}

- (void)testCanCancelWithoutHandler {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:5];

    NSURLRequest *request = [self newRequest];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:nil];
    [connection setBlockerToSignalOnCompletion:_blocker];
    [connection cancel];

    BOOL signaled = [_blocker waitWithTimeout:0.2];
    assertThatBool(signaled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testHelperInitDefaultsToSkipRoundtripIfCached {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithURL:request.URL
                                                             completionHandler:nil];

    assertThatBool([(id)connection skipRoundtripIfCached], equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testWithCachedURLCallsHandlerImmediately {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:0 andString:@"Hello World"];

    id mockDataDiskCache = [self createMockDiskCacheReturning:@"Hello World"
                                                       forURL:@"http://www.example.com"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:YES
                                                                 completionHandler:_handler
                                                                     dataDiskCache:mockDataDiskCache];

    assertThatBool(_handlerCalled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testCachedResponseIsLogged {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];

    [self setHandlerExpectingStatus:0 andString:@"Hello World"];

    id mockDataDiskCache = [self createMockDiskCacheReturning:@"Hello World"
                                                       forURL:@"http://www.example.com"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:YES
                                                                 completionHandler:_handler
                                                                     dataDiskCache:mockDataDiskCache];

    [_blocker waitWithTimeout:0.2];

    assertThat(connection.accumulatedLog, containsString(@"Cached response"));

    [connection release];
    [request release];
}

- (void)testUsesSharedDiskCache {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];
    FBURLConnection *connection = [[FBURLConnection alloc] initWithRequest:request
                                                     skipRoundTripIfCached:YES
                                                         completionHandler:nil];

    assertThat([connection getCache], equalTo([FBDataDiskCache sharedCache]));

    [connection release];
}

- (void)testCanHitCacheWithoutHandler {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [self newRequest];
    id mockDataDiskCache = [self createMockDiskCacheReturning:@"Hello World"
                                                       forURL:@"http://www.example.com"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:YES
                                                       blockerToSignalOnCompletion:_blocker
                                                                     dataDiskCache:mockDataDiskCache];

    BOOL signaled = [_blocker waitWithTimeout:0.2];
    assertThatBool(signaled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testAddsDataFromCDNToCache {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.akamaihd.net"]];

    id mockDataDiskCache = [self createMockDiskCacheExpecting:@"Hello World"
                                                       forURL:@"http://www.akamaihd.net"];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:YES
                                                                 completionHandler:_handler
                                                                     dataDiskCache:mockDataDiskCache];
    [_blocker waitWithTimeout:.2];

    [mockDataDiskCache verify];

    [connection release];
    [request release];
}

- (void)testRedirectResponsesSucceed {
    [self setupHTTPStubWithStatus:200 andString:@"Hello World" delayed:0];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.example.com"]];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler
                                                                     dataDiskCache:nil
                                                                     actAsRedirect:YES];

    [_blocker waitWithTimeout:.2];

    assertThatBool(_handlerCalled, equalToBool(YES));

    [connection release];
    [request release];
}

- (void)testCachedRedirectResponsesSucceed {
    [self setupHTTPStubWithStatus:200 andString:nil delayed:0];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.example.com"]];
    id mockDataDiskCache = [self createMockDiskCacheReturning:@"Hello World"
                                                       forURL:@"http://www.example.com"];

    [self setHandlerExpectingStatus:200 andString:@"Hello World"];

    TestFBURLConnection *connection = [[TestFBURLConnection alloc] initWithRequest:request
                                                             skipRoundTripIfCached:NO
                                                                 completionHandler:_handler
                                                                     dataDiskCache:mockDataDiskCache
                                                                     actAsRedirect:YES];

    [_blocker waitWithTimeout:.2];

    assertThatBool(_handlerCalled, equalToBool(YES));

    [connection release];
    [request release];
}


#pragma mark Helpers


- (void)setupHTTPStubWithStatus:(int)statusCode andString:(NSString *)string delayed:(NSTimeInterval)delay {
    // www.example.com (non-CDN) and www.akamaihd.net (CDN) generate responses
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:@"http://www.example.com"] ||
        [request.URL.absoluteString isEqualToString:@"http://www.akamaihd.net"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *data = nil;
        if (string != nil) {
            data = [string dataUsingEncoding:NSUTF8StringEncoding];
        }
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:statusCode
                                        responseTime:delay
                                             headers:nil];
    }];
}

- (void)setupHTTPStubWithError:(NSError *)error {
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:error];
    }];
}

- (NSDictionary *)getParametersFromURL:(NSURL *)url {
    NSArray *parameters = [url.query componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"=&"]];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    for (int i = 0; i < [parameters count]; i=i+2) {
        NSString *key = [[parameters objectAtIndex:i] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *value = [[parameters objectAtIndex:i+1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [result setObject:value
                   forKey:key];
    }

    return result;
}

- (void)setHandlerExpectingStatus:(int)expectedStatusCode andString:(NSString *)expectedString {
    id handler = ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *responseData) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        assertThatInteger(statusCode, equalToInteger(expectedStatusCode));

        if (expectedString != nil) {
            assertThat(responseData, notNilValue());

            NSString *responseString = [[[NSString alloc] initWithData:responseData
                                                              encoding:NSUTF8StringEncoding] autorelease];
            assertThat(responseString, equalTo(expectedString));
        }

        _handlerCalled = YES;
        [_blocker signal];
    };
    _handler = [handler copy];
    [handler release];
}

- (void)setHandlerExpectingError:(NSError *)expectedError {
    id handler = ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *responseData) {
        if (error != nil) {
            assertThat(error, notNilValue());
            assertThat([error domain], equalTo([expectedError domain]));
            assertThatInteger([error code], equalToInteger([expectedError code]));
        }

        _handlerCalled = YES;
        [_blocker signal];
    };
    _handler = [handler copy];
    [handler release];
}

- (NSURLRequest *)newRequest {
    return [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.example.com"]];

}

- (FBDataDiskCache *)createMockDiskCacheReturning:(NSString *)string forURL:(NSString *)url {
    NSData *data = nil;
    if (string != nil) {
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
    }

    id mockDataDiskCache = [OCMockObject mockForClass:[FBDataDiskCache class]];
    [[[mockDataDiskCache stub] andReturn:data] dataForURL:[NSURL URLWithString:url]];

    return mockDataDiskCache;
}

- (FBDataDiskCache *)createMockDiskCacheExpecting:(NSString *)string forURL:(NSString *)url {
    NSData *data = nil;
    if (string != nil) {
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
    }

    id mockDataDiskCache = [OCMockObject mockForClass:[FBDataDiskCache class]];
    [[[mockDataDiskCache stub] andReturn:nil] dataForURL:[NSURL URLWithString:url]];
    [[mockDataDiskCache expect] setData:data forURL:[NSURL URLWithString:url]];
    
    return mockDataDiskCache;
}

@end
