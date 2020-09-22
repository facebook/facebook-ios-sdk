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
#import "FBSDKVideoUploader.h"

@interface FBSDKGamingVideoUploaderTests : XCTestCase
@end

@implementation FBSDKGamingVideoUploaderTests
{
  id _mockToken;
  id _mockConfig;
}

- (void)setUp
{
  [super setUp];

  _mockToken = OCMClassMock([FBSDKAccessToken class]);
  [FBSDKAccessToken setCurrentAccessToken:_mockToken];

  _mockConfig = OCMClassMock([FBSDKGamingVideoUploaderConfiguration class]);
  OCMStub([_mockConfig videoURL]).andReturn([NSURL URLWithString:@"file://video.mp4"]);
}

- (void)testValuesAreSavedToConfig
{
  NSURL *const videoURL = [NSURL URLWithString:@"file://video.mp4"];

  FBSDKGamingVideoUploaderConfiguration *config =
  [[FBSDKGamingVideoUploaderConfiguration alloc]
   initWithVideoURL:videoURL
   caption:@"Cool Video"];

  XCTAssertEqual(config.caption, @"Cool Video");
  XCTAssertEqual(config.videoURL, videoURL);
}

- (void)testFailureWhenNoValidAccessTokenPresent
{
  [FBSDKAccessToken setCurrentAccessToken:nil];

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorAccessTokenRequired, "Expected error requiring a valid access token");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testNilVideoURLFails
{
  id nilVideoConfig = OCMClassMock([FBSDKGamingVideoUploaderConfiguration class]);

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:nilVideoConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorInvalidArgument, "Expected error requiring a non nil video url");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testBadVideoURLFails
{
  id badVideoConfig = OCMClassMock([FBSDKGamingVideoUploaderConfiguration class]);
  OCMStub([badVideoConfig videoURL]).andReturn([NSURL URLWithString:@"file://not-a-video.mp4"]);

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:badVideoConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorInvalidArgument, "Expected error requiring a non nil video url");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testVideoUploaderErrorsAreHandled
{
  __block id<FBSDKVideoUploaderDelegate> delegate;
  id mockUploader = [self mockVideoUploaderWithDelegateCapture:^(id<FBSDKVideoUploaderDelegate> obj) {
    delegate = obj;
  }];

  NSError *expectedError = [NSError errorWithDomain:NSURLErrorDomain code:123 userInfo:nil];

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == expectedError.code);
     actioned = true;
   }];

  [delegate videoUploader:mockUploader didFailWithError:expectedError];

  XCTAssertTrue(actioned);
}

- (void)testVideoUploaderErrorOnUnsuccessful
{
  __block id<FBSDKVideoUploaderDelegate> delegate;
  id mockUploader = [self mockVideoUploaderWithDelegateCapture:^(id<FBSDKVideoUploaderDelegate> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorUnknown);
     actioned = true;
   }];

  [delegate
   videoUploader:mockUploader
   didCompleteWithResults:@{
     @"success" : @(false)
   }];

  XCTAssertTrue(actioned);
}

- (void)testVideoUploaderSucceeds
{
  __block id<FBSDKVideoUploaderDelegate> delegate;
  id mockUploader = [self mockVideoUploaderWithDelegateCapture:^(id<FBSDKVideoUploaderDelegate> obj) {
    delegate = obj;
  }];

  __block BOOL actioned = false;
  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:_mockConfig
   andResultCompletionHandler:^(BOOL success, id result, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  [delegate
   videoUploader:mockUploader
   didCompleteWithResults:@{
     @"success" : @(true)
   }];

  XCTAssertTrue(actioned);
}

- (void)testVideoUploaderProgress
{
  __block id<FBSDKVideoUploaderDelegate> delegate;
  id mockUploader = [self mockVideoUploaderWithDelegateCapture:^(id<FBSDKVideoUploaderDelegate> obj) {
    delegate = obj;
  }];

  __block BOOL actionedFirst = false;
  __block void (^ProgressCheck)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) =
  ^void (int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    XCTAssertEqual(bytesSent, 0);
    XCTAssertEqual(totalBytesSent, 0);
    XCTAssertEqual(totalBytesExpectedToSend, 999);
    actionedFirst = true;
  };

  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:_mockConfig
   completionHandler:^(BOOL success, id result, NSError *_Nullable error) {}
   andProgressHandler:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
     ProgressCheck(bytesSent, totalBytesSent, totalBytesExpectedToSend);
   }];

  // Send some bytes
  [delegate
   videoChunkDataForVideoUploader:mockUploader
   startOffset:0
   endOffset:500];

  __block BOOL actionedSecond = false;
  ProgressCheck =
  ^void (int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    XCTAssertEqual(bytesSent, 500);
    XCTAssertEqual(totalBytesSent, 500);
    XCTAssertEqual(totalBytesExpectedToSend, 999);
    actionedSecond = true;
  };

  // Send some more bytes
  [delegate
   videoChunkDataForVideoUploader:mockUploader
   startOffset:500
   endOffset:999];

  __block BOOL actionedThird = false;
  ProgressCheck =
  ^void (int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    XCTAssertEqual(bytesSent, 499);
    XCTAssertEqual(totalBytesSent, 999);
    XCTAssertEqual(totalBytesExpectedToSend, 999);
    actionedThird = true;
  };

  // Finish upload
  [delegate
   videoUploader:mockUploader
   didCompleteWithResults:@{
     @"success" : @(true)
   }];

  XCTAssertTrue(actionedFirst);
  XCTAssertTrue(actionedSecond);
  XCTAssertTrue(actionedThird);
}

#pragma mark - Helpers

- (id)mockVideoUploaderWithDelegateCapture:(void (^)(id<FBSDKVideoUploaderDelegate>))captureHandler
{
  id mockDataChunkOne = OCMClassMock([NSData class]);
  OCMStub([mockDataChunkOne length]).andReturn(500);
  id mockDataChunkTwo = OCMClassMock([NSData class]);
  OCMStub([mockDataChunkTwo length]).andReturn(499);

  id mockFileHandle = OCMClassMock([NSFileHandle class]);
  OCMStub([mockFileHandle fileHandleForReadingFromURL:[OCMArg any] error:nil]).andReturn(mockFileHandle);
  OCMStub([mockFileHandle seekToEndOfFile]).andReturn(999);
  OCMStub([mockFileHandle readDataOfLength:500]).andReturn(mockDataChunkOne);
  OCMStub([mockFileHandle readDataOfLength:499]).andReturn(mockDataChunkTwo);

  id mockVideoUploader = OCMClassMock([FBSDKVideoUploader class]);
  OCMStub([mockVideoUploader alloc]).andReturn(mockVideoUploader);

  OCMStub(
    [mockVideoUploader initWithVideoName:[OCMArg any] videoSize:999 parameters:[OCMArg any] delegate:[OCMArg checkWithBlock:^BOOL (id obj) {
      captureHandler(obj);
      return true;
    }]]
  )
  .andReturn(mockVideoUploader);

  return mockVideoUploader;
}

@end
