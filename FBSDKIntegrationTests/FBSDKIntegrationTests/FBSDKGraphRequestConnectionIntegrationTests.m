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
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKTestUsersManager.h>

#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"

@interface FBSDKGraphRequestConnectionIntegrationTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKGraphRequestConnectionIntegrationTests

- (void)testFetchMe {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{ @"fields": @"id" }
                                                                tokenString:token.tokenString
                                                                    version:nil
                                                                 HTTPMethod:nil];
  [conn addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error, "@unexpected error: %@", error);
    XCTAssertNotNil(result);
    [expectation fulfill];
  }];
  [conn start];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];
}

- (void)testFetchLikesWithCurrentToken {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  FBSDKAccessToken *token = [self getTokenWithPermissions:[NSSet setWithObject:@"user_likes"]];
  [FBSDKAccessToken setCurrentAccessToken:token];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/likes"
                                                                 parameters:@{ @"fields": @"id" }];
  [conn addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error, "@unexpected error: %@", error);
    XCTAssertNotNil(result);
    [expectation fulfill];
  }];
  [conn start];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];
}

- (void)testRefreshToken {
  XCTestExpectation *expectation = [self expectationWithDescription:@"token refreshed"];
  // create token locally without permissions
  FBSDKAccessToken *token = [self getTokenWithPermissions:[NSSet setWithObject:@""]];
  [FBSDKAccessToken setCurrentAccessToken:token];

  XCTAssertFalse([[FBSDKAccessToken currentAccessToken] hasGranted: @"public_profile"], "Permission is not expected to be granted.");

  // refresh token not only should succeed but also update permissions data
  [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error, "@unexpected error: %@", error);
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
    XCTAssertTrue([[FBSDKAccessToken currentAccessToken] hasGranted: @"public_profile"], "Permission is expected to be granted.");
  }];
}

- (void)testCancel {
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"zuck/picture" parameters:nil tokenString:nil version:@"v2.0" HTTPMethod:@"GET"];
  [conn addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertFalse(YES, @"did not expect to his completion handler since the connection should have been cancelled");
    [blocker signal];
  }];
  [conn start];
  [conn cancel];

  XCTAssertFalse([blocker waitWithTimeout:5], @"expected blocker timeout indicating cancellation.");
}

#pragma mark - batch requests

- (void)testBatchSimple
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:3];
  FBSDKAccessToken *token = [self getTokenWithPermissions:[NSSet setWithObject:@"user_likes"]];
  [FBSDKAccessToken setCurrentAccessToken:token];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/likes"
                                                     parameters:@{ @"fields":@"id" }]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   [blocker signal];
 }];
  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                     parameters:@{ @"fields":@"id" }]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   [blocker signal];
 }];

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *body = [[NSString alloc] initWithData:request.OHHTTPStubs_HTTPBody encoding:NSUTF8StringEncoding];
    if ([body rangeOfString:@"likes"].location != NSNotFound) {
      [blocker signal];
      XCTAssertEqual(1, [body countOfSubstring:@"access_token"]);
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  [conn start];
  XCTAssertTrue([blocker waitWithTimeout:10], @"batch request didn't finish or wasn't able to observe like batch request.");
  [OHHTTPStubs removeAllStubs];
}

// test with no current access token, and different tokens specified in batch.
- (void)testBatchMixedTokens
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken *tokenWithLikes;
  __block FBSDKAccessToken *tokenWithEmail;
  [[self testUsersManager] requestTestAccountTokensWithArraysOfPermissions:@[
                                                                             [NSSet setWithObject:@"user_likes"],
                                                                             [NSSet setWithObject:@"email"]                                                                            ]
                                                          createIfNotFound:YES
                                                         completionHandler:^(NSArray *tokens, NSError *error) {
                                                           tokenWithLikes = tokens[0];
                                                           tokenWithEmail = tokens[1];
                                                           [blocker signal];
                                                         }];
  XCTAssertTrue([blocker waitWithTimeout:8], @"failed to fetch two test users for testing");

  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:2];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/likes"
                                                     parameters:@{ @"fields":@"id" }
                                                    tokenString:tokenWithLikes.tokenString
                                                        version:nil
                                                     HTTPMethod:nil]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error, @"failed for %@", tokenWithLikes.tokenString);
   [blocker signal];
 }];
  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=email"
                                                     parameters:nil
                                                    tokenString:tokenWithEmail.tokenString
                                                        version:nil
                                                     HTTPMethod:nil]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error, @"failed for %@", tokenWithEmail.tokenString);
   XCTAssertEqualObjects(tokenWithEmail.userID, result[@"id"]);
   [blocker signal];
 }];

  [conn start];
  XCTAssertTrue([blocker waitWithTimeout:10], @"batch request didn't finish.");
}

- (void)testBatchPhotoUpload
{
  FBSDKAccessToken *token = [self getTokenWithPermissions:[NSSet setWithObjects:@"publish_actions", nil]];
  [FBSDKAccessToken setCurrentAccessToken:token];
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:4];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];

  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/photos"
                                                     parameters:@{ @"picture" : [self createSquareTestImage:120] }
                                                     HTTPMethod:@"POST"]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   XCTAssertNil(result[@"id"], @"unexpected post id since omit_response_on_success should default to YES");
   [blocker signal];
 } batchEntryName:@"uploadRequest1"];

  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/photos"
                                                     parameters:@{ @"picture" : [self createSquareTestImage:150]}
                                                     HTTPMethod:@"POST"]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   // expect an id since we specify omit_response_on_success
   XCTAssertNotNil(result[@"id"], @"expected id since we specified omit_response_on_success");
   [blocker signal];
 } batchParameters:@{ @"name" : @"uploadRequest2",
                      @"omit_response_on_success" : @(NO)}];

  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"{result=uploadRequest1:$.id}" parameters:@{ @"fields" : @"id,width" }]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   XCTAssertEqualObjects(@(120), result[@"width"]);
   [blocker signal];
 }];

  [conn addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"{result=uploadRequest2:$.id}" parameters:@{ @"fields" : @"id,width" }]
 completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
   XCTAssertNil(error);
   XCTAssertEqualObjects(@(150), result[@"width"]);
   [blocker signal];
 }];
  [conn start];
  XCTAssertTrue([blocker waitWithTimeout:25], @"batch request didn't finish.");
}

// issue requests that will fail and make sure error is as expected.
- (void)testErrorUnpacking {
  [FBSDKAccessToken setCurrentAccessToken:nil];
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:3];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];

  FBSDKGraphRequestHandler assertMissingTokenErrorHandler = ^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    /* error JSON should be :
     body =     {
     error =         {
     code = 2500;
     message = "An active access token must be used to query information about the current user.";
     type = OAuthException;
     };
     };
     code = 400;
     */
    XCTAssertEqual(FBSDKGraphRequestGraphAPIErrorCode, error.code);
    XCTAssertEqualObjects(@(400), error.userInfo[FBSDKGraphRequestErrorParsedJSONResponseKey][@"code"]);
    XCTAssertEqualObjects(@(400), error.userInfo[FBSDKGraphRequestErrorHTTPStatusCodeKey]);
    XCTAssertEqualObjects(@(2500), error.userInfo[FBSDKGraphRequestErrorParsedJSONResponseKey][@"body"][@"error"][@"code"]);
    XCTAssertEqualObjects(@(2500), error.userInfo[FBSDKGraphRequestErrorGraphErrorCode]);
    XCTAssertTrue([error.userInfo[FBSDKErrorDeveloperMessageKey] rangeOfString:@"active access token"].location != NSNotFound);
    XCTAssertNil(error.userInfo[NSLocalizedDescriptionKey]);
    XCTAssertNil(error.userInfo[FBSDKGraphRequestErrorGraphErrorSubcode]);
    [blocker signal];
  };
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{ @"fields": @"id" }];
  [request setGraphErrorRecoveryDisabled:YES];

  [conn addRequest:request completionHandler:assertMissingTokenErrorHandler];
  [conn start];

  FBSDKGraphRequestConnection *conn2 = [[FBSDKGraphRequestConnection alloc] init];
  [conn2 addRequest:request completionHandler:assertMissingTokenErrorHandler];
  [conn2 addRequest:request completionHandler:assertMissingTokenErrorHandler];
  [conn2 start];

  XCTAssertTrue([blocker waitWithTimeout:5], @"request timeout");

  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  FBSDKAccessToken *accessToken = [self getTokenWithPermissions:[NSSet setWithObject:@"publish_actions"]];
  FBSDKGraphRequest *feedRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/feed"
                                                                     parameters:@{ @"fields": @"" }
                                                                    tokenString:accessToken.tokenString
                                                                        version:nil
                                                                     HTTPMethod:@"POST"];
  FBSDKGraphRequestConnection *conn3 = [[FBSDKGraphRequestConnection alloc] init];
  [conn3 addRequest:feedRequest
  completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(@"Invalid parameter", error.userInfo[FBSDKErrorDeveloperMessageKey]);
    XCTAssertEqualObjects(@(100), error.userInfo[FBSDKGraphRequestErrorGraphErrorCode]);
    XCTAssertEqualObjects(@(1349125), error.userInfo[FBSDKGraphRequestErrorGraphErrorSubcode]);
    XCTAssertEqualObjects(@"Missing message or attachment.", error.localizedDescription);
    XCTAssertEqualObjects(error.localizedDescription, error.userInfo[FBSDKErrorLocalizedDescriptionKey]);
    XCTAssertEqualObjects(@"Missing Message Or Attachment", error.userInfo[FBSDKErrorLocalizedTitleKey]);
    [blocker signal];
  }];

  [conn3 start];
  XCTAssertTrue([blocker waitWithTimeout:5], @"request timeout");
}

- (void)testFetchGenderLocale {
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed request"];
  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
  __block NSString *originalGender;
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{ @"fields": @"gender" }
                                                                tokenString:token.tokenString
                                                                    version:nil
                                                                 HTTPMethod:nil];
  [conn addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error, "@unexpected error: %@", error);
    XCTAssertNotNil(result);
    originalGender = result[@"gender"];
    [expectation fulfill];
  }];
  [conn start];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];

  // now start another request with de_DE locale and make sure gender response is different
  XCTestExpectation *expectation2 = [self expectationWithDescription:@"completed request2"];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                    parameters:@{ @"fields": @"gender",
                                                  @"locale" : @"de_DE" }
                                   tokenString:token.tokenString
                                       version:nil
                                    HTTPMethod:nil] startWithCompletionHandler:
  ^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error, "@unexpected error: %@", error);
    XCTAssertNotNil(result);
    XCTAssertFalse([originalGender isEqualToString:result[@"gender"]]);
    [expectation2 fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];

}
@end
