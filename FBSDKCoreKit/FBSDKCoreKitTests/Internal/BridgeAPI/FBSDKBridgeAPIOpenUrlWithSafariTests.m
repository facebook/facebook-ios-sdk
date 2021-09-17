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

#import <SafariServices/SFSafariViewController.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKBridgeAPIOpenUrlWithSafariTests : XCTestCase

@property (nonatomic) FBSDKBridgeAPI *api;
@property (nonatomic) TestLogger *logger;
@property (nonatomic, readonly) NSURL *sampleUrl;
@property (nonatomic) FBSDKLoginManager *loginManager;
@property (nonatomic) TestInternalURLOpener *urlOpener;
@property (nonatomic) TestBridgeAPIResponseFactory *bridgeAPIResponseFactory;
@property (nonatomic) TestDylibResolver *frameworkLoader;
@property (nonatomic) TestInternalUtility *appURLSchemeProvider;

@end

@implementation FBSDKBridgeAPIOpenUrlWithSafariTests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];
  self.logger = [TestLogger new];
  self.urlOpener = [[TestInternalURLOpener alloc] initWithCanOpenUrl:YES];
  self.bridgeAPIResponseFactory = [TestBridgeAPIResponseFactory new];
  self.frameworkLoader = [TestDylibResolver new];
  self.appURLSchemeProvider = [TestInternalUtility new];
  self.api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                                  logger:self.logger
                                               urlOpener:self.urlOpener
                                bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                         frameworkLoader:self.frameworkLoader
                                    appURLSchemeProvider:self.appURLSchemeProvider];
  self.loginManager = [FBSDKLoginManager new];

  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
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

  XCTAssertEqualObjects(
    self.urlOpener.capturedOpenUrl,
    url,
    "Should try to open a url with a non http scheme"
  );
  XCTAssertTrue(self.api.expectingBackground, "Should not modify whether the background is expected to change");
  XCTAssertNil(self.api.pendingUrlOpen, "Should not set a pending url opener");
}

- (void)testWithAuthenticationURL
{
  self.loginManager.stubbedIsAuthenticationUrl = YES;
  self.api.expectingBackground = YES;

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open an authentication url when safari controller is specified"
  );
  XCTAssertNotNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNotNil(self.api.authenticationSession);
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithNonAuthenticationURLWithSafariControllerAvailable
{
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when a safari controller is expected to be used"
  );
  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNil(self.api.authenticationSession);
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithoutSafariVcAvailable
{
  self.frameworkLoader.stubSafariViewControllerClass = nil;
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  XCTAssertEqualObjects(
    self.urlOpener.capturedOpenUrl,
    self.sampleUrl,
    "Should try to open a url when a safari controller is not available"
  );
  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNil(self.api.authenticationSession);
  XCTAssertEqualObjects(
    self.api.pendingUrlOpen,
    self.loginManager,
    "Should set the pending url opener to the passed in sender"
  );
}

- (void)testWithoutFromViewController
{
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:nil
                                    handler:self.uninvokedSuccessBlock];

  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );

  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNil(self.api.authenticationSession);
  XCTAssertEqualObjects(_logger.capturedContents, @"There are no valid ViewController to present SafariViewController with");
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithFromViewControllerMissingTransitionCoordinator
{
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success, "Should call the handler with success");
    XCTAssertNil(error, "Should not call the handler with an error");
  };

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
  XCTAssertTrue(
    spy.capturedPresentViewControllerAnimated,
    "Should animate presenting the safari view controller"
  );
  XCTAssertNil(
    spy.capturedPresentViewControllerCompletion,
    "Should not pass a completion handler to the safari vc presentation"
  );
  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );
  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNil(self.api.authenticationSession);
  [self assertExpectingBackgroundAndPendingUrlOpener];
}

- (void)testWithFromViewControllerWithTransitionCoordinator
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = ViewControllerSpy.makeDefaultSpy;
  TestViewControllerTransitionCoordinator *coordinator = [TestViewControllerTransitionCoordinator new];
  spy.stubbedTransitionCoordinator = coordinator;
  self.loginManager.stubbedIsAuthenticationUrl = NO;
  self.api.expectingBackground = YES;
  __block BOOL didInvokeHandler = NO;
  FBSDKSuccessBlock handler = ^(BOOL success, NSError *_Nullable error) {
    XCTAssertTrue(success, "Should call the handler with success");
    XCTAssertNil(error, "Should not call the handler with an error");
    didInvokeHandler = YES;
  };

  [self.api openURLWithSafariViewController:self.sampleUrl
                                     sender:self.loginManager
                         fromViewController:spy
                                    handler:handler];

  coordinator.capturedAnimateAlongsideTransitionCompletion(
    [TestViewControllerTransitionCoordinatorContext new]
  );

  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );

  XCTAssertNil(self.api.authenticationSessionCompletionHandler);
  XCTAssertNil(self.api.authenticationSession);

  SFSafariViewController *safariVc = self.api.safariViewController;

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
  XCTAssertTrue(
    spy.capturedPresentViewControllerAnimated,
    "Should animate presenting the safari view controller"
  );
  XCTAssertNil(
    spy.capturedPresentViewControllerCompletion,
    "Should not pass a completion handler to the safari vc presentation"
  );
  [self assertExpectingBackgroundAndPendingUrlOpener];
  XCTAssertTrue(didInvokeHandler);
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
