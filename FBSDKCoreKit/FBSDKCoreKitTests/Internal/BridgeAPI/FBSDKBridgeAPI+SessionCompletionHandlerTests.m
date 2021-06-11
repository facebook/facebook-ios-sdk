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

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests (SessionCompletionTests)

// MARK: - Setting Session Completion Handler

- (NSError *)loginCancellationErrorWithURL:(NSURL *)url
{
  NSString *errorMessage = [[NSString alloc]
                            initWithFormat:@"Login attempt cancelled by alternate call to openURL from: %@",
                            url];
  return [[NSError alloc]
          initWithDomain:FBSDKErrorDomain
          code:FBSDKErrorBridgeAPIInterruption
          userInfo:@{FBSDKErrorLocalizedDescriptionKey : errorMessage}];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithValidUrlWithoutError
{
  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    if (callCount == 0) {
      XCTAssertTrue(success);
      XCTAssertNil(error);
    } else {
      XCTAssertFalse(success, "Should complete with the expected failure status");
      XCTAssertEqualObjects(
        error,
        [self loginCancellationErrorWithURL:self.sampleUrl],
        "Should complete with the expected error"
      );
    }
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  [self.api setSessionCompletionHandlerFromHandler:handler];

  self.api.authenticationSessionCompletionHandler(self.sampleUrl, nil);
  XCTAssertEqual(callCount, 2, "Should invoke the completion twice");
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidUrlWithoutError
{
  NSURL *url = [NSURL URLWithString:@" "];

  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertNil(error);
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(url, nil);
  XCTAssertEqual(callCount, 1, "Should only invoke the completion once");
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithoutUrlWithoutError
{
  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertNil(error);
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(nil, nil);
  XCTAssertEqual(callCount, 1, "Should only invoke the completion once");
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithValidUrlWithError
{
  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(self.sampleUrl, self.sampleError);
  XCTAssertEqual(callCount, 1, "Should only invoke the completion once");
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidUrlWithError
{
  NSURL *url = [NSURL URLWithString:@" "];

  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(url, self.sampleError);
  XCTAssertEqual(callCount, 1, "Should only invoke the completion once");
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithoutUrlWithError
{
  __block int callCount = 0;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
    callCount++;
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(nil, self.sampleError);
  XCTAssertEqual(callCount, 1, "Should only invoke the completion once");
  [self verifyAuthenticationPropertiesReset];
}

// MARK: - Helpers

- (void)verifyAuthenticationPropertiesReset
{
  XCTAssertNil(self.api.authenticationSession);
  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertEqual(self.api.authenticationSessionState, FBSDKAuthenticationSessionNone);
}

@end
