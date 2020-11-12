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

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"

@interface FBSDKBridgeAPITests : FBSDKTestCase
@end

@implementation FBSDKBridgeAPITests

// MARK: - Lifecycle Methods

- (void)testWillResignActiveWithoutAuthSessionWithoutAuthSessionState
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  [api applicationWillResignActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "Should not modify the auth session state if there is no auth session"
  );
}

- (void)testWillResignActiveWithAuthSessionWithoutAuthSessionState
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  [api applicationWillResignActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "Should not modify the auth session state unless the current state is 'started'"
  );
}

- (void)testWillResignActiveWithAuthSessionWithNonStartedAuthSessionState
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionShowAlert),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    api.authenticationSessionState = state.intValue;
    [api applicationWillResignActive:UIApplication.sharedApplication];
    XCTAssertEqual(
      api.authenticationSessionState,
      state.intValue,
      "Should not modify the auth session state unless the current state is 'started'"
    );
  }
}

- (void)testWillResignActiveWithAuthSessionWithStartedAuthSessionState
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  [api applicationWillResignActive:UIApplication.sharedApplication];
  XCTAssertEqual(
    api.authenticationSessionState,
    FBSDKAuthenticationSessionShowAlert,
    "Should change the auth state from 'started' to 'alert' before resigning activity"
  );
}

- (void)testUpdatingShowAlertStateForDidBecomeActiveWithoutAuthSession
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionStarted),
    @(FBSDKAuthenticationSessionShowAlert),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    api.authenticationSessionState = state.intValue;
    [api applicationDidBecomeActive:UIApplication.sharedApplication];
    XCTAssertEqual(
      api.authenticationSessionState,
      state.intValue,
      "Should not modify the auth session state if there is no auth session"
    );
  }
}

- (void)testUpdatingShowAlertStateForDidBecomeActive
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  api.authenticationSession = spy;
  api.authenticationSessionState = FBSDKAuthenticationSessionShowAlert;

  [api applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    api.authenticationSessionState,
    FBSDKAuthenticationSessionShowWebBrowser,
    "Becoming active when the state is 'showAlert' should set the state to be 'showWebBrowser'"
  );
  XCTAssertEqual(spy.cancelCallCount, 0, "Becoming active when the state is 'showAlert' should not cancel the session");
  XCTAssertNotNil(api.authenticationSession, "Becoming active when the state is 'showAlert' should not destroy the session");
}

- (void)testUpdatingCancelledBySystemStateForDidBecomeActive
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  api.authenticationSession = spy;
  api.authenticationSessionState = FBSDKAuthenticationSessionCanceledBySystem;

  [api applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    api.authenticationSessionState,
    FBSDKAuthenticationSessionCanceledBySystem,
    "Becoming active when the state is 'canceledBySystem' should not change the state"
  );
  XCTAssertNil(
    api.authenticationSession,
    "Becoming active when the state is 'canceledBySystem' should destroy the session"
  );
  XCTAssertEqual(spy.cancelCallCount, 1, "Becoming active when the state is 'canceledBySystem' should cancel the session");
}

- (void)testCompletingWithCancelledBySystemStateForDidBecomeActive
{
  FBSDKBridgeAPI *api = [FBSDKBridgeAPI new];
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  api.authenticationSession = spy;
  api.authenticationSessionState = FBSDKAuthenticationSessionCanceledBySystem;
  api.authenticationSessionCompletionHandler = ^(NSURL *callbackURL, NSError *error) {
    XCTAssertNil(callbackURL, "A completion triggered by becoming active in a canceled state should not have a callback URL");
    XCTAssertEqualObjects(
      error.domain,
      @"com.apple.AuthenticationServices.WebAuthenticationSession",
      "A completion triggered by becoming active in a canceled state should include an error"
    );
  };

  [api applicationDidBecomeActive:UIApplication.sharedApplication];
}

@end
