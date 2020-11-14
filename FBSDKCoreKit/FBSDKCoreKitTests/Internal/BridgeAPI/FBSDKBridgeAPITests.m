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

@implementation FBSDKBridgeAPITests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];
  _api = [FBSDKBridgeAPI new];
}

- (void)tearDown
{
  _api = nil;
  [FBSDKLoginManager resetTestEvidence];

  [super tearDown];
}

// MARK: - Lifecycle Methods

// MARK: Will Resign Active

- (void)testWillResignActiveWithoutAuthSessionWithoutAuthSessionState
{
  [self.api applicationWillResignActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "Should not modify the auth session state if there is no auth session"
  );
}

- (void)testWillResignActiveWithAuthSessionWithoutAuthSessionState
{
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  [self.api applicationWillResignActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "Should not modify the auth session state unless the current state is 'started'"
  );
}

- (void)testWillResignActiveWithAuthSessionWithNonStartedAuthSessionState
{
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionShowAlert),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    self.api.authenticationSessionState = state.intValue;
    [self.api applicationWillResignActive:UIApplication.sharedApplication];
    XCTAssertEqual(
      self.api.authenticationSessionState,
      state.intValue,
      "Should not modify the auth session state unless the current state is 'started'"
    );
  }
}

- (void)testWillResignActiveWithAuthSessionWithStartedAuthSessionState
{
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  self.api.authenticationSessionState = FBSDKAuthenticationSessionStarted;
  [self.api applicationWillResignActive:UIApplication.sharedApplication];
  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionShowAlert,
    "Should change the auth state from 'started' to 'alert' before resigning activity"
  );
}

// MARK: Did Become Active

- (void)testUpdatingShowAlertStateForDidBecomeActiveWithoutAuthSession
{
  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionStarted),
    @(FBSDKAuthenticationSessionShowAlert),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    self.api.authenticationSessionState = state.intValue;
    [self.api applicationDidBecomeActive:UIApplication.sharedApplication];
    XCTAssertEqual(
      self.api.authenticationSessionState,
      state.intValue,
      "Should not modify the auth session state if there is no auth session"
    );
  }
}

- (void)testUpdatingShowAlertStateForDidBecomeActive
{
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = spy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionShowAlert;

  [self.api applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionShowWebBrowser,
    "Becoming active when the state is 'showAlert' should set the state to be 'showWebBrowser'"
  );
  XCTAssertEqual(spy.cancelCallCount, 0, "Becoming active when the state is 'showAlert' should not cancel the session");
  XCTAssertNotNil(self.api.authenticationSession, "Becoming active when the state is 'showAlert' should not destroy the session");
}

- (void)testUpdatingCancelledBySystemStateForDidBecomeActive
{
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = spy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionCanceledBySystem;

  [self.api applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionCanceledBySystem,
    "Becoming active when the state is 'canceledBySystem' should not change the state"
  );
  XCTAssertNil(
    self.api.authenticationSession,
    "Becoming active when the state is 'canceledBySystem' should destroy the session"
  );
  XCTAssertEqual(spy.cancelCallCount, 1, "Becoming active when the state is 'canceledBySystem' should cancel the session");
}

- (void)testCompletingWithCancelledBySystemStateForDidBecomeActive
{
  AuthenticationSessionSpy *spy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = spy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionCanceledBySystem;
  self.api.authenticationSessionCompletionHandler = ^(NSURL *callbackURL, NSError *error) {
    XCTAssertNil(callbackURL, "A completion triggered by becoming active in a canceled state should not have a callback URL");
    XCTAssertEqualObjects(
      error.domain,
      @"com.apple.AuthenticationServices.WebAuthenticationSession",
      "A completion triggered by becoming active in a canceled state should include an error"
    );
  };

  [self.api applicationDidBecomeActive:UIApplication.sharedApplication];
}

// MARK: Did Enter Background

- (void)testDidEnterBackgroundWithoutAuthSession
{
  self.api.active = YES;
  self.api.expectingBackground = YES;

  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionStarted),
    @(FBSDKAuthenticationSessionShowAlert),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    self.api.authenticationSessionState = state.intValue;
    [self.api applicationDidEnterBackground:UIApplication.sharedApplication];
    XCTAssertFalse(
      self.api.active,
      "Should mark a bridge api inactive when entering the background"
    );
    XCTAssertFalse(
      self.api.expectingBackground,
      "Should mark a bridge api as not expecting backgrounding when entering the background"
    );
  }
}

- (void)testDidEnterBackgroundInShowAlertState
{
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionShowAlert;

  [self.api applicationDidEnterBackground:UIApplication.sharedApplication];
  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionCanceledBySystem,
    "Should cancel the session when entering the background while showing an alert"
  );
}

- (void)testDidEnterBackgroundInNonShowAlertState
{
  self.api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy;

  NSArray *states = @[
    @(FBSDKAuthenticationSessionNone),
    @(FBSDKAuthenticationSessionStarted),
    @(FBSDKAuthenticationSessionShowWebBrowser),
    @(FBSDKAuthenticationSessionCanceledBySystem)
  ];

  for (NSNumber *state in states) {
    self.api.authenticationSessionState = state.intValue;
    [self.api applicationDidEnterBackground:UIApplication.sharedApplication];
    XCTAssertEqual(
      self.api.authenticationSessionState,
      state.intValue,
      "Should only modify the auth session state on backgrounding if it is showing an alert"
    );
  }
}

// MARK: Did Finish Launching With Options

- (void)testDidFinishLaunchingWithoutLaunchedUrlWithoutSourceApplication
{
  XCTAssertFalse(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:@{}],
    "Should not consider it a successful launch if there is no launch url or source application"
  );
}

- (void)testDidFinishLaunchingWithoutLaunchedUrlWithSourceApplication
{
  NSDictionary *options = @{ UIApplicationLaunchOptionsSourceApplicationKey : @"com.example" };
  XCTAssertFalse(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:options],
    "Should not consider it a successful launch if there is no launch url"
  );
}

- (void)testDidFinishLaunchingWithLaunchedUrlWithoutSourceApplication
{
  NSDictionary *options = @{ UIApplicationLaunchOptionsURLKey : self.sampleUrl };
  XCTAssertFalse(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:options],
    "Should not consider it a successful launch if there is no source application"
  );
}

- (void)testDidFinishLaunchingWithLaunchedUrlWithSourceApplication
{
  NSDictionary *options = @{
    UIApplicationLaunchOptionsURLKey : self.sampleUrl,
    UIApplicationLaunchOptionsSourceApplicationKey : sampleSource,
    UIApplicationLaunchOptionsAnnotationKey : sampleAnnotation
  };

  FBSDKLoginManager.stubbedOpenUrlSuccess = YES;

  XCTAssertTrue(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:options],
    "Should return the success value determined by the login manager's open url method"
  );

  XCTAssertEqualObjects(FBSDKLoginManager.capturedOpenUrl, self.sampleUrl, "Should pass the launch url to the login manager");
  XCTAssertEqualObjects(FBSDKLoginManager.capturedSourceApplication, sampleSource, "Should pass the source application to the login manager");
  XCTAssertEqualObjects(FBSDKLoginManager.capturedAnnotation, sampleAnnotation, "Should pass the annotation to the login manager");
}

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"http://example.com"];
}

static inline NSString *StringFromBool(BOOL value)
{
  return value ? @"YES" : @"NO";
}

NSString *const sampleSource = @"com.example";
NSString *const sampleAnnotation = @"foo";

@end
