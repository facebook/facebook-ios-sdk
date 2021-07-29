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
