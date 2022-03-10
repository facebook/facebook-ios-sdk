/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKGamingServicesKit;

@import FBSDKCoreKit;
@import TestTools;
@import XCTest;

@interface FBSDKContextDialogPresenterTests : XCTestCase <FBSDKContextDialogDelegate>
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FBSDKContextDialogPresenterTests

- (void)setUp
{
  [super setUp];

  FBSDKAccessToken.currentAccessToken = SampleAccessTokens.validToken;
}

- (void)tearDown
{
  FBSDKAccessToken.currentAccessToken = nil;

  [super tearDown];
}

- (void)testCreateContextDialog
{
  FBSDKCreateContextContent *content = [[FBSDKCreateContextContent alloc] initDialogContentWithPlayerID:@"123"];
  XCTAssertNotNil(
    [FBSDKContextDialogPresenter createContextDialogWithContent:content delegate:self]
  );
}

- (void)testShowCreateContextDialog
{
  FBSDKCreateContextContent *content = [[FBSDKCreateContextContent alloc] initDialogContentWithPlayerID:@"123"];
  XCTAssertNil(
    [FBSDKContextDialogPresenter showCreateContextDialogWithContent:content delegate:self]
  );
}

- (void)testSwitchContextDialog
{
  FBSDKSwitchContextContent *content = [[FBSDKSwitchContextContent alloc] initDialogContentWithContextID:@"123"];
  XCTAssertNotNil(
    [FBSDKContextDialogPresenter switchContextDialogWithContent:content delegate:self]
  );
}

- (void)testShowSwitchContextDialog
{
  FBSDKSwitchContextContent *content = [[FBSDKSwitchContextContent alloc] initDialogContentWithContextID:@"123"];
  XCTAssertNil(
    [FBSDKContextDialogPresenter showSwitchContextDialogWithContent:content delegate:self]
  );
}

- (void)testShowChooseContextDialog
{
  FBSDKChooseContextContent *content = [FBSDKChooseContextContent new];
  XCTAssertNotNil(
    [FBSDKContextDialogPresenter showChooseContextDialogWithContent:content delegate:self]
  );
}

#pragma clang diagnostic pop

// MARK: - FBSDKContextDialogDelegate methods

- (void)contextDialogDidComplete:(FBSDKContextWebDialog *)contextDialog {}

- (void)contextDialog:(FBSDKContextWebDialog *)contextDialog didFailWithError:(nonnull NSError *)error {}

- (void)contextDialogDidCancel:(FBSDKContextWebDialog *)contextDialog {}

@end
