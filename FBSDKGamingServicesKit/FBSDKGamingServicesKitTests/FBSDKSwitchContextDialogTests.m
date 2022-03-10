/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKGamingServicesKit;
@import TestTools;
@import XCTest;

@interface FBSDKSwitchContextDialogTests : XCTestCase <FBSDKContextDialogDelegate>

@property (nullable, nonatomic) FBSDKSwitchContextDialog *dialog;
@property (nullable, nonatomic) FBSDKSwitchContextContent *content;
@property (nullable, nonatomic) TestWindowFinder *windowFinder;

@end

@implementation FBSDKSwitchContextDialogTests

- (void)setUp
{
  [super setUp];

  self.content = [[FBSDKSwitchContextContent alloc] initDialogContentWithContextID:@"123"];
  self.windowFinder = [TestWindowFinder new];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  self.dialog = [FBSDKSwitchContextDialog dialogWithContent:self.content
                                               windowFinder:self.windowFinder
                                                   delegate:self];
  #pragma clang diagnostic pop
}

- (void)tearDown
{
  self.content = nil;
  self.windowFinder = nil;
  self.dialog = nil;

  [super tearDown];
}

- (void)testCreatingWithFactoryMethod
{
  XCTAssertTrue(
    [self.dialog isKindOfClass:FBSDKSwitchContextDialog.class],
    "The factory method should return the expected concrete dialog"
  );
  XCTAssertEqualObjects(
    self.dialog.dialogContent,
    self.content,
    "The dialog should be created with the provided content"
  );
  XCTAssertEqualObjects(
    self.dialog.delegate,
    self,
    "The dialog should be created with the provided delegate"
  );
}

// MARK: - FBSDKContextDialogDelegate

- (void)contextDialogDidComplete:(FBSDKContextWebDialog *)contextDialog {}

- (void)contextDialog:(FBSDKContextWebDialog *)contextDialog didFailWithError:(NSError *)error {}

- (void)contextDialogDidCancel:(FBSDKContextWebDialog *)contextDialog {}

@end
