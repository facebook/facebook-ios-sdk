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

#import <XCTest/XCTest.h>

#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"

@interface FBSDKAuthenticationToken (Testing)

+ (void)setCurrentAuthenticationToken:(FBSDKAuthenticationToken *)token
               shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKProfile (Testing)

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKAuthenticationStatusUtility (Testing)

+ (void)_handleResponse:(NSURLResponse *)response;
+ (NSURL *)_requestURL;

@end

@interface FBSDKAuthenticationStatusUtilityTests : FBSDKTestCase

@end

@implementation FBSDKAuthenticationStatusUtilityTests

- (void)setUp
{
  [super setUp];
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:SampleAuthenticationToken.validToken shouldPostNotification:NO];
  [FBSDKAccessToken setCurrentAccessToken:SampleAccessToken.validToken shouldDispatchNotif:NO];
  [FBSDKProfile setCurrentProfile:SampleUserProfile.valid shouldPostNotification:NO];
}

// MARK: checkAuthenticationStatus

- (void)testCheckAuthenticationStatusWithNoToken
{
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:nil shouldPostNotification:NO];

  [FBSDKAuthenticationStatusUtility checkAuthenticationStatus];

  XCTAssertNotNil(FBSDKAccessToken.currentAccessToken, @"Access token should not be cleared");
  XCTAssertNotNil(FBSDKProfile.currentProfile, @"Profile should not be cleared");
}

// MARK: _requestURL

- (void)testRequestURL
{
  NSURL *url = [FBSDKAuthenticationStatusUtility _requestURL];

  XCTAssertEqualObjects(url.host, @"m.facebook.com");
  XCTAssertEqualObjects(url.path, @"/platform/oidc/status");

  NSDictionary *params = [FBSDKInternalUtility parametersFromFBURL:url];
  XCTAssertEqualObjects(params[@"id_token"], FBSDKAuthenticationToken.currentAuthenticationToken.tokenString, @"Incorrect ID token parameter in request url");
}

// MARK: _handleResponse

- (void)testHandleNotAuthorizedResponse
{
  NSURL *url = [NSURL URLWithString:@"m.facebook.com/platform/oidc/status/"];
  NSDictionary *header = @{@"fb-s" : @"not_authorized"};
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                            statusCode:200
                                                           HTTPVersion:nil
                                                          headerFields:header];

  [FBSDKAuthenticationStatusUtility _handleResponse:response];

  XCTAssertNil(FBSDKAuthenticationToken.currentAuthenticationToken, @"Authentication token should be cleared when not authorized");
  XCTAssertNil(FBSDKAccessToken.currentAccessToken, @"Access token should be cleared when not authorized");
  XCTAssertNil(FBSDKProfile.currentProfile, @"Profile should be cleared when not authorized");
}

- (void)testHandleConnectedResponse
{
  NSURL *url = [NSURL URLWithString:@"m.facebook.com/platform/oidc/status/"];
  NSDictionary *header = @{@"fb-s" : @"connected"};
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                            statusCode:200
                                                           HTTPVersion:nil
                                                          headerFields:header];

  [FBSDKAuthenticationStatusUtility _handleResponse:response];

  XCTAssertNotNil(FBSDKAuthenticationToken.currentAuthenticationToken, @"Authentication token should not be cleared when connected");
  XCTAssertNotNil(FBSDKAccessToken.currentAccessToken, @"Access token should not be cleared when connected");
  XCTAssertNotNil(FBSDKProfile.currentProfile, @"Profile should not be cleared when connected");
}

- (void)testHandleNoStatusResponse
{
  NSURL *url = [NSURL URLWithString:@"m.facebook.com/platform/oidc/status/"];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                            statusCode:200
                                                           HTTPVersion:nil
                                                          headerFields:@{}];

  [FBSDKAuthenticationStatusUtility _handleResponse:response];

  XCTAssertNotNil(FBSDKAuthenticationToken.currentAuthenticationToken, @"Authentication token should not be cleared when no status returned");
  XCTAssertNotNil(FBSDKAccessToken.currentAccessToken, @"Access token should not be cleared when no status returned");
  XCTAssertNotNil(FBSDKProfile.currentProfile, @"Profile should not be cleared when no status returned");
}

- (void)testHandleFailedResponse
{
  NSURL *url = [NSURL URLWithString:@"m.facebook.com/platform/oidc/status/"];
  NSDictionary *header = @{@"fb-s" : @"connected"};
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                            statusCode:401
                                                           HTTPVersion:nil
                                                          headerFields:header];

  [FBSDKAuthenticationStatusUtility _handleResponse:response];

  XCTAssertNotNil(FBSDKAuthenticationToken.currentAuthenticationToken, @"Authentication token should not be cleared when the request failed");
  XCTAssertNotNil(FBSDKAccessToken.currentAccessToken, @"Access token should not be cleared when the request failed");
  XCTAssertNotNil(FBSDKProfile.currentProfile, @"Profile should not be cleared when the request failed");
}

- (void)testHandleResponseWithFuzzyData
{
  NSURL *url = [NSURL URLWithString:@"m.facebook.com/platform/oidc/status/"];

  for (int i = 0; i < 100; i++) {
    // only strings allowed in HTTP header
    NSDictionary *header = @{
      @"fb-s" : [[Fuzzer random] description],
      @"some_header_key" : [[Fuzzer random] description],
    };

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:header];

    [FBSDKAuthenticationStatusUtility _handleResponse:response];
  }
}

@end
