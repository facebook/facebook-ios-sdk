/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>

 #import <TestTools/TestTools-Swift.h>
#else
@import FBSDKCoreKit;
@import TestTools;
#endif

#import <XCTest/XCTest.h>

#import "FBSDKMessageDialog.h"
#import "FBSDKMessageDialog+Testing.h"
#import "FBSDKShareKitTestUtility.h"
#import "FBSDKShareModelTestUtility.h"
#import "FakeSharingDelegate.h"

@interface FBSDKMessageDialogTests : XCTestCase

@property (nonatomic) TestInternalUtility *appAvailabilityChecker;
@property (nonatomic) FakeSharingDelegate *delegate;
@property (nonatomic) FBSDKMessageDialog *dialog;

@end

@implementation FBSDKMessageDialogTests

- (void)setUp
{
  [super setUp];

  self.appAvailabilityChecker = [TestInternalUtility new];
  self.delegate = [FakeSharingDelegate new];
  self.dialog = [[FBSDKMessageDialog alloc] initWithContent:nil
                                                   delegate:self.delegate
                                     appAvailabilityChecker:self.appAvailabilityChecker];
}

- (void)testCanShow
{
  self.appAvailabilityChecker.isMessengerAppInstalled = YES;
  XCTAssertTrue([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertTrue([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertTrue([self.dialog canShow]);
  self.appAvailabilityChecker.isMessengerAppInstalled = NO;
  XCTAssertFalse([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertFalse([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse([self.dialog canShow]);
  self.dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([self.dialog canShow]);
}

- (void)testValidate
{
  FBSDKMessageDialog *dialog = [FBSDKMessageDialog new];
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
  self.appAvailabilityChecker.isMessengerAppInstalled = NO;
  [self.dialog show];

  XCTAssertEqualObjects(
    self.delegate.capturedError.domain,
    FBSDKShareErrorDomain,
    "Failure to show a message dialog should present an error with the expected domain."
  );
  XCTAssertEqual(
    self.delegate.capturedError.code,
    FBSDKShareErrorDialogNotAvailable,
    "Failure to show a message dialog should present an error with the expected code."
  );
  XCTAssertEqualObjects(
    self.delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
    @"Message dialog is not available.",
    "Failure to show a message dialog should present an error with the expected message."
  );
}

- (void)testShowInvokesDelegateWhenMissingContent
{
  self.appAvailabilityChecker.isMessengerAppInstalled = YES;
  [self.dialog show];

  XCTAssertEqualObjects(
    self.delegate.capturedError.domain,
    FBSDKShareErrorDomain,
    "Failure to show a message dialog should present an error with the expected domain."
  );
  XCTAssertEqual(
    self.delegate.capturedError.code,
    FBSDKErrorInvalidArgument,
    "Failure to show a message dialog should present an error with the expected code."
  );
  XCTAssertEqualObjects(
    self.delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
    @"Value for shareContent is required.",
    "Failure to show a message dialog should present an error with the expected message."
  );
}

- (void)testShowInvokesDelegateWhenCannotValidate
{
  FBSDKMessageDialog *dialog = [[FBSDKMessageDialog alloc] initWithContent:[FBSDKShareModelTestUtility cameraEffectContent]
                                                                  delegate:self.delegate
                                                    appAvailabilityChecker:self.appAvailabilityChecker];
  self.appAvailabilityChecker.isMessengerAppInstalled = YES;
  [dialog show];

  XCTAssertEqualObjects(
    self.delegate.capturedError.domain,
    FBSDKShareErrorDomain,
    "Failure to show a message dialog should present an error with the expected domain."
  );
  XCTAssertEqual(
    self.delegate.capturedError.code,
    FBSDKErrorInvalidArgument,
    "Failure to show a message dialog should present an error with the expected code."
  );
  XCTAssertEqualObjects(
    self.delegate.capturedError.userInfo[FBSDKErrorDeveloperMessageKey],
    @"Message dialog does not support FBSDKShareCameraEffectContent.",
    "Failure to show a message dialog should present an error with the expected message."
  );
}

@end
