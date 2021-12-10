/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests (SessionCompletionTests)

// MARK: - Setting Session Completion Handler

- (NSError *)loginCancellationErrorWithURL:(NSURL *)url
{
  NSString *errorMessage = [[NSString alloc]
                            initWithFormat:@"Login attempt cancelled by alternate call to openURL from: %@",
                            url];
  return [self.errorFactory errorWithCode:FBSDKErrorBridgeAPIInterruption
                                 userInfo:@{FBSDKErrorLocalizedDescriptionKey : errorMessage}
                                  message:errorMessage
                          underlyingError:nil];
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
