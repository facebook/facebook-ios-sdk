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
#import "FBSDKGamingServicesKitTests-Swift.h"

@interface FBSDKGamingImageUploaderTests : XCTestCase

@property (nonatomic) FBSDKGamingImageUploader *uploader;
@property (nonatomic) TestGamingServiceControllerFactory *factory;
@property (nonatomic) FBSDKGamingImageUploaderConfiguration *configuration;

@end

@implementation FBSDKGamingImageUploaderTests

- (void)setUp
{
  [super setUp];

  FBSDKAccessToken.currentAccessToken = [self createAccessToken];

  self.factory = [TestGamingServiceControllerFactory new];
  self.uploader = [[FBSDKGamingImageUploader alloc] initWithGamingServiceControllerFactory:self.factory];
  self.configuration = [self createConfigurationWithShouldLaunch:YES];
}

- (void)tearDown
{
  FBSDKAccessToken.currentAccessToken = nil;

  [super tearDown];
}

// MARK: - Dependencies

- (void)testDefaultDependencies
{
  XCTAssertEqualObjects(
    [(NSObject *)FBSDKGamingImageUploader.shared.factory class],
    FBSDKGamingServiceControllerFactory.class,
    "Should use the expected default gaming service controller factory type by default"
  );
}

// MARK: - Configuration

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

// MARK: - Uploading

- (void)testFailureWhenNoValidAccessTokenPresent
{
  [FBSDKAccessToken setCurrentAccessToken:nil];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:self.configuration
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
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorGraphRequestGraphAPI, "Expected error from Graph API");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testGraphResponsesTriggerCompletionIfDialogNotRequested
{
  NSString *expectedID = @"111";
  NSDictionary *expectedResult = @{@"id" : expectedID};
  NSString *expectedDialogResult = self.name;
  NSError *expectedError = [[NSError alloc]
                            initWithDomain:FBSDKErrorDomain
                            code:FBSDKErrorUnknown
                            userInfo:nil];
  [self stubGraphRequestWithResult:expectedResult error:nil];

  __block BOOL actioned = false;
  [self.uploader
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     XCTAssertEqualObjects(error, expectedError);
     XCTAssertEqualObjects(result, expectedDialogResult);
     actioned = true;
   }];

  XCTAssertEqual(
    self.factory.capturedServiceType,
    FBSDKGamingServiceTypeMediaAsset,
    "Should create a controller with the expected service type"
  );
  XCTAssertEqualObjects(
    (NSDictionary *)self.factory.capturedPendingResult,
    expectedResult,
    "Should not create a controller with a pending result"
  );
  XCTAssertEqualObjects(
    self.factory.controller.capturedArgument,
    expectedID,
    "Should invoke the new controller with the id from the result"
  );

  self.factory.capturedCompletion(YES, self.name, expectedError);

  XCTAssertTrue(actioned);
}

- (void)testGraphResponsesDoNotTriggerCompletionIfDialogIsRequested
{
  [self stubGraphRequestWithResult:@{@"id" : @"123"} error:nil];

  __block BOOL actioned = false;
  [self.uploader
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     actioned = true;
   }];

  XCTAssertFalse(actioned, "Callback should not have been called because there was more work to do");
}

- (void)testGraphResponsesTriggerDialogIfDialogIsRequested
{
  NSString *expectedID = @"111";
  NSDictionary *expectedResult = @{@"id" : expectedID};
  [self stubGraphRequestWithResult:expectedResult error:nil];

  __block BOOL didInvokeCompletion = NO;
  [self.uploader
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     didInvokeCompletion = YES;
   }];

  XCTAssertEqual(
    self.factory.capturedServiceType,
    FBSDKGamingServiceTypeMediaAsset,
    "Should create a controller with the expected service type"
  );
  XCTAssertEqualObjects(
    (NSDictionary *)self.factory.capturedPendingResult,
    expectedResult,
    "Should not create a controller with a pending result"
  );
  XCTAssertEqualObjects(
    self.factory.controller.capturedArgument,
    expectedID,
    "Should invoke the new controller with the id from the result"
  );

  self.factory.capturedCompletion(YES, nil, nil);

  XCTAssertTrue(didInvokeCompletion);
}

- (void)testDialogCompletionOnURLCallback
{
  id settings = OCMClassMock([FBSDKSettings class]);
  OCMStub(ClassMethod([settings appID])).andReturn(@"123");

  [self stubGraphRequestWithResult:@{@"id" : @"111"} error:nil];

  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  [delegate
   application:UIApplication.sharedApplication
   openURL:[NSURL URLWithString:@"fb123://media_asset"]
   sourceApplication:@""
   annotation:nil];

  XCTAssertTrue(actioned);
}

// TODO: This is actually testing the applicationDidBecomeActive method
// of GamingServicesController. This is a roundabout way of setting a
// completion on that then invoking it via the delegate from the bridge.
// This test should be moved to where it makes sense or deleted.
- (void)_testDialogCompletionOnApplicationBecameActive
{
  FBSDKAccessToken.currentAccessToken = [self createAccessToken];
  [self stubGraphRequestWithResult:@{@"id" : @"111"} error:nil];

  __block id<FBSDKURLOpening> delegate;
  [FBSDKGamingServicesKitTestUtility captureURLDelegateFromBridgeAPI:^(id<FBSDKURLOpening> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [self.uploader
   uploadImageWithConfiguration:self.configuration
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  [delegate applicationDidBecomeActive:UIApplication.sharedApplication];

  XCTAssertTrue(actioned);
}

- (void)testUploadProgress
{
  __block id<FBSDKGraphRequestConnectionDelegate> delegate;
  __block FBSDKGraphRequestCompletion completion;
  id mockConnection = [self stubGraphRequestWithDelegateCapture:^(id<FBSDKGraphRequestConnectionDelegate> obj) {
                              delegate = obj;
                            } andCompletionCapture:^(FBSDKGraphRequestCompletion obj) {
                              completion = obj;
                            }];

  __block BOOL completionActioned = false;
  __block BOOL progressActioned = false;
  [self.uploader
   uploadImageWithConfiguration:[self createConfigurationWithShouldLaunch:NO]
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
                     andCompletionCapture:(void (^)(FBSDKGraphRequestCompletion))completionCaptureHandler
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
    [mockConnection addRequest:[OCMArg isEqual:mockRequest] completion:[OCMArg checkWithBlock:^BOOL (id obj) {
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
    [mockConnection addRequest:[OCMArg isEqual:mockRequest] completion:[OCMArg checkWithBlock:^BOOL (id obj) {
      ((FBSDKGraphRequestCompletion) obj)(nil, result, error);
      return true;
    }]]
  );
}

// MARK: - Helpers

- (FBSDKAccessToken *)createAccessToken
{
  return [[FBSDKAccessToken alloc]
          initWithTokenString:@"abc"
          permissions:@[]
          declinedPermissions:@[]
          expiredPermissions:@[]
          appID:@"123"
          userID:@""
          expirationDate:nil
          refreshDate:nil
          dataAccessExpirationDate:nil];
}

- (FBSDKGamingImageUploaderConfiguration *)createConfigurationWithShouldLaunch:(BOOL)shouldLaunch
{
  return [[FBSDKGamingImageUploaderConfiguration alloc]
          initWithImage:[self testUIImage]
          caption:@"Cool Photo"
          shouldLaunchMediaDialog:shouldLaunch];
}

@end
