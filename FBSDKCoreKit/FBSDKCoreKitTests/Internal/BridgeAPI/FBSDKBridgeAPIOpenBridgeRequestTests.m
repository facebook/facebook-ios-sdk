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
#import <SafariServices/SafariServices.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKBridgeAPIOpenBridgeRequestTests : XCTestCase

@property FBSDKBridgeAPI *api;
@property id partialMock;
@property (readonly) NSURL *sampleUrl;
@property (nonatomic) TestURLOpener *urlOpener;
@property (nonatomic) TestBridgeApiResponseFactory *bridgeAPIResponseFactory;
@property (nonatomic) TestDylibResolver *frameworkLoader;
@property (nonatomic) TestAppURLSchemeProvider *appURLSchemeProvider;

@end

@implementation FBSDKBridgeAPIOpenBridgeRequestTests

- (void)setUp
{
  [super setUp];

  _urlOpener = [[TestURLOpener alloc] initWithCanOpenUrl:YES];
  _bridgeAPIResponseFactory = [TestBridgeApiResponseFactory new];
  _frameworkLoader = [TestDylibResolver new];
  _appURLSchemeProvider = [TestAppURLSchemeProvider new];
  _api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                              logger:[TestLogger new]
                                           urlOpener:self.urlOpener
                            bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                     frameworkLoader:self.frameworkLoader
                                appURLSchemeProvider:self.appURLSchemeProvider];
}

// MARK: - Url Opening

- (void)testOpeningBridgeRequestWithRequestUrlUsingSafariVcWithFromVc
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = [ViewControllerSpy makeDefaultSpy];
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:self.sampleUrl];
  [self.api openBridgeAPIRequest:request
         useSafariViewController:YES
              fromViewController:spy
                 completionBlock:self.uninvokedCompletionHandler];

  XCTAssertEqualObjects(self.api.pendingRequest, request);
  XCTAssertEqualObjects(self.api.pendingRequestCompletionBlock, self.uninvokedCompletionHandler);

  XCTAssertNil(
    self.bridgeAPIResponseFactory.capturedResponseURL,
    "Should not create a bridge response"
  );
  XCTAssertTrue(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should try and load the safari view controller class"
  );
  XCTAssertEqualObjects(
    self.api.safariViewController.delegate,
    self.api,
    "Should create a safari controller with the bridge as its delegate"
  );
}

- (void)testOpeningBridgeRequestWithRequestUrlUsingSafariVcWithoutFromVc
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:self.sampleUrl];
  [self.api openBridgeAPIRequest:request
         useSafariViewController:YES
              fromViewController:nil
                 completionBlock:self.uninvokedCompletionHandler];

  XCTAssertEqualObjects(self.api.pendingRequest, request);
  XCTAssertEqualObjects(self.api.pendingRequestCompletionBlock, self.uninvokedCompletionHandler);

  XCTAssertTrue(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should try and load the safari view controller class"
  );
  XCTAssertEqualObjects(
    self.api.logger.contents,
    @"There are no valid ViewController to present SafariViewController with"
  );
}

- (void)testOpeningBridgeRequestWithRequestUrlNotUsingSafariVcWithFromVc
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = [ViewControllerSpy makeDefaultSpy];
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:self.sampleUrl];
  [self.api openBridgeAPIRequest:request
         useSafariViewController:NO
              fromViewController:spy
                 completionBlock:self.uninvokedCompletionHandler];

  XCTAssertEqualObjects(self.api.pendingRequest, request);
  XCTAssertEqualObjects(self.api.pendingRequestCompletionBlock, self.uninvokedCompletionHandler);

  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when safari is not requested"
  );
}

- (void)testOpeningBridgeRequestWithRequestUrlNotUsingSafariVcWithoutFromVc
{
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:self.sampleUrl];
  [self.api openBridgeAPIRequest:request
         useSafariViewController:NO
              fromViewController:nil
                 completionBlock:self.uninvokedCompletionHandler];

  XCTAssertEqualObjects(self.api.pendingRequest, request);
  XCTAssertEqualObjects(self.api.pendingRequestCompletionBlock, self.uninvokedCompletionHandler);

  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when safari is not requested"
  );
}

- (void)testOpeningBridgeRequestWithoutRequestUrlUsingSafariVcWithFromVc
{
  ViewControllerSpy *spy = [ViewControllerSpy makeDefaultSpy];
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeApiRequestError.class],
      "Should call the completion with an error if the request cannot provide a url"
    );
  };

  [self.api openBridgeAPIRequest:request
         useSafariViewController:YES
              fromViewController:spy
                 completionBlock:completionHandler];

  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );
  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when the request cannot provide a url"
  );
  [self assertPendingPropertiesNotSet];
}

- (void)testOpeningBridgeRequestWithoutRequestUrlUsingSafariVcWithoutFromVc
{
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeApiRequestError.class],
      "Should call the completion with an error if the request cannot provide a url"
    );
  };
  [self.api openBridgeAPIRequest:request
         useSafariViewController:YES
              fromViewController:nil
                 completionBlock:completionHandler];
  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );
  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when the request cannot provide a url"
  );
  [self assertPendingPropertiesNotSet];
}

- (void)testOpeningBridgeRequestWithoutRequestUrlNotUsingSafariVcWithFromVc
{
  ViewControllerSpy *spy = [ViewControllerSpy makeDefaultSpy];
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeApiRequestError.class],
      "Should call the completion with an error if the request cannot provide a url"
    );
  };
  [self.api openBridgeAPIRequest:request
         useSafariViewController:NO
              fromViewController:spy
                 completionBlock:completionHandler];
  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );
  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when the request cannot provide a url"
  );
  [self assertPendingPropertiesNotSet];
}

- (void)testOpeningBridgeRequestWithoutRequestUrlNotUsingSafariVcWithoutFromVc
{
  TestBridgeApiRequest *request = [TestBridgeApiRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeApiRequestError.class],
      "Should call the completion with an error if the request cannot provide a url"
    );
  };
  [self.api openBridgeAPIRequest:request
         useSafariViewController:NO
              fromViewController:nil
                 completionBlock:completionHandler];
  XCTAssertNil(
    self.urlOpener.capturedOpenUrl,
    "Should not try to open a url when the request cannot provide one"
  );
  XCTAssertFalse(
    self.frameworkLoader.didLoadSafariViewControllerClass,
    "Should not try and load the safari view controller class when the request cannot provide a url"
  );
  [self assertPendingPropertiesNotSet];
}

// MARK: - Helpers

- (void)assertPendingPropertiesNotSet
{
  XCTAssertNil(
    self.api.pendingRequest,
    "Should not set a pending request if the bridge request does not have a request url"
  );
  XCTAssertNil(
    self.api.pendingRequestCompletionBlock,
    "Should not set a pending request completion block if the bridge request does not have a request url"
  );
}

- (FBSDKBridgeAPIResponseBlock)uninvokedCompletionHandler
{
  return ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTFail("Should not invoke the completion handler");
  };
}

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"http://example.com"];
}

@end
