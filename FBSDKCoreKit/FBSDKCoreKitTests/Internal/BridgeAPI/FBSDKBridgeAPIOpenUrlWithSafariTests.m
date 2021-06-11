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

@interface FBSDKBridgeAPIOpenUrlWithSafariTests : FBSDKTestCase

@property (nonatomic) FBSDKBridgeAPI *api;
@property (nonatomic) TestLogger *logger;
@property (nonatomic) id partialMock;
@property (nonatomic, readonly) NSURL *sampleUrl;
@property (nonatomic) FBSDKLoginManager *loginManager;
@property (nonatomic) TestURLOpener *urlOpener;
@property (nonatomic) TestBridgeApiResponseFactory *bridgeAPIResponseFactory;
@property (nonatomic) TestDylibResolver *frameworkLoader;

@end

@implementation FBSDKBridgeAPIOpenUrlWithSafariTests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];
  _logger = [TestLogger new];
  _urlOpener = [[TestURLOpener alloc] initWithCanOpenUrl:YES];
  _bridgeAPIResponseFactory = [TestBridgeApiResponseFactory new];
  _frameworkLoader = [TestDylibResolver new];
  _api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                              logger:self.logger
                                           urlOpener:self.urlOpener
                            bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                     frameworkLoader:self.frameworkLoader];
  _partialMock = OCMPartialMock(self.api);
  _loginManager = [FBSDKLoginManager new];

  OCMStub([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMStub([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMStub([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);
}

- (void)tearDown
{
  _api = nil;
  _loginManager = nil;

  [_partialMock stopMocking];
  _partialMock = nil;
  [TestLogger reset];

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
  self.loginManager.stubbedIsAuthenticationUrl = YES;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  OCMVerify([_partialMock setSessionCompletionHandlerFromHandler:self.uninvokedSuccessBlock]);
  OCMVerify([_partialMock openURLWithAuthenticationSession:self.sampleUrl]);
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithNonAuthenticationURL
{
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);
  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithoutSafariVcAvailable
{
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  OCMVerify(
    [_partialMock openURL:self.sampleUrl
                   sender:self.loginManager
                  handler:self.uninvokedSuccessBlock]
  );
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithoutFromViewController
{
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  XCTAssertEqualObjects(_logger.capturedContents, @"There are no valid ViewController to present SafariViewController with");
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithFromViewControllerMissingTransitionCoordinator
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success, "Should call the handler with success");
    XCTAssertNil(error, "Should not call the handler with an error");
  };

  OCMReject([_partialMock setSessionCompletionHandlerFromHandler:OCMArg.any]);
  OCMReject([_partialMock openURLWithAuthenticationSession:OCMArg.any]);
  OCMReject([_partialMock openURL:OCMArg.any sender:OCMArg.any handler:OCMArg.any]);

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
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
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  spy.stubbedTransitionCoordinator = self.transitionCoordinatorMock;
  self.loginManager.stubbedIsAuthenticationUrl = NO;
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
                                     sender:self.loginManager
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
  XCTAssertEqualObjects(self.api.pendingUrlOpen, self.loginManager, "Should set the pending url opener to the passed in sender");
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
