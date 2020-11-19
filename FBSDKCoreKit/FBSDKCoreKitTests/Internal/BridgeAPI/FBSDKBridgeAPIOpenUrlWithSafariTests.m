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

#import <OCMock/OCMock.h>
#import <SafariServices/SFSafariViewController.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"
#import "FakeLoginManager.h"

@interface FBSDKBridgeAPI (Testing)
- (void)_openURLWithSafariViewController:(NSURL *)url
                                  sender:(id<FBSDKURLOpening>)sender
                      fromViewController:(UIViewController *)fromViewController
                                 handler:(FBSDKSuccessBlock)handler
                           dylibResolver:(id<FBSDKDynamicFrameworkResolving>)dylibResolver;
@end

@interface FBSDKBridgeAPIOpenUrlWithSafariTests : FBSDKTestCase

@property (nonatomic) FBSDKBridgeAPI *api;
@property (nonatomic) id partialMock;
@property (nonatomic, readonly) NSURL *sampleUrl;
@property (nonatomic) FBSDKLoginManager *urlOpener;

@end

@implementation FBSDKBridgeAPIOpenUrlWithSafariTests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];
  _api = [FBSDKBridgeAPI new];
  _partialMock = OCMPartialMock(self.api);
  _urlOpener = [FBSDKLoginManager new];

  OCMStub([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMStub([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMStub([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);
}

- (void)tearDown
{
  _api = nil;
  _urlOpener = nil;

  [_partialMock stopMocking];
  _partialMock = nil;

  [super tearDown];
}

// MARK: - Url Opening

- (void)testWithNonHttpUrlScheme
{
  NSURL *url = [NSURL URLWithString:@"file://example.com"];
  self.api.expectingBackground = YES; // So we can check that it's unchanged

  [self.api openURLWithSafariViewController:url
                                     sender:nil
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];
  OCMVerify([_partialMock openURL:url sender:nil handler:self.uninvokedSuccessBlock]);
  XCTAssertTrue(self.api.expectingBackground, "Should not modify whether the background is expected to change");
  XCTAssertNil(self.api.pendingUrlOpen, "Should not set a pending url opener");
}

- (void)testWithAuthenticationURL
{
  self.urlOpener.stubbedIsAuthenticationUrl = YES;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.urlOpener
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  OCMVerify([_partialMock setSessionCompletionHandlerFromHandler:self.uninvokedSuccessBlock]);
  OCMVerify([_partialMock openURLWithAuthenticationSession:self.sampleUrl]);
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithNonAuthenticationURL
{
  self.urlOpener.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);
  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.urlOpener
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithoutSafariVcAvailable
{
  FakeDylibResolver *resolver = [FakeDylibResolver new];
  self.urlOpener.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);

  [self.api _openURLWithSafariViewController:self.sampleUrl
                                      sender:self.urlOpener
                          fromViewController:nil
                                     handler:self.uninvokedSuccessBlock
                               dylibResolver:resolver];

  OCMVerify(
    [_partialMock openURL:self.sampleUrl
                   sender:self.urlOpener
                  handler:self.uninvokedSuccessBlock]
  );
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithoutFromViewController
{
  self.urlOpener.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.urlOpener
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  OCMVerify(
    [self.loggerClassMock singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                    logEntry:@"There are no valid ViewController to present SafariViewController with"]
  );
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithFromViewControllerMissingTransitionCoordinator
{
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  self.urlOpener.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success, "Should call the handler with success");
    XCTAssertNil(error, "Should not call the handler with an error");
  };

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.urlOpener
                         fromViewController:spy
                                    handler:handler];

  SFSafariViewController *safariVc = (SFSafariViewController *)self.api.safariViewController;

  XCTAssertNotNil(safariVc, "Should create and set a safari view controller for display");
  XCTAssertEqual(
    safariVc.modalPresentationStyle,
    UIModalPresentationOverFullScreen,
    "Should set the correct modal presentation style"
  );
  XCTAssertEqualObjects(
    safariVc.delegate,
    self.api,
    "Should set the safari view controller delegate to the bridge api"
  );
  XCTAssertEqualObjects(
    spy.capturedPresentViewController,
    safariVc.parentViewController,
    "Should present the view controller containing the safari view controller"
  );
  XCTAssertTrue(spy.capturedPresentViewControllerAnimated, "Should animate presenting the safari view controller");
  XCTAssertNil(spy.capturedPresentViewControllerCompletion, "Should not pass a completion handler to the safari vc presentation");
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithFromViewControllerWithTransitionCoordinator
{
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  spy.stubbedTransitionCoordinator = self.transitionCoordinatorMock;
  self.urlOpener.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success, "Should call the handler with success");
    XCTAssertNil(error, "Should not call the handler with an error");
  };

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  OCMStub([self.transitionCoordinatorMock animateAlongsideTransition:nil completion:[OCMArg invokeBlock]]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.urlOpener
                         fromViewController:spy
                                    handler:handler];

  SFSafariViewController *safariVc = (SFSafariViewController *)self.api.safariViewController;

  XCTAssertNotNil(safariVc, "Should create and set a safari view controller for display");
  XCTAssertEqual(
    safariVc.modalPresentationStyle,
    UIModalPresentationOverFullScreen,
    "Should set the correct modal presentation style"
  );
  XCTAssertEqualObjects(
    safariVc.delegate,
    self.api,
    "Should set the safari view controller delegate to the bridge api"
  );
  XCTAssertEqualObjects(
    spy.capturedPresentViewController,
    safariVc.parentViewController,
    "Should present the view controller containing the safari view controller"
  );
  XCTAssertTrue(spy.capturedPresentViewControllerAnimated, "Should animate presenting the safari view controller");
  XCTAssertNil(spy.capturedPresentViewControllerCompletion, "Should not pass a completion handler to the safari vc presentation");
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

// MARK: - Helpers

- (void)assertExpectingBackgroundAndPendingUrlOpener
{
  XCTAssertFalse(self.api.expectingBackground, "Should set expecting background to false");
  XCTAssertEqualObjects(self.api.pendingUrlOpen, self.urlOpener, "Should set the pending url opener to the passed in sender");
}

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"http://example.com"];
}

- (FBSDKSuccessBlock)uninvokedSuccessBlock
{
  return ^(BOOL success, NSError *_Nullable error) {
    XCTFail("Should not invoke the completion handler");
  };
}

@end
