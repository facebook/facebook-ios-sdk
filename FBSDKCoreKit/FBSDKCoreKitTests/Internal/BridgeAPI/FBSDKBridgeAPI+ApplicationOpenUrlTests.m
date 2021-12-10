/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests (ApplicationOpenURLTests)

// MARK: - Url Opening

- (void)testOpenUrlShouldStopPropagationWithPendingURL
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  [urlOpener stubShouldStopPropagationOfURL:self.sampleUrl withValue:YES];
  urlOpener.stubbedCanOpenUrl = YES;

  self.api.pendingURLOpen = urlOpener;

  BOOL returnValue = [self.api application:UIApplication.sharedApplication
                                   openURL:self.sampleUrl
                         sourceApplication:sampleSource
                                annotation:sampleAnnotation];
  XCTAssertTrue(
    returnValue,
    "Should early exit when the opener stops propagation"
  );

  XCTAssertNil(
    urlOpener.capturedCanOpenUrl,
    "Should not check if a url can be opened when exiting early"
  );
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

// MARK: - Helpers

/// Assumes should not stop propagation of url
/// Assumes SafariViewController is not nil
- (void)verifyOpenUrlWithPendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
             isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
           authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                 expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
          expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                      hasSafariViewController:YES
             isDismissingSafariViewController:isDismissingSafariViewController
           authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:nil
    expectedAuthSessionCompletionHandlerError:nil
    expectAuthSessionCompletionHandlerInvoked:NO
                  expectedAuthCancelCallCount:0
                    expectedAuthSessionExists:YES
          expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
                     expectedCanOpenUrlSource:sampleSource
                 expectedCanOpenUrlAnnotation:sampleAnnotation
                           expectedOpenUrlUrl:nil
                        expectedOpenUrlSource:nil
                    expectedOpenUrlAnnotation:nil
                 expectedPendingUrlOpenExists:YES
                 expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                       expectedSafariVcExists:NO
                          expectedReturnValue:YES];
}

/// Assumes should not stop propagation of url
/// Assumes Pending Url cannot open
/// Assumes SafariViewController is nil
- (void)verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                                     authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                                             canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                                           expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
                                    expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
                                                    expectedReturnValue:(BOOL)expectedReturnValue
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:NO
                      hasSafariViewController:NO
             isDismissingSafariViewController:isDismissingSafariViewController
           authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
    expectedAuthSessionCompletionHandlerError:[self loginInterruptionErrorWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
    expectAuthSessionCompletionHandlerInvoked:YES
                  expectedAuthCancelCallCount:1
                    expectedAuthSessionExists:NO
          expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
                     expectedCanOpenUrlSource:sampleSource
                 expectedCanOpenUrlAnnotation:sampleAnnotation
                           expectedOpenUrlUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
                        expectedOpenUrlSource:sampleSource
                    expectedOpenUrlAnnotation:sampleAnnotation
                 expectedPendingUrlOpenExists:NO
                 expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                       expectedSafariVcExists:NO
                          expectedReturnValue:expectedReturnValue];
}

/// Assumes should not stop propagation of url
- (void)verifyOpenUrlWithPendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                      hasSafariViewController:(BOOL)hasSafariViewController
             isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
           authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                  expectedAuthCancelCallCount:(int)expectedAuthCancelCallCount
                 expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
          expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                      hasSafariViewController:hasSafariViewController
             isDismissingSafariViewController:isDismissingSafariViewController
           authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:nil
    expectedAuthSessionCompletionHandlerError:nil
    expectAuthSessionCompletionHandlerInvoked:NO
                  expectedAuthCancelCallCount:expectedAuthCancelCallCount
                    expectedAuthSessionExists:NO
          expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
                     expectedCanOpenUrlSource:sampleSource
                 expectedCanOpenUrlAnnotation:sampleAnnotation
                           expectedOpenUrlUrl:[self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse]
                        expectedOpenUrlSource:sampleSource
                    expectedOpenUrlAnnotation:sampleAnnotation
                 expectedPendingUrlOpenExists:NO
                 expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                       expectedSafariVcExists:hasSafariViewController
                          expectedReturnValue:YES];
}

- (void)verifyOpenUrlWithShouldStopPropagationOfUrl:(BOOL)shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                            hasSafariViewController:(BOOL)hasSafariViewController
                   isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                 authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                      hasSafariViewController:hasSafariViewController
             isDismissingSafariViewController:isDismissingSafariViewController
           authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:nil
    expectedAuthSessionCompletionHandlerError:nil
    expectAuthSessionCompletionHandlerInvoked:NO
                  expectedAuthCancelCallCount:0
                    expectedAuthSessionExists:YES
          expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:nil
                     expectedCanOpenUrlSource:nil
                 expectedCanOpenUrlAnnotation:nil
                           expectedOpenUrlUrl:nil
                        expectedOpenUrlSource:nil
                    expectedOpenUrlAnnotation:nil
                 expectedPendingUrlOpenExists:YES
                 expectedIsDismissingSafariVc:isDismissingSafariViewController // Should not change the value
                       expectedSafariVcExists:hasSafariViewController
                          expectedReturnValue:YES];
}

/// Assumes SafariViewController is nil
- (void)verifyOpenUrlWithShouldStopPropagationOfUrl:(BOOL)shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                   isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                 authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                      hasSafariViewController:NO
             isDismissingSafariViewController:isDismissingSafariViewController
           authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:nil
    expectedAuthSessionCompletionHandlerError:nil
    expectAuthSessionCompletionHandlerInvoked:NO
                  expectedAuthCancelCallCount:0
                    expectedAuthSessionExists:YES
          expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:nil
                     expectedCanOpenUrlSource:nil
                 expectedCanOpenUrlAnnotation:nil
                           expectedOpenUrlUrl:nil
                        expectedOpenUrlSource:nil
                    expectedOpenUrlAnnotation:nil
                 expectedPendingUrlOpenExists:YES
                 expectedIsDismissingSafariVc:isDismissingSafariViewController // Should not change this value
                       expectedSafariVcExists:NO
                          expectedReturnValue:YES];
}

- (void)verifyOpenUrlWithPendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                      hasSafariViewController:(BOOL)hasSafariViewController
             isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
           authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
      expectedAuthSessionCompletionHandlerUrl:(NSURL *)expectedAuthSessionCompletionHandlerUrl
    expectedAuthSessionCompletionHandlerError:(NSError *)expectedAuthSessionCompletionHandlerError
    expectAuthSessionCompletionHandlerInvoked:(BOOL)expectAuthSessionCompletionHandlerInvoked
                  expectedAuthCancelCallCount:(int)expectedAuthCancelCallCount
                    expectedAuthSessionExists:(BOOL)expectedAuthSessionExists
          expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
                        expectedCanOpenUrlUrl:(NSURL *)expectedCanOpenUrlCalledWithUrl
                     expectedCanOpenUrlSource:(NSString *)expectedCanOpenUrlSource
                 expectedCanOpenUrlAnnotation:(NSString *)expectedCanOpenUrlAnnotation
                           expectedOpenUrlUrl:(NSURL *)expectedOpenUrlUrl
                        expectedOpenUrlSource:(NSString *)expectedOpenUrlSource
                    expectedOpenUrlAnnotation:(NSString *)expectedOpenUrlAnnotation
                 expectedPendingUrlOpenExists:(BOOL)expectedPendingUrlOpenExists
                 expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
                       expectedSafariVcExists:(BOOL)expectedSafariVcExists
                          expectedReturnValue:(BOOL)expectedReturnValue
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  AuthenticationSessionSpy *authSessionSpy = [[AuthenticationSessionSpy alloc] initWithURL:self.sampleUrl
                                                                         callbackURLScheme:nil
                                                                         completionHandler:^(NSURL *_Nullable callbackURL, NSError *_Nullable error) {
                                                                           XCTFail("Should not invoke the completion for the authentication session");
                                                                         }];
  [urlOpener stubShouldStopPropagationOfURL:self.sampleUrl withValue:NO];
  urlOpener.stubbedCanOpenUrl = pendingUrlCanOpenUrl;

  self.api.pendingURLOpen = urlOpener;

  if (hasSafariViewController) {
    ViewControllerSpy *viewControllerSpy = ViewControllerSpy.makeDefaultSpy;
    self.api.safariViewController = (id)viewControllerSpy;
  }
  self.api.isDismissingSafariViewController = isDismissingSafariViewController;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionNone;
  self.api.pendingRequest = self.sampleBridgeApiRequest;
  self.api.authenticationSession = authSessionSpy;
  if (authSessionCompletionHandlerExists) {
    self.api.authenticationSessionCompletionHandler = ^(NSURL *callbackURL, NSError *error) {
      if (!expectAuthSessionCompletionHandlerInvoked) {
        XCTFail("Should not invoke the authentication session completion handler");
      }
      XCTAssertEqualObjects(
        callbackURL,
        expectedAuthSessionCompletionHandlerUrl,
        "Should invoke the authentication session completion handler with the expected URL"
      );
      XCTAssertEqualObjects(
        error,
        expectedAuthSessionCompletionHandlerError,
        "Should invoke the authentication session completion handler with the expected error"
      );
    };
  }
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {
    XCTFail("Should not invoke the pending request completion block");
  };

  if (canHandleBridgeApiResponse) {
    self.appURLSchemeProvider.stubbedScheme = FBSDKURLSchemeHTTP;
    self.api.pendingRequestCompletionBlock = nil;
  } else {
    self.appURLSchemeProvider.stubbedScheme = @"foo";
  }

  NSURL *urlToOpen = [self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse];
  BOOL returnValue = [self.api application:UIApplication.sharedApplication
                                   openURL:urlToOpen
                         sourceApplication:sampleSource
                                annotation:sampleAnnotation];
  XCTAssertEqual(
    returnValue,
    expectedReturnValue,
    "The return value for the overall method should be %@",
    StringFromBool(expectedReturnValue)
  );
  if (expectedAuthSessionExists) {
    XCTAssertNotNil(self.api.authenticationSession, "The authentication session should not be nil");
  } else {
    XCTAssertNil(self.api.authenticationSession, "The authentication session should be nil");
  }
  if (expectedAuthSessionCompletionExists) {
    XCTAssertNotNil(
      self.api.authenticationSessionCompletionHandler,
      "The authentication session completion handler should not be nil"
    );
  } else {
    XCTAssertNil(
      self.api.authenticationSessionCompletionHandler,
      "The authentication session completion handler should be nil"
    );
  }
  XCTAssertEqual(
    authSessionSpy.cancelCallCount,
    expectedAuthCancelCallCount,
    "The authentication session should be cancelled the expected number of times"
  );
  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "The authentication session state should not change"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenUrl,
    expectedCanOpenUrlCalledWithUrl,
    "The url opener's can open url method should be called with the expected URL"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenSourceApplication,
    expectedCanOpenUrlSource,
    "The url opener's can open url method should be called with the expected source application"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenAnnotation,
    expectedCanOpenUrlAnnotation,
    "The url opener's can open url method should be called with the expected annotation"
  );

  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedOpenUrl,
    expectedOpenUrlUrl,
    "The url opener's open url method should be called with the expected URL"
  );
  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedSourceApplication,
    expectedOpenUrlSource,
    "The url opener's open url method should be called with the expected source application"
  );
  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedAnnotation,
    expectedOpenUrlAnnotation,
    "The url opener's open url method should be called with the expected annotation"
  );

  if (pendingUrlCanOpenUrl) {
    XCTAssertNotNil(self.api.pendingRequest, "The pending request should be nil");
  } else {
    XCTAssertNil(self.api.pendingRequest, "The pending request should be nil");
    XCTAssertNil(self.api.pendingRequestCompletionBlock, "The pending request completion block should be nil");
  }
  if (expectedPendingUrlOpenExists) {
    XCTAssertNotNil(self.api.pendingURLOpen, "The reference to the url opener should not be nil");
  } else {
    XCTAssertNil(self.api.pendingURLOpen, "The reference to the url opener should be nil");
  }
  if (expectedSafariVcExists) {
    XCTAssertNotNil(self.api.safariViewController, "Safari view controller should not be nil");
  } else {
    XCTAssertNil(self.api.safariViewController, "Safari view controller should be nil");
  }
  XCTAssertEqual(
    self.api.isDismissingSafariViewController,
    expectedIsDismissingSafariVc,
    "Should set isDismissingSafariViewController to the expected value"
  );
}

- (NSURL *)createURLWithCanHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
{
  if (canHandleBridgeApiResponse) {
    return [NSURL URLWithString:@"http://bridge"];
  } else {
    return self.sampleUrl;
  }
}

- (FBSDKBridgeAPIRequest *)sampleBridgeApiRequest
{
  return [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                          scheme:FBSDKURLSchemeHTTPS
                                                      methodName:nil
                                                      parameters:nil
                                                        userInfo:nil];
}

- (NSError *)loginInterruptionErrorWithCanHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
{
  NSURL *url = [self createURLWithCanHandleBridgeApiResponse:canHandleBridgeApiResponse];
  NSString *errorMessage = [[NSString alloc]
                            initWithFormat:@"Login attempt cancelled by alternate call to openURL from: %@",
                            url];
  return [self.errorFactory errorWithCode:FBSDKErrorBridgeAPIInterruption
                                 userInfo:@{FBSDKErrorLocalizedDescriptionKey : errorMessage}
                                  message:errorMessage
                          underlyingError:nil];
}

static inline NSString *StringFromBool(BOOL value)
{
  return value ? @"YES" : @"NO";
}

@end
