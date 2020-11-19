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
  _partialMock = OCMPartialMock(_api);
}

- (void)tearDown
{
  _api = nil;
  [_partialMock stopMocking];
  _partialMock = nil;
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
  AuthenticationSessionSpy *authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = authSessionSpy;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionShowAlert;

  [self.api applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionShowWebBrowser,
    "Becoming active when the state is 'showAlert' should set the state to be 'showWebBrowser'"
  );
  XCTAssertEqual(authSessionSpy.cancelCallCount, 0, "Becoming active when the state is 'showAlert' should not cancel the session");
  XCTAssertNotNil(self.api.authenticationSession, "Becoming active when the state is 'showAlert' should not destroy the session");
}

- (void)testUpdatingCancelledBySystemStateForDidBecomeActive
{
  AuthenticationSessionSpy *authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = authSessionSpy;
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
  XCTAssertEqual(authSessionSpy.cancelCallCount, 1, "Becoming active when the state is 'canceledBySystem' should cancel the session");
}

- (void)testCompletingWithCancelledBySystemStateForDidBecomeActive
{
  AuthenticationSessionSpy *authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy;
  self.api.authenticationSession = authSessionSpy;
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

// MARK: - Open Url

- (void)testOpenUrlWithMissingSender
{
  [self.api openURL:self.sampleUrl
             sender:nil
            handler:^(BOOL _success, NSError *_Nullable error) {}];

  XCTAssertTrue(self.api.expectingBackground, "Should set expecting background to true when opening a URL");
  XCTAssertNil(self.api.pendingUrlOpen, "Should not set the pending url opener if there is no sender");
}

- (void)testOpenUrlWithSender
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  [self.api openURL:self.sampleUrl
             sender:urlOpener
            handler:^(BOOL _success, NSError *_Nullable error) {}];

  XCTAssertTrue(self.api.expectingBackground, "Should set expecting background to true when opening a URL");
  XCTAssertEqual(self.api.pendingUrlOpen, urlOpener, "Should set the pending url opener to the sender");
}

- (void)testOpenUrlWithVersionBelow10WhenApplicationOpens
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  BOOL applicationOpensSuccessfully = YES;
  [self stubIsOperatingSystemVersionAtLeast:iOS10Version with:NO];
  [self stubOpenURLWith:applicationOpensSuccessfully];

  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testOpenUrlWithVersionBelow10WhenApplicationDoesNotOpen
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  BOOL applicationOpensSuccessfully = NO;
  [self stubIsOperatingSystemVersionAtLeast:iOS10Version with:NO];
  [self stubOpenURLWith:applicationOpensSuccessfully];

  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testOpenUrlWhenApplicationOpens
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  BOOL applicationOpensSuccessfully = YES;
  [self stubIsOperatingSystemVersionAtLeast:iOS10Version with:YES];
  [self stubOpenUrlOptionsCompletionHandlerWithPerformCompletion:YES
                                               completionSuccess:applicationOpensSuccessfully];

  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testOpenUrlWhenApplicationDoesNotOpen
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  BOOL applicationOpensSuccessfully = NO;
  [self stubIsOperatingSystemVersionAtLeast:iOS10Version with:YES];
  [self stubOpenUrlOptionsCompletionHandlerWithPerformCompletion:YES
                                               completionSuccess:applicationOpensSuccessfully];

  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

// MARK: - Request completion block

- (void)testRequestCompletionBlockCalledWithSuccess
{
  FakeBridgeApiRequest *request = [FakeBridgeApiRequest requestWithURL:self.sampleUrl];
  FBSDKBridgeAPIResponseBlock responseBlock = ^void (FBSDKBridgeAPIResponse *response) {
    XCTFail("Should not call the response block when the request completion is called with success");
  };
  self.api.pendingRequest = request;
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {};

  FBSDKSuccessBlock completion = [self.api _bridgeAPIRequestCompletionBlockWithRequest:request
                                                                            completion:responseBlock];
  // With Error
  completion(true, self.sampleError);
  [self assertPendingPropertiesNotCleared];

  // Without Error
  completion(true, nil);
  [self assertPendingPropertiesNotCleared];
}

- (void)testRequestCompletionBlockWithNonHttpRequestCalledWithoutSuccess
{
  FakeBridgeApiRequest *request = [FakeBridgeApiRequest requestWithURL:self.sampleUrl scheme:@"file"];
  FBSDKBridgeAPIResponseBlock responseBlock = ^void (FBSDKBridgeAPIResponse *response) {
    XCTAssertEqualObjects(response.request, request, "The response should contain the original request");
    XCTAssertEqual(
      response.error.code,
      FBSDKErrorAppVersionUnsupported,
      "The response should contain the expected error code"
    );
    XCTAssertEqualObjects(
      response.error.userInfo[FBSDKErrorDeveloperMessageKey],
      @"the app switch failed because the destination app is out of date",
      "The response should contain the expected error message"
    );
  };
  self.api.pendingRequest = request;
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {};

  FBSDKSuccessBlock completion = [self.api _bridgeAPIRequestCompletionBlockWithRequest:request
                                                                            completion:responseBlock];
  // With Error
  completion(false, self.sampleError);
  [self assertPendingPropertiesCleared];

  // Without Error
  completion(false, nil);
  [self assertPendingPropertiesCleared];
}

- (void)testRequestCompletionBlockWithHttpRequestCalledWithoutSuccess
{
  FakeBridgeApiRequest *request = [FakeBridgeApiRequest requestWithURL:self.sampleUrl scheme:@"https"];
  FBSDKBridgeAPIResponseBlock responseBlock = ^void (FBSDKBridgeAPIResponse *response) {
    XCTAssertEqualObjects(response.request, request, "The response should contain the original request");
    XCTAssertEqual(
      response.error.code,
      FBSDKErrorBrowserUnavailable,
      "The response should contain the expected error code"
    );
    XCTAssertEqualObjects(
      response.error.userInfo[FBSDKErrorDeveloperMessageKey],
      @"the app switch failed because the browser is unavailable",
      "The response should contain the expected error message"
    );
  };
  self.api.pendingRequest = request;
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {};

  FBSDKSuccessBlock completion = [self.api _bridgeAPIRequestCompletionBlockWithRequest:request
                                                                            completion:responseBlock];
  // With Error
  completion(false, self.sampleError);
  [self assertPendingPropertiesCleared];

  // Without Error
  completion(false, nil);
  [self assertPendingPropertiesCleared];
}

// MARK: - Safari View Controller Delegate Methods

- (void)testSafariVcDidFinishWithPendingUrlOpener
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  self.api.pendingUrlOpen = urlOpener;
  self.api.safariViewController = ViewControllerSpy.makeDefaultSpy;

  // Funny enough there's no check that the safari view controller from the delegate
  // is the same instance stored in the safariViewController property
  [self.api safariViewControllerDidFinish:self.api.safariViewController];

  XCTAssertNil(self.api.pendingUrlOpen, "Should remove the reference to the pending url opener");
  XCTAssertNil(
    self.api.safariViewController,
    "Should remove the reference to the safari view controller when the delegate method is called"
  );

  OCMVerify([_partialMock _cancelBridgeRequest]);
  XCTAssertTrue(urlOpener.openUrlWasCalled, "Should ask the opener to open a url (even though there is not one provided");
  XCTAssertNil(FBSDKLoginManager.capturedOpenUrl, "The url opener should be called with nil arguments");
  XCTAssertNil(FBSDKLoginManager.capturedSourceApplication, "The url opener should be called with nil arguments");
  XCTAssertNil(FBSDKLoginManager.capturedAnnotation, "The url opener should be called with nil arguments");
}

- (void)testSafariVcDidFinishWithoutPendingUrlOpener
{
  self.api.safariViewController = ViewControllerSpy.makeDefaultSpy;

  // Funny enough there's no check that the safari view controller from the delegate
  // is the same instance stored in the safariViewController property
  [self.api safariViewControllerDidFinish:self.api.safariViewController];

  XCTAssertNil(self.api.pendingUrlOpen, "Should remove the reference to the pending url opener");
  XCTAssertNil(
    self.api.safariViewController,
    "Should remove the reference to the safari view controller when the delegate method is called"
  );

  OCMVerify([_partialMock _cancelBridgeRequest]);
  XCTAssertNil(FBSDKLoginManager.capturedOpenUrl, "The url opener should not be called");
  XCTAssertNil(FBSDKLoginManager.capturedSourceApplication, "The url opener should not be called");
  XCTAssertNil(FBSDKLoginManager.capturedAnnotation, "The url opener should not be called");
}

// MARK: - ContainerViewController Delegate Methods

- (void)testViewControllerDidDisappearWithSafariViewController
{
  UIViewController *viewControllerSpy = ViewControllerSpy.makeDefaultSpy;
  self.api.safariViewController = viewControllerSpy;
  FBSDKContainerViewController *container = [FBSDKContainerViewController new];

  [self.api viewControllerDidDisappear:container animated:NO];

  OCMVerify([self.loggerClassMock singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"**ERROR**:\n The SFSafariViewController's parent view controller was dismissed.\nThis can happen if you are triggering login from a UIAlertController. Instead, make sure your top most view controller will not be prematurely dismissed."]);
  OCMVerify([_partialMock safariViewControllerDidFinish:viewControllerSpy]);
}

- (void)testViewControllerDidDisappearWithoutSafariViewController
{
  FBSDKContainerViewController *container = [FBSDKContainerViewController new];

  OCMReject([self.loggerClassMock singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:OCMArg.any]);
  OCMReject([_partialMock safariViewControllerDidFinish:OCMArg.any]);

  [self.api viewControllerDidDisappear:container animated:NO];
}

// MARK: - Bridge Response Url Handling

- (void)testHandlingBridgeResponseWithInvalidScheme
{
  [self stubBridgeApiResponseWithUrlCreation];
  [self stubAppUrlSchemeWith:@"foo"];

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.sampleUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with an invalid url scheme");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithInvalidHost
{
  [self stubBridgeApiResponseWithUrlCreation];
  [self stubAppUrlSchemeWith:self.sampleUrl.scheme];

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.sampleUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with an invalid url host");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingRequest
{
  [self stubBridgeApiResponseWithUrlCreation];
  [self stubAppUrlSchemeWith:self.validBridgeResponseUrl.scheme];

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with a missing request");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingCompletionBlock
{
  [self stubBridgeApiResponseWithUrlCreation];
  [self stubAppUrlSchemeWith:self.validBridgeResponseUrl.scheme];
  self.api.pendingRequest = [FakeBridgeApiRequest requestWithURL:self.sampleUrl];

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should successfully handle bridge api response url with a missing completion block");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithBridgeResponse
{
  FBSDKBridgeAPIResponse *response = (FBSDKBridgeAPIResponse *)NSObject.new;
  OCMStub(
    ClassMethod(
      [self.bridgeApiResponseClassMock bridgeAPIResponseWithRequest:OCMArg.any
                                                        responseURL:OCMArg.any
                                                  sourceApplication:OCMArg.any
                                                              error:[OCMArg setTo:nil]]
    )
  )
  .andReturn(response);

  [self stubAppUrlSchemeWith:self.validBridgeResponseUrl.scheme];
  self.api.pendingRequest = [FakeBridgeApiRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *_response) {
    XCTAssertEqualObjects(_response, response, "Should invoke the completion with the expected bridge api response");
  };
  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should successfully handle creation of a bridge api response");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithBridgeError
{
  FBSDKBridgeAPIResponse *response = (FBSDKBridgeAPIResponse *)NSObject.new;

  // First attempt to create response populates error and returns nil response.
  OCMStub(
    ClassMethod(
      [self.bridgeApiResponseClassMock bridgeAPIResponseWithRequest:OCMArg.any
                                                        responseURL:OCMArg.any
                                                  sourceApplication:OCMArg.any
                                                              error:[OCMArg setTo:self.sampleError]]
    )
  );

  // Second (different) attempt to create response takes error and returns response
  OCMStub(ClassMethod([self.bridgeApiResponseClassMock bridgeAPIResponseWithRequest:OCMArg.any error:self.sampleError]))
  .andReturn(response);

  [self stubAppUrlSchemeWith:self.validBridgeResponseUrl.scheme];
  self.api.pendingRequest = [FakeBridgeApiRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *_response) {
    XCTAssertEqualObjects(_response, response, "Should invoke the completion with the expected bridge api response");
  };
  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should retry creation of a bridge api response if the first attempt has an error");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingResponseMissingError
{
  // First attempt to create response returns nil
  [self stubBridgeApiResponseWithUrlCreation];

  // Second (different) attempt to create response returns nil
  OCMStub(ClassMethod([self.bridgeApiResponseClassMock bridgeAPIResponseWithRequest:OCMArg.any error:OCMArg.any]));

  [self stubAppUrlSchemeWith:self.validBridgeResponseUrl.scheme];
  self.api.pendingRequest = [FakeBridgeApiRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {
    XCTFail("Should not invoke pending completion handler");
  };
  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should return false when a bridge response cannot be created");
  [self assertPendingPropertiesCleared];
}

// MARK: - Helpers

- (void)assertPendingPropertiesCleared
{
  XCTAssertNil(
    self.api.pendingRequest,
    "Should clear the pending request"
  );
  XCTAssertNil(
    self.api.pendingRequestCompletionBlock,
    "Should clear the pending request completion block"
  );
}

- (void)assertPendingPropertiesNotCleared
{
  XCTAssertNotNil(
    self.api.pendingRequest,
    "Should not clear the pending request"
  );
  XCTAssertNotNil(
    self.api.pendingRequestCompletionBlock,
    "Should not clear the pending request completion block"
  );
}

/// Stubs `FBSDKBridgeAPI`'s  `bridgeAPIResponseWithRequest:responseURL:sourceApplication:error:` to keep it from being called
- (void)stubBridgeApiResponseWithUrlCreation
{
  OCMStub(
    ClassMethod(
      [self.bridgeApiResponseClassMock bridgeAPIResponseWithRequest:OCMArg.any
                                                        responseURL:OCMArg.any
                                                  sourceApplication:OCMArg.any
                                                              error:[OCMArg setTo:nil]]
    )
  );
}

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"http://example.com"];
}

- (NSError *)sampleError
{
  return [NSError errorWithDomain:self.name code:0 userInfo:nil];
}

static inline NSString *StringFromBool(BOOL value)
{
  return value ? @"YES" : @"NO";
}

- (NSURL *)validBridgeResponseUrl
{
  return [NSURL URLWithString:@"http://bridge"];
}

NSString *const sampleSource = @"com.example";
NSString *const sampleAnnotation = @"foo";
NSOperatingSystemVersion const iOS10Version = { .majorVersion = 10, .minorVersion = 0, .patchVersion = 0 };

@end
