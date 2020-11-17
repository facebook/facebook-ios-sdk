// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKTestCase.h"

@interface FBSDKGraphRequestConnection (Testing)

- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout;

@end

@interface FBSDKGraphRequestConnectionTests : FBSDKTestCase <FBSDKGraphRequestConnectionDelegate>

@property (nonatomic, copy) void (^requestConnectionStartingCallback)(FBSDKGraphRequestConnection *connection);
@property (nonatomic, copy) void (^requestConnectionCallback)(FBSDKGraphRequestConnection *connection, NSError *error);
@end

@implementation FBSDKGraphRequestConnectionTests

#pragma mark - XCTestCase

- (void)setUp
{
  [super setUp];

  [self stubAppID:self.appID];
  [self stubCheckingFeatures];
  [self stubIsSDKInitialized:YES];
  [self stubLoadingGateKeepers];
  [self stubFetchingCachedServerConfiguration];
}

- (void)tearDown
{
  [super tearDown];

  [OHHTTPStubs removeAllStubs];
}

#pragma mark - Helpers

// to prevent piggybacking of server config fetching
+ (id)mockCachedServerConfiguration
{
  id mockPiggybackManager = [OCMockObject niceMockForClass:[FBSDKGraphRequestPiggybackManager class]];
  [[mockPiggybackManager stub] addServerConfigurationPiggyback:OCMOCK_ANY];
  return mockPiggybackManager;
}

#pragma mark - FBSDKGraphRequestConnectionDelegate

- (void)requestConnection:(FBSDKGraphRequestConnection *)connection didFailWithError:(NSError *)error
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, error);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionDidFinishLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, nil);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionWillBeginLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionStartingCallback) {
    self.requestConnectionStartingCallback(connection);
    self.requestConnectionStartingCallback = nil;
  }
}

#pragma mark - Tests

- (void)_testClientToken
{
  // if it's a batch request the body will be zipped so make sure we don't do that
  id mockUtility = [OCMockObject niceMockForClass:[FBSDKBasicUtility class]];
  [[[mockUtility stub] andReturn:nil] gzip:[OCMArg any]];

  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [self stubCurrentAccessTokenWith:nil];
  [self stubClientTokenWith:@"clienttoken"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 // If it's a batch request, the token will be in the body. If it's a single request it will be in the url
                 // we should check that it's in one or the other.
                 NSString *url = request.URL.absoluteString;
                 NSString *body = [[NSString alloc] initWithData:request.OHHTTPStubs_HTTPBody encoding:NSUTF8StringEncoding];
                 u_long tokenLength = ([body rangeOfString:@"access_token"].length + [url rangeOfString:@"access_token"].length);
                 XCTAssertTrue(tokenLength > 0);
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463, \"type\":\"OAuthException\"}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion);
    [exp fulfill];
  }];
  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}

- (void)testClientTokenSkipped
{
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 XCTAssertTrue([[request.URL absoluteString] rangeOfString:@"access_token"].location == NSNotFound);
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} flags:FBSDKGraphRequestFlagSkipClientToken]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     [exp fulfill];
   }];
  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}

- (void)testConnectionDelegate
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  // stub out a batch response that returns /me.id twice
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                 NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" }, {\"code\":200,\"body\": \"%@\" } ]", meResponse, meResponse];
                 NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:200
                                                      headers:nil];
               }];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
  __block int actualCallbacksCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"expected to receive delegate completion"];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
       }];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
       }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];

  [mockPiggybackManager stopMocking];
}

- (void)testNonErrorEmptyDictionaryOrNullResponse
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": null }, {\"code\":200,\"body\": {} } ]"];
                 NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:200
                                                      headers:nil];
               }];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
  __block int actualCallbacksCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"expected not to crash on null or empty dict responses"];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
       }];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
       }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];

  [mockPiggybackManager stopMocking];
}

- (void)testConnectionDelegateWithNetworkError
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 // stub a response indicating a disconnected network
                 return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:@"NSURLErrorDomain" code:-1009 userInfo:nil]];
               }];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
  XCTestExpectation *expectation = [self expectationWithDescription:@"expected to receive network error"];
  [connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error != nil, @"didFinishLoading shouldn't have been called");
    [expectation fulfill];
  };
  connection.delegate = self;
  [connection start];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];

  [mockPiggybackManager stopMocking];
}

// test to verify piggyback refresh token behavior.
- (void)testTokenPiggyback
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  // use stubs because test tokens are not refreshable.
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                 NSString *refreshResponse = [[NSString stringWithFormat:@"{ \"access_token\":\"123\", \"expires_at\":%.0f }", [NSDate dateWithTimeIntervalSinceNow:60].timeIntervalSince1970] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                 NSString *permissionsResponse = [@"{ \"data\": [ { \"permission\" : \"public_profile\", \"status\" : \"granted\" },  { \"permission\" : \"email\", \"status\" : \"granted\" },  { \"permission\" : \"user_friends\", \"status\" : \"declined\" } ] }" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                 NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" },"
                                             @"{\"code\":200,\"body\": \"%@\" },"
                                             @"{\"code\":200,\"body\": \"%@\" } ]",
                                             meResponse,
                                             refreshResponse,
                                             permissionsResponse];
                 NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:200
                                                      headers:nil];
               }];
  FBSDKAccessToken *tokenThatNeedsRefresh = [[FBSDKAccessToken alloc]
                                             initWithTokenString:@"token"
                                             permissions:@[]
                                             declinedPermissions:@[]
                                             expiredPermissions:@[]
                                             appID:@"appid"
                                             userID:@"userid"
                                             expirationDate:[NSDate distantPast]
                                             refreshDate:[NSDate distantPast]
                                             dataAccessExpirationDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenThatNeedsRefresh];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertEqualObjects(tokenThatNeedsRefresh.userID, result[@"id"]);
    [exp fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertGreaterThan([[FBSDKAccessToken currentAccessToken].expirationDate timeIntervalSinceNow], 0);
  XCTAssertGreaterThan([[FBSDKAccessToken currentAccessToken].refreshDate timeIntervalSinceNow], -60);
  XCTAssertNotEqualObjects(tokenThatNeedsRefresh, [FBSDKAccessToken currentAccessToken]);
  XCTAssertTrue([[FBSDKAccessToken currentAccessToken].permissions containsObject:@"email"]);
  XCTAssertTrue([[FBSDKAccessToken currentAccessToken].declinedPermissions containsObject:@"user_friends"]);
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [mockPiggybackManager stopMocking];
}

// test no piggyback if refresh date is today.
- (void)testTokenPiggybackSkipped
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  FBSDKAccessToken *tokenNoRefresh = [[FBSDKAccessToken alloc]
                                      initWithTokenString:@"token"
                                      permissions:@[]
                                      declinedPermissions:@[]
                                      expiredPermissions:@[]
                                      appID:@"appid"
                                      userID:@"userid"
                                      expirationDate:[NSDate distantPast]
                                      refreshDate:[NSDate date]
                                      dataAccessExpirationDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenNoRefresh];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *r) {
                 // assert the path of r is "me"; since piggyback would go to root batch endpoint.
                 XCTAssertTrue([r.URL.path hasSuffix:@"me"]);
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *r) {
                 NSString *responseString = @"{ \"id\" : \"userid\"}";
                 NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:200
                                                      headers:nil];
               }];
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertEqualObjects(tokenNoRefresh.userID, result[@"id"]);
    [exp fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqualObjects(tokenNoRefresh, [FBSDKAccessToken currentAccessToken]);
  [mockPiggybackManager stopMocking];
}

- (void)testUnsettingAccessToken
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  __block int tokenChangeCount = 0;
  [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                            object:nil
                           handler:^BOOL (NSNotification *notification) {
                             if (++tokenChangeCount == 2) {
                               XCTAssertNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                               XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeOldKey]);
                               return YES;
                             }
                             return NO;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(result);
     XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNil([FBSDKAccessToken currentAccessToken]);
  [mockPiggybackManager stopMocking];
}

- (void)testUnsettingAccessTokenSkipped
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                            object:nil
                           handler:^BOOL (NSNotification *notification) {
                             XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                             return YES;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                     parameters:@{@"fields" : @""}
                                    tokenString:@"notCurrentToken"
                                        version:nil
                                     HTTPMethod:@""]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(result);
     XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
  [mockPiggybackManager stopMocking];
}

- (void)testUnsettingAccessTokenFlag
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                            object:nil
                           handler:^BOOL (NSNotification *notification) {
                             XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                             return YES;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(result);
     XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
  [mockPiggybackManager stopMocking];
}

- (void)testUserAgentSuffix
{
  // Disable compressing network request
  id mockUtility = [OCMockObject niceMockForClass:[FBSDKBasicUtility class]];
  [[[mockUtility stub] andReturn:nil] gzip:[OCMArg any]];
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  XCTestExpectation *exp2 = [self expectationWithDescription:@"completed request 2"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setUserAgentSuffix:@"UnitTest.1.0.0"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 NSString *actualUserAgent = [request valueForHTTPHeaderField:@"User-Agent"];
                 NSString *body = [[NSString alloc] initWithData:request.OHHTTPStubs_HTTPBody encoding:NSUTF8StringEncoding];
                 if ([body containsString:@"with_suffix"] || [body containsString:@"without_suffix"]) {
                   BOOL expectUserAgentSuffix = [body containsString:@"fields=with_suffix"];
                   if (expectUserAgentSuffix) {
                     XCTAssertTrue([actualUserAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", actualUserAgent);
                   } else {
                     XCTAssertFalse([actualUserAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", actualUserAgent);
                   }
                 }

                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"Missing oktne\",\"code\": 190, \"type\":\"OAuthException\"}}" dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"with_suffix"}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    [exp fulfill];
  }];

  [FBSDKSettings setUserAgentSuffix:nil];
  // issue a second request o verify clearing out of user agent suffix, passing a field=name to uniquely identify the request.
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"without_suffix"}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    [exp2 fulfill];
  }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

- (void)testNonDictionaryInError
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": \"a-non-dictionary\"}" dataUsingEncoding:NSUTF8StringEncoding];
                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:200
                                                      headers:nil];
               }];

  // adding fresh token to avoid piggybacking a token refresh
  FBSDKAccessToken *tokenNoRefresh = [[FBSDKAccessToken alloc]
                                      initWithTokenString:@"token"
                                      permissions:@[]
                                      declinedPermissions:@[]
                                      expiredPermissions:@[]
                                      appID:@"appid"
                                      userID:@"userid"
                                      expirationDate:[NSDate distantPast]
                                      refreshDate:[NSDate date]
                                      dataAccessExpirationDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenNoRefresh];

  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    // should not crash when receiving something other than a dictionary within the response.
    [exp fulfill];
  }];
  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  [mockPiggybackManager stopMocking];
}

- (void)testRequestWithBatchConstructionWithSingleGetRequest
{
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"with_suffix"}];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *_Nullable _connection, id _Nullable result, NSError *_Nullable error) {}];
  NSURLRequest *request = [connection requestWithBatch:connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"me"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"GET");
  XCTAssertTrue(request.HTTPBody.length == 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

- (void)testRequestWithBatchConstructionWithSinglePostRequest
{
  NSDictionary *parameters = @{
    @"first_key" : @"first_value",
  };
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"activities" parameters:parameters HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  [connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *_Nullable _connection, id _Nullable result, NSError *_Nullable error) {}];
  NSURLRequest *request = [connection requestWithBatch:connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"activities"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"POST");
  XCTAssertTrue(request.HTTPBody.length > 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

#pragma mark - Error recovery.

// verify we do a single retry.
- (void)testRetry
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  __block int requestCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 XCTAssertLessThanOrEqual(++requestCount, 2);
                 NSString *responseJSON = (requestCount == 1
                   ? @"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}"
                   : @"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}");
                 NSData *data = [responseJSON dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    // verify we get the second error instance.
    XCTAssertEqual(2, [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqual(2, requestCount);
  [mockPiggybackManager stopMocking];
}

- (void)_testRetryDisabled
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  FBSDKSettings.graphErrorRecoveryEnabled = NO;

  __block int requestCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 return YES;
               } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                 XCTAssertLessThanOrEqual(++requestCount, 1);
                 NSString *responseJSON = (requestCount == 1
                   ? @"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}"
                   : @"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}");
                 NSData *data = [responseJSON dataUsingEncoding:NSUTF8StringEncoding];

                 return [OHHTTPStubsResponse responseWithData:data
                                                   statusCode:400
                                                      headers:nil];
               }];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];

  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    // verify we don't get the second error instance.
    XCTAssertEqual(1, [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqual(1, requestCount);
  FBSDKSettings.graphErrorRecoveryEnabled = NO;
  [mockPiggybackManager stopMocking];
}

@end
