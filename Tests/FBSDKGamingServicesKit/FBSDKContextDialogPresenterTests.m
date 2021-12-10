/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import XCTest;
@import TestTools;
@import FBSDKGamingServicesKit;

@interface FBSDKContextDialogPresenterTests : XCTestCase <FBSDKContextDialogDelegate>
@end

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
  XCTAssertNil([FBSDKContextDialogPresenter showCreateContextDialogWithContent:content delegate:self]);
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
  XCTAssertNil([FBSDKContextDialogPresenter showSwitchContextDialogWithContent:content delegate:self]);
}

- (void)testShowChooseContextDialog
{
  FBSDKChooseContextContent *content = [FBSDKChooseContextContent new];
  XCTAssertNotNil([FBSDKContextDialogPresenter showChooseContextDialogWithContent:content delegate:self]);
}

// MARK: - FBSDKContextDialogDelegate methods

- (void)contextDialog:(nonnull FBSDKContextWebDialog *)contextDialog didFailWithError:(nonnull NSError *)error {}

- (void)contextDialogDidCancel:(nonnull FBSDKContextWebDialog *)contextDialog {}

- (void)contextDialogDidComplete:(nonnull FBSDKContextWebDialog *)contextDialog {}

@end
