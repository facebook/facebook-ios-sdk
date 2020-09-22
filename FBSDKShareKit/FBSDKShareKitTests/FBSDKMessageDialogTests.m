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
#import <UIKit/UIKit.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKMessageDialog.h"
#import "FBSDKShareKitTestUtility.h"
#import "FBSDKShareModelTestUtility.h"
#import "FakeSharingDelegate.h"

@interface FBSDKMessageDialogTests : XCTestCase
@end

@implementation FBSDKMessageDialogTests

- (void)_mockApplicationForURL:(NSURL *)URL canOpen:(BOOL)canOpen usingBlock:(void (^)(void))block
{
  if (block != NULL) {
    id applicationMock = OCMClassMock(UIApplication.class);
    OCMStub([applicationMock canOpenURL:URL]).andReturn(canOpen);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    block();
    [applicationMock stopMocking];
  }
}

- (void)setUp
{
  [super setUp];
  [FBSDKShareKitTestUtility mainBundleMock];
}

- (void)testCanShow
{
  FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] init];
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    XCTAssertTrue([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
    XCTAssertTrue([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertTrue([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertTrue([dialog canShow]);
  }];
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:NO usingBlock:^{
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertFalse([dialog canShow]);
  }];
}

- (void)testValidate
{
  FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] init];
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog validateWithError:&error],
    @"Known valid content should pass validation without issue if this test fails then the criteria for the fixture may no longer be valid"
  );
  XCTAssertNil(
    error,
    @"A successful validation should not populate the error reference that was passed to it"
  );

  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  error = nil;
  XCTAssertTrue(
    [dialog validateWithError:&error],
    @"Known valid content should pass validation without issue if this test fails then the criteria for the fixture may no longer be valid"
  );
  XCTAssertNil(
    error,
    @"A successful validation should not populate the error reference that was passed to it"
  );

  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  error = nil;
  XCTAssertTrue(
    [dialog validateWithError:&error],
    @"Known valid content should pass validation without issue if this test fails then the criteria for the fixture may no longer be valid"
  );
  XCTAssertNil(
    error,
    @"A successful validation should not populate the error reference that was passed to it"
  );

  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];
  error = nil;
  XCTAssertFalse(
    [dialog validateWithError:&error],
    @"Should not successfully validate share content that is known to be missing content"
  );
  XCTAssertNotNil(
    error,
    @"A failed validation should populate the error reference that was passed to it"
  );
}

- (void)testShowInvokesDelegateWhenCannotShow
{
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:NO usingBlock:^{
    FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] init];
    FakeSharingDelegate *delegate = [FakeSharingDelegate new];
    dialog.delegate = delegate;

    [dialog show];

    XCTAssertEqualObjects(
      delegate.capturedError.domain,
      FBSDKShareErrorDomain,
      "Failure to show a message dialog should present an error with the expected domain."
    );
    XCTAssertEqual(
      delegate.capturedError.code,
      FBSDKShareErrorDialogNotAvailable,
      "Failure to show a message dialog should present an error with the expected code."
    );
    XCTAssertEqualObjects(
      delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
      @"Message dialog is not available.",
      "Failure to show a message dialog should present an error with the expected message."
    );
  }];
}

- (void)testShowInvokesDelegateWhenMissingContent
{
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] init];
    FakeSharingDelegate *delegate = [FakeSharingDelegate new];
    dialog.delegate = delegate;

    [dialog show];

    XCTAssertEqualObjects(
      delegate.capturedError.domain,
      FBSDKShareErrorDomain,
      "Failure to show a message dialog should present an error with the expected domain."
    );
    XCTAssertEqual(
      delegate.capturedError.code,
      FBSDKErrorInvalidArgument,
      "Failure to show a message dialog should present an error with the expected code."
    );
    XCTAssertEqualObjects(
      delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
      @"Value for shareContent is required.",
      "Failure to show a message dialog should present an error with the expected message."
    );
  }];
}

- (void)testShowInvokesDelegateWhenCannotValidate
{
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] init];
    // Using invalid share content to force validation failure
    dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];
    FakeSharingDelegate *delegate = [FakeSharingDelegate new];
    dialog.delegate = delegate;

    [dialog show];

    XCTAssertEqualObjects(
      delegate.capturedError.domain,
      FBSDKShareErrorDomain,
      "Failure to show a message dialog should present an error with the expected domain."
    );
    XCTAssertEqual(
      delegate.capturedError.code,
      FBSDKErrorInvalidArgument,
      "Failure to show a message dialog should present an error with the expected code."
    );
    XCTAssertEqualObjects(
      delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
      @"Message dialog does not support FBSDKShareCameraEffectContent.",
      "Failure to show a message dialog should present an error with the expected message."
    );
  }];
}

@end
