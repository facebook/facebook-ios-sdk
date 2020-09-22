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
#import <XCTest/XCTest.h>

#import <FBSDKGamingServicesKit/FBSDKGamingServicesKit.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKGamingServicesKitTestUtility.h"

@interface FBSDKGamingImageUploaderTests : XCTestCase
@end

@implementation FBSDKGamingImageUploaderTests
{
  id _mockToken;
  id _mockConfig;
  id _mockApp;
}

- (void)setUp
{
  [super setUp];

  _mockToken = OCMClassMock([FBSDKAccessToken class]);
  [FBSDKAccessToken setCurrentAccessToken:_mockToken];

  _mockConfig = OCMClassMock([FBSDKGamingImageUploaderConfiguration class]);
  OCMStub([_mockConfig image]).andReturn([self testUIImage]);

  _mockApp = OCMClassMock([UIApplication class]);
  OCMStub([_mockApp sharedApplication]).andReturn(_mockApp);
}

- (void)testValuesAreSavedToConfig
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"png_transparency" ofType:@"png"];
  UIImage *image = [UIImage imageWithContentsOfFile:path];

  FBSDKGamingImageUploaderConfiguration *config =
  [[FBSDKGamingImageUploaderConfiguration alloc]
   initWithImage:image
   caption:@"Cool Photo"
   shouldLaunchMediaDialog:YES];

  XCTAssertEqual(config.caption, @"Cool Photo");
  XCTAssertEqual(config.image, image);
  XCTAssertTrue(config.shouldLaunchMediaDialog);
}

- (void)testFailureWhenNoValidAccessTokenPresent
{
  [FBSDKAccessToken setCurrentAccessToken:nil];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorAccessTokenRequired, "Expected error requiring a valid access token");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testNilImageFails
{
  id nilImageConfig = OCMClassMock([FBSDKGamingImageUploaderConfiguration class]);

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:nilImageConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorInvalidArgument, "Expected error requiring a non nil image");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testGraphErrorsAreHandled
{
  [self stubGraphRequestWithResult:nil error:[NSError new]];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorGraphRequestGraphAPI, "Expected error from Graph API");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testGraphResponsesTriggerCompletionIfDialogNotRequested
{
  [self stubGraphRequestWithResult:@{@"id" : @"123"} error:nil];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     XCTAssertNil(error);
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testGraphResponsesDoNotTriggerCompletionIfDialogIsRequested
{
  [self stubGraphRequestWithResult:@{@"id" : @"123"} error:nil];
  OCMStub([_mockConfig shouldLaunchMediaDialog]).andReturn(true);

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     actioned = true;
   }];

  XCTAssertFalse(actioned, "Callback should not have been called because there was more work to do");
}

- (void)testGraphResponsesTriggerDialogIfDialogIsRequested
{
  [self stubGraphRequestWithResult:@{@"id" : @"111"} error:nil];
  OCMStub([_mockConfig shouldLaunchMediaDialog]).andReturn(true);

  OCMStub(
    [_mockApp
     openURL:[OCMArg any]
     options:[OCMArg any]
     completionHandler:([OCMArg invokeBlockWithArgs:@(false), nil])]
  );

  // This will cause an lint warning, ignore it, this is an external sdk test
  // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
  id expectation = [self expectationWithDescription:@"callback"];

  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:1 handler:nil];

  id urlCheck = [OCMArg checkWithBlock:^BOOL (id obj) {
    return [[(NSURL *)obj absoluteString] isEqualToString:@"https://fb.gg/me/media_asset/111"];
  }];
  OCMVerify([_mockApp openURL:urlCheck options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)testDialogCompletionOnURLCallback
{
  id settings = OCMClassMock([FBSDKSettings class]);
  OCMStub([settings appID]).andReturn(@"123");

  [self stubGraphRequestWithResult:@{@"id" : @"111"} error:nil];
  OCMStub([_mockConfig shouldLaunchMediaDialog]).andReturn(true);

  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  [delegate
   application:_mockApp
   openURL:[NSURL URLWithString:@"fb123://media_asset"]
   sourceApplication:@""
   annotation:nil];

  XCTAssertTrue(actioned);
}

- (void)testDialogCompletionOnApplicationBecameActive
{
  [self stubGraphRequestWithResult:@{@"id" : @"111"} error:nil];
  OCMStub([_mockConfig shouldLaunchMediaDialog]).andReturn(true);

  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  [delegate applicationDidBecomeActive:_mockApp];

  XCTAssertTrue(actioned);
}

- (void)testUploadProgress
{
  __block id<FBSDKGraphRequestConnectionDelegate> delegate;
  __block FBSDKGraphRequestBlock completion;
  id mockConnection = [self stubGraphRequestWithDelegateCapture:^(id<FBSDKGraphRequestConnectionDelegate> obj) {
                              delegate = obj;
                            } andCompletionCapture:^(FBSDKGraphRequestBlock obj) {
                              completion = obj;
                            }];

  __block BOOL completionActioned = false;
  __block BOOL progressActioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:_mockConfig
   completionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(success);
     XCTAssertEqual(result[@"id"], @"foo");
     completionActioned = true;
   }
   andProgressHandler:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
     XCTAssertEqual(bytesSent, 123);
     XCTAssertEqual(totalBytesSent, 456);
     XCTAssertEqual(totalBytesExpectedToSend, 789);
     progressActioned = true;
   }];

  [delegate requestConnection:mockConnection didSendBodyData:123 totalBytesWritten:456 totalBytesExpectedToWrite:789];
  XCTAssertTrue(progressActioned);

  completion(mockConnection, @{@"id" : @"foo"}, nil);
  XCTAssertTrue(completionActioned);
}

#pragma mark - Helpers

- (UIImage *)testUIImage
{
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 0);
  [UIColor.redColor setFill];
  UIRectFill(CGRectMake(0, 0, 1, 1));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (id)stubGraphRequestWithDelegateCapture:(void (^)(id<FBSDKGraphRequestConnectionDelegate>))delegateCaptureHandler
                     andCompletionCapture:(void (^)(FBSDKGraphRequestBlock))completionCaptureHandler
{
  id mockRequest = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([mockRequest alloc]).andReturn(mockRequest);
  OCMStub([mockRequest initWithGraphPath:[OCMArg any] parameters:[OCMArg any] HTTPMethod:[OCMArg any]]).andReturn(mockRequest);

  id mockConnection = OCMClassMock([FBSDKGraphRequestConnection class]);
  OCMStub([mockConnection alloc]).andReturn(mockConnection);
  OCMStub(
    [mockConnection setDelegate:[OCMArg checkWithBlock:^BOOL (id obj) {
      delegateCaptureHandler(obj);
      return true;
    }]]
  );
  OCMStub(
    [mockConnection addRequest:[OCMArg isEqual:mockRequest] completionHandler:[OCMArg checkWithBlock:^BOOL (id obj) {
      completionCaptureHandler(obj);
      return true;
    }]]
  );

  return mockConnection;
}

- (void)stubGraphRequestWithResult:(id)result error:(NSError *)error
{
  id mockRequest = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([mockRequest alloc]).andReturn(mockRequest);
  OCMStub([mockRequest initWithGraphPath:[OCMArg any] parameters:[OCMArg any] HTTPMethod:[OCMArg any]]).andReturn(mockRequest);

  __block id delegate;
  id mockConnection = OCMClassMock([FBSDKGraphRequestConnection class]);
  OCMStub([mockConnection alloc]).andReturn(mockConnection);
  OCMStub(
    [mockConnection setDelegate:[OCMArg checkWithBlock:^BOOL (id obj) {
      delegate = obj;
      return true;
    }]]
  );
  OCMStub(
    [mockConnection addRequest:[OCMArg isEqual:mockRequest] completionHandler:[OCMArg checkWithBlock:^BOOL (id obj) {
      ((FBSDKGraphRequestBlock) obj)(nil, result, error);
      return true;
    }]]
  );
}

@end
