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

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithValidUrlWithoutError
{
  OCMStub(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );

  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success);
    XCTAssertNil(error);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(self.sampleUrl, nil);

  OCMVerify(
    [self.partialMock application:OCMArg.any
                          openURL:self.sampleUrl
                sourceApplication:@"com.apple"
                       annotation:OCMArg.any]
  );
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidUrlWithoutError
{
  NSURL *url = [NSURL URLWithString:@" "];
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertNil(error);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  OCMReject(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );
  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(url, nil);
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithoutUrlWithoutError
{
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertNil(error);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  OCMReject(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(nil, nil);
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithValidUrlWithError
{
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  OCMReject(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );

  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(self.sampleUrl, self.sampleError);
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidUrlWithError
{
  NSURL *url = [NSURL URLWithString:@" "];
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  OCMReject(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );
  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(url, self.sampleError);
  [self verifyAuthenticationPropertiesReset];
}

- (void)testInvokingAuthSessionCompletionHandlerFromHandlerWithoutUrlWithError
{
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertFalse(success);
    XCTAssertEqualObjects(error, self.sampleError);
  };
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;

  OCMReject(
    [self.partialMock application:OCMArg.any
                          openURL:OCMArg.any
                sourceApplication:OCMArg.any
                       annotation:OCMArg.any]
  );
  [self.api setSessionCompletionHandlerFromHandler:handler];
  self.api.authenticationSessionCompletionHandler(nil, self.sampleError);
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
