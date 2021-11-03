/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];

  self.appURLSchemeProvider = [TestInternalUtility new];
  self.logger = [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
  self.urlOpener = [[TestInternalURLOpener alloc] initWithCanOpenUrl:YES];
  self.bridgeAPIResponseFactory = [TestBridgeAPIResponseFactory new];
  self.errorFactory = [TestErrorFactory new];

  [self configureSDK];

  self.api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                                  logger:self.logger
                                               urlOpener:self.urlOpener
                                bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                         frameworkLoader:self.frameworkLoader
                                    appURLSchemeProvider:self.appURLSchemeProvider
                                            errorFactory:self.errorFactory];
}

- (void)tearDown
{
  [FBSDKLoginManager resetTestEvidence];
  [TestLogger reset];

  [super tearDown];
}

- (void)configureSDK
{
  TestBackgroundEventLogger *backgroundEventLogger = [[TestBackgroundEventLogger alloc] initWithInfoDictionaryProvider:[TestBundle new]
                                                                                                           eventLogger:[TestAppEvents new]];
  TestServerConfigurationProvider *serverConfigurationProvider = [[TestServerConfigurationProvider alloc]
                                                                  initWithConfiguration:ServerConfigurationFixtures.defaultConfig];
  FBSDKApplicationDelegate *delegate = [[FBSDKApplicationDelegate alloc] initWithNotificationCenter:[TestNotificationCenter new]
                                                                                        tokenWallet:TestAccessTokenWallet.class
                                                                                           settings:[TestSettings new]
                                                                                     featureChecker:[TestFeatureManager new]
                                                                                          appEvents:[TestAppEvents new]
                                                                        serverConfigurationProvider:serverConfigurationProvider
                                                                                              store:[UserDefaultsSpy new]
                                                                          authenticationTokenWallet:TestAuthenticationTokenWallet.class
                                                                                    profileProvider:TestProfileProvider.class
                                                                              backgroundEventLogger:backgroundEventLogger
                                                                                    paymentObserver:[TestPaymentObserver new]];
  [delegate initializeSDKWithLaunchOptions:@{}];
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
  NSDictionary<NSString *, id> *options = @{ UIApplicationLaunchOptionsSourceApplicationKey : @"com.example" };
  XCTAssertFalse(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:options],
    "Should not consider it a successful launch if there is no launch url"
  );
}

- (void)testDidFinishLaunchingWithLaunchedUrlWithoutSourceApplication
{
  NSDictionary<NSString *, id> *options = @{ UIApplicationLaunchOptionsURLKey : self.sampleUrl };
  XCTAssertFalse(
    [self.api application:UIApplication.sharedApplication didFinishLaunchingWithOptions:options],
    "Should not consider it a successful launch if there is no source application"
  );
}

- (void)testDidFinishLaunchingWithLaunchedUrlWithSourceApplication
{
  NSDictionary<NSString *, id> *options = @{
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
  XCTAssertNil(self.api.pendingURLOpen, "Should not set the pending url opener if there is no sender");
}

- (void)testOpenUrlWithSender
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  [self.api openURL:self.sampleUrl
             sender:urlOpener
            handler:^(BOOL _success, NSError *_Nullable error) {}];

  XCTAssertTrue(self.api.expectingBackground, "Should set expecting background to true when opening a URL");
  XCTAssertEqual(self.api.pendingURLOpen, urlOpener, "Should set the pending url opener to the sender");
}

- (void)testOpenUrlWithVersionBelow10WhenApplicationOpens
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  TestProcessInfo *processInfo = [[TestProcessInfo alloc]
                                  initWithStubbedOperatingSystemCheckResult:NO];
  self.api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:processInfo
                                                  logger:self.logger
                                               urlOpener:self.urlOpener
                                bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                         frameworkLoader:self.frameworkLoader
                                    appURLSchemeProvider:self.appURLSchemeProvider
                                            errorFactory:self.errorFactory];

  BOOL applicationOpensSuccessfully = YES;
  [self.urlOpener stubOpenWithUrl:self.sampleUrl success:applicationOpensSuccessfully];

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
  TestProcessInfo *processInfo = [[TestProcessInfo alloc]
                                  initWithStubbedOperatingSystemCheckResult:NO];

  self.api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:processInfo
                                                  logger:self.logger
                                               urlOpener:self.urlOpener
                                bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                         frameworkLoader:self.frameworkLoader
                                    appURLSchemeProvider:self.appURLSchemeProvider
                                            errorFactory:self.errorFactory];

  [self.urlOpener stubOpenWithUrl:self.sampleUrl success:applicationOpensSuccessfully];
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
  BOOL applicationOpensSuccessfully = YES;

  __block BOOL didInvokeCompletion = NO;
  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    didInvokeCompletion = YES;
  }];

  self.urlOpener.capturedOpenUrlCompletion(applicationOpensSuccessfully);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testOpenUrlWhenApplicationDoesNotOpen
{
  BOOL applicationOpensSuccessfully = NO;

  __block BOOL didInvokeCompletion = NO;
  [self.api openURL:self.sampleUrl sender:nil handler:^(BOOL _success, NSError *_Nullable error) {
    XCTAssertEqual(
      _success,
      applicationOpensSuccessfully,
      "Should call the completion handler with the expected value"
    );
    XCTAssertNil(error, "Should not call the completion handler with an error");
    didInvokeCompletion = YES;
  }];

  self.urlOpener.capturedOpenUrlCompletion(applicationOpensSuccessfully);
  XCTAssertTrue(didInvokeCompletion);
}

// MARK: - Request completion block

- (void)testRequestCompletionBlockCalledWithSuccess
{
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl scheme:@"file"];

  FBSDKBridgeAPIResponseBlock responseBlock = ^void (FBSDKBridgeAPIResponse *response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      @"The response should contain the original request"
    );
    TestSDKError *error = (TestSDKError *)response.error;
    XCTAssertEqual(
      error.type,
      ErrorTypeGeneral,
      @"The response should contain a general error"
    );
    XCTAssertEqual(
      error.code,
      FBSDKErrorAppVersionUnsupported,
      @"The error should use an app version unsupported error code"
    );
    XCTAssertEqualObjects(
      error.message,
      @"the app switch failed because the destination app is out of date",
      @"The error should use an appropriate error message"
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl scheme:FBSDKURLSchemeHTTPS];
  FBSDKBridgeAPIResponseBlock responseBlock = ^void (FBSDKBridgeAPIResponse *response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      @"The response should contain the original request"
    );
    TestSDKError *error = (TestSDKError *)response.error;
    XCTAssertEqual(
      error.type,
      ErrorTypeGeneral,
      @"The response should contain a general error"
    );
    XCTAssertEqual(
      error.code,
      FBSDKErrorBrowserUnavailable,
      @"The error should use a browser unavailable error code"
    );
    XCTAssertEqualObjects(
      error.message,
      @"the app switch failed because the browser is unavailable",
      @"The response should use an appropriate error message"
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
  self.api.pendingURLOpen = urlOpener;
  self.api.safariViewController = (SFSafariViewController *)ViewControllerSpy.makeDefaultSpy;

  // Setting a pending request so we can assert that it's nilled out upon cancellation
  self.api.pendingRequest = self.sampleTestBridgeAPIRequest;

  // Funny enough there's no check that the safari view controller from the delegate
  // is the same instance stored in the safariViewController property
  [self.api safariViewControllerDidFinish:self.api.safariViewController];

  XCTAssertNil(self.api.pendingURLOpen, "Should remove the reference to the pending url opener");
  XCTAssertNil(
    self.api.safariViewController,
    "Should remove the reference to the safari view controller when the delegate method is called"
  );

  XCTAssertNil(self.api.pendingRequest, "Should cancel the request");
  XCTAssertTrue(urlOpener.openUrlWasCalled, "Should ask the opener to open a url (even though there is not one provided");
  XCTAssertNil(FBSDKLoginManager.capturedOpenUrl, "The url opener should be called with nil arguments");
  XCTAssertNil(FBSDKLoginManager.capturedSourceApplication, "The url opener should be called with nil arguments");
  XCTAssertNil(FBSDKLoginManager.capturedAnnotation, "The url opener should be called with nil arguments");
}

- (void)testSafariVcDidFinishWithoutPendingUrlOpener
{
  self.api.safariViewController = (id)ViewControllerSpy.makeDefaultSpy;

  // Setting a pending request so we can assert that it's nilled out upon cancellation
  self.api.pendingRequest = self.sampleTestBridgeAPIRequest;

  // Funny enough there's no check that the safari view controller from the delegate
  // is the same instance stored in the safariViewController property
  [self.api safariViewControllerDidFinish:self.api.safariViewController];

  XCTAssertNil(self.api.pendingURLOpen, "Should remove the reference to the pending url opener");
  XCTAssertNil(
    self.api.safariViewController,
    "Should remove the reference to the safari view controller when the delegate method is called"
  );

  XCTAssertNil(self.api.pendingRequest, "Should cancel the request");
  XCTAssertNil(FBSDKLoginManager.capturedOpenUrl, "The url opener should not be called");
  XCTAssertNil(FBSDKLoginManager.capturedSourceApplication, "The url opener should not be called");
  XCTAssertNil(FBSDKLoginManager.capturedAnnotation, "The url opener should not be called");
}

// MARK: - ContainerViewController Delegate Methods

- (void)testViewControllerDidDisappearWithSafariViewController
{
  UIViewController *viewControllerSpy = ViewControllerSpy.makeDefaultSpy;
  self.api.safariViewController = (SFSafariViewController *)viewControllerSpy;
  FBSDKContainerViewController *container = [FBSDKContainerViewController new];

  // Setting a pending request so we can assert that it's nilled out upon cancellation
  self.api.pendingRequest = self.sampleTestBridgeAPIRequest;

  [self.api viewControllerDidDisappear:container animated:NO];

  XCTAssertEqualObjects(_logger.capturedContents, @"**ERROR**:\n The SFSafariViewController's parent view controller was dismissed.\nThis can happen if you are triggering login from a UIAlertController. Instead, make sure your top most view controller will not be prematurely dismissed.");
  XCTAssertNil(self.api.pendingRequest, "Should cancel the request");
}

- (void)testViewControllerDidDisappearWithoutSafariViewController
{
  FBSDKContainerViewController *container = [FBSDKContainerViewController new];

  // Setting a pending request so we can assert that it's nilled out upon cancellation
  self.api.pendingRequest = self.sampleTestBridgeAPIRequest;

  [self.api viewControllerDidDisappear:container animated:NO];

  XCTAssertNotNil(self.api.pendingRequest, "Should not cancel the request");
  XCTAssertNil(_logger.capturedContents, @"Expected nothing to be logged");
}

// MARK: - Bridge Response Url Handling

- (void)testHandlingBridgeResponseWithInvalidScheme
{
  [self stubBridgeApiResponseWithUrlCreation];
  self.appURLSchemeProvider.stubbedScheme = @"foo";

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.sampleUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with an invalid url scheme");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithInvalidHost
{
  [self stubBridgeApiResponseWithUrlCreation];
  self.appURLSchemeProvider.stubbedScheme = self.sampleUrl.scheme;

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.sampleUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with an invalid url host");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingRequest
{
  [self stubBridgeApiResponseWithUrlCreation];
  self.appURLSchemeProvider.stubbedScheme = self.validBridgeResponseUrl.scheme;

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertFalse(result, "Should not successfully handle bridge api response url with a missing request");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingCompletionBlock
{
  [self stubBridgeApiResponseWithUrlCreation];
  self.appURLSchemeProvider.stubbedScheme = self.validBridgeResponseUrl.scheme;
  self.api.pendingRequest = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should successfully handle bridge api response url with a missing completion block");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithBridgeResponse
{
  FBSDKBridgeAPIResponse *response = [[FBSDKBridgeAPIResponse alloc] initWithRequest:[TestBridgeAPIRequest requestWithURL:self.sampleUrl]
                                                                  responseParameters:@{}
                                                                           cancelled:NO
                                                                               error:nil];
  self.bridgeAPIResponseFactory.stubbedResponse = response;
  self.appURLSchemeProvider.stubbedScheme = self.validBridgeResponseUrl.scheme;
  self.api.pendingRequest = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *_response) {
    XCTAssertEqualObjects(_response, response, "Should invoke the completion with the expected bridge api response");
  };

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should successfully handle creation of a bridge api response");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithBridgeError
{
  FBSDKBridgeAPIResponse *response = [[FBSDKBridgeAPIResponse alloc] initWithRequest:[TestBridgeAPIRequest requestWithURL:self.sampleUrl]
                                                                  responseParameters:@{}
                                                                           cancelled:NO
                                                                               error:self.sampleError];
  self.bridgeAPIResponseFactory.stubbedResponse = response;
  self.appURLSchemeProvider.stubbedScheme = self.validBridgeResponseUrl.scheme;
  self.api.pendingRequest = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *_response) {
    XCTAssertEqualObjects(_response, response, "Should invoke the completion with the expected bridge api response");
  };

  BOOL result = [self.api _handleBridgeAPIResponseURL:self.validBridgeResponseUrl sourceApplication:@""];

  XCTAssertTrue(result, "Should retry creation of a bridge api response if the first attempt has an error");
  [self assertPendingPropertiesCleared];
}

- (void)testHandlingBridgeResponseWithMissingResponseMissingError
{
  FBSDKBridgeAPIResponse *response = [[FBSDKBridgeAPIResponse alloc] initWithRequest:[TestBridgeAPIRequest requestWithURL:self.sampleUrl]
                                                                  responseParameters:@{}
                                                                           cancelled:NO
                                                                               error:nil];
  self.bridgeAPIResponseFactory.stubbedResponse = response;
  self.bridgeAPIResponseFactory.shouldFailCreation = YES;
  self.appURLSchemeProvider.stubbedScheme = self.validBridgeResponseUrl.scheme;
  self.api.pendingRequest = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *_response) {
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

- (void)stubBridgeApiResponseWithUrlCreation
{
  FBSDKBridgeAPIResponse *response = [[FBSDKBridgeAPIResponse alloc] initWithRequest:[TestBridgeAPIRequest requestWithURL:self.sampleUrl]
                                                                  responseParameters:@{}
                                                                           cancelled:NO
                                                                               error:nil];
  self.bridgeAPIResponseFactory.stubbedResponse = response;
}

- (TestBridgeAPIRequest *)sampleTestBridgeAPIRequest
{
  return [[TestBridgeAPIRequest alloc] initWithUrl:self.sampleUrl
                                      protocolType:FBSDKBridgeAPIProtocolTypeWeb
                                            scheme:@"1"];
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
