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

#import <UIKit/UIKit.h>

#import <OCMock/OCMock.h>

#import <OHHTTPStubs/OHHTTPStubs.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestPiggybackManager.h"

@interface FBSDKGraphRequestConnectionTests : XCTestCase
@end

static id g_mockAccountStoreAdapter;
static id g_mockNSBundle;

@implementation FBSDKGraphRequestConnectionTests

- (void)tearDown
{
  [OHHTTPStubs removeAllStubs];
}

+ (void)setUp
{
  [FBSDKSettings setAppID:@"appid"];
  g_mockNSBundle = [FBSDKCoreKitTestUtility mainBundleMock];
  g_mockAccountStoreAdapter = [FBSDKCoreKitTestUtility mockAccountStoreAdapter];
}

+ (void)tearDown
{
  [g_mockNSBundle stopMocking];
  g_mockNSBundle = nil;
  [g_mockAccountStoreAdapter stopMocking];
  g_mockAccountStoreAdapter = nil;

}

//to prevent piggybacking of server config fetching
+ (id)mockCachedServerConfiguration
{
  id mockPiggybackManager = [OCMockObject niceMockForClass:[FBSDKGraphRequestPiggybackManager class]];
  [[mockPiggybackManager stub] addServerConfigurationPiggyback:OCMOCK_ANY];
  return mockPiggybackManager;
}

- (void)testClientToken
{
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    XCTAssertFalse([body rangeOfString:@"access_token"].location == NSNotFound);
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSData *data =  [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    XCTAssertTrue([[request.URL absoluteString] rangeOfString:@"access_token"].location == NSNotFound);
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSData *data =  [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil flags:FBSDKGraphRequestFlagSkipClientToken]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     [exp fulfill];
   }];
  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}

// test to verify piggyback refresh token behavior.
- (void)testTokenPiggyback
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  // use stubs because test tokens are not refreshable.
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *refreshResponse = [[NSString stringWithFormat:@"{ \"access_token\":\"123\", \"expires_at\":%.0f }", [[NSDate dateWithTimeIntervalSinceNow:60] timeIntervalSince1970]] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" }, {\"code\":200,\"body\": \"%@\" } ]", meResponse, refreshResponse];
    NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:200
                                         headers:nil];
  }];
  FBSDKAccessToken *tokenThatNeedsRefresh = [[FBSDKAccessToken alloc]
                                             initWithTokenString:@"token"
                                             permissions:nil
                                             declinedPermissions:nil
                                             appID:@"appid"
                                             userID:@"userid"
                                             expirationDate:[NSDate distantPast]
                                             refreshDate:[NSDate distantPast]];
  [FBSDKAccessToken setCurrentAccessToken:tokenThatNeedsRefresh];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
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
                                      permissions:nil
                                      declinedPermissions:nil
                                      appID:@"appid"
                                      userID:@"userid"
                                      expirationDate:[NSDate distantPast]
                                      refreshDate:[NSDate date]];
  [FBSDKAccessToken setCurrentAccessToken:tokenNoRefresh];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
  XCTestExpectation *exp = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *r) {
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
                           handler:^BOOL(NSNotification *notification) {
                             if (++tokenChangeCount == 2) {
                               XCTAssertNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                               XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeOldKey]);
                               return YES;
                             }
                             return NO;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:nil
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSData *data =  [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
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
                           handler:^BOOL(NSNotification *notification) {
                             XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                             return YES;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:nil
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSData *data =  [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                     parameters:nil
                                    tokenString:@"notCurrentToken"
                                        version:nil
                                     HTTPMethod:nil]
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
                           handler:^BOOL(NSNotification *notification) {
                             XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                             return YES;
                           }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:nil
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSData *data =  [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError]
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

#pragma mark - Error recovery.

// verify we do a single retry.
- (void)testRetry
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  __block int requestCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    XCTAssertLessThanOrEqual(++requestCount, 2);
    NSString *responseJSON = (requestCount == 1 ?
                              @"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}"
                              : @"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}" );
    NSData *data =  [responseJSON dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    //verify we get the second error instance.
    XCTAssertEqual(2, [error.userInfo[FBSDKGraphRequestErrorGraphErrorCode] integerValue]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqual(2, requestCount);
  [mockPiggybackManager stopMocking];
}

- (void)testRetryDisabled
{
  id mockPiggybackManager = [[self class] mockCachedServerConfiguration];
  [FBSDKSettings setGraphErrorRecoveryDisabled:YES];
  __block int requestCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    XCTAssertLessThanOrEqual(++requestCount, 1);
    NSString *responseJSON = (requestCount == 1 ?
                              @"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}"
                              : @"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}" );
    NSData *data =  [responseJSON dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:400
                                         headers:nil];
  }];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    //verify we don't get the second error instance.
    XCTAssertEqual(1, [error.userInfo[FBSDKGraphRequestErrorGraphErrorCode] integerValue]);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertEqual(1, requestCount);
  [FBSDKSettings setGraphErrorRecoveryDisabled:NO];
  [mockPiggybackManager stopMocking];
}
@end
