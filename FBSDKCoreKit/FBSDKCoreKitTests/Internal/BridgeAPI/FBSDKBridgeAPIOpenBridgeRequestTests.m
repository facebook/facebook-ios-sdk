/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKBridgeAPIOpenBridgeRequestTests : XCTestCase

@property (nonatomic) FBSDKBridgeAPI *api;
@property (nonatomic) id partialMock;
@property (readonly) NSURL *sampleUrl;
@property (nonatomic) TestInternalURLOpener *urlOpener;
@property (nonatomic) TestBridgeAPIResponseFactory *bridgeAPIResponseFactory;
@property (nonatomic) TestDylibResolver *frameworkLoader;
@property (nonatomic) TestInternalUtility *appURLSchemeProvider;
@property (nonatomic) TestLogger *logger;
@property (nonatomic) TestErrorFactory *errorFactory;

@end

@implementation FBSDKBridgeAPIOpenBridgeRequestTests

- (void)setUp
{
  [super setUp];

  _urlOpener = [[TestInternalURLOpener alloc] initWithCanOpenUrl:YES];
  _bridgeAPIResponseFactory = [TestBridgeAPIResponseFactory new];
  _frameworkLoader = [TestDylibResolver new];
  _appURLSchemeProvider = [TestInternalUtility new];
  _logger = [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
  _errorFactory = [TestErrorFactory new];
  _api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                              logger:self.logger
                                           urlOpener:self.urlOpener
                            bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                     frameworkLoader:self.frameworkLoader
                                appURLSchemeProvider:self.appURLSchemeProvider
                                        errorFactory:self.errorFactory];
}

// MARK: - Url Opening

- (void)testOpeningBridgeRequestWithRequestUrlUsingSafariVcWithFromVc
{
  self.frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.class;
  ViewControllerSpy *spy = [ViewControllerSpy makeDefaultSpy];
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:self.sampleUrl];
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeAPIRequestError.class],
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeAPIRequestError.class],
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeAPIRequestError.class],
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
  TestBridgeAPIRequest *request = [TestBridgeAPIRequest requestWithURL:nil];
  FBSDKBridgeAPIResponseBlock completionHandler = ^(FBSDKBridgeAPIResponse *_Nonnull response) {
    XCTAssertEqualObjects(
      response.request,
      request,
      "Should call the completion with a response that includes the original request"
    );
    XCTAssertTrue(
      [response.error isKindOfClass:FakeBridgeAPIRequestError.class],
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
