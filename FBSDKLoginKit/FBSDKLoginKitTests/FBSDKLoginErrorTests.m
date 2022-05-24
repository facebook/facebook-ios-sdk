/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKLoginKit;
#import <XCTest/XCTest.h>

@interface FBSDKLoginErrorTests : XCTestCase

@end

@implementation FBSDKLoginErrorTests

- (void)testErrorDomain
{
  XCTAssertEqualObjects(FBSDKLoginErrorDomain, @"com.facebook.sdk.login");
}

- (void)testLoginErrorCodes
{
  XCTAssertEqual(FBSDKLoginErrorReserved, 300);
  XCTAssertEqual(FBSDKLoginErrorUnknown, 301);
  XCTAssertEqual(FBSDKLoginErrorPasswordChanged, 302);
  XCTAssertEqual(FBSDKLoginErrorUserCheckpointed, 303);
  XCTAssertEqual(FBSDKLoginErrorUserMismatch, 304);
  XCTAssertEqual(FBSDKLoginErrorUnconfirmedUser, 305);
  XCTAssertEqual(FBSDKLoginErrorSystemAccountAppDisabled, 306);
  XCTAssertEqual(FBSDKLoginErrorSystemAccountUnavailable, 307);
  XCTAssertEqual(FBSDKLoginErrorBadChallengeString, 308);
  XCTAssertEqual(FBSDKLoginErrorInvalidIDToken, 309);
  XCTAssertEqual(FBSDKLoginErrorMissingAccessToken, 310);
}

- (void)testDeviceLoginErrorCodes
{
  XCTAssertEqual(FBSDKDeviceLoginErrorExcessivePolling, 1349172);
  XCTAssertEqual(FBSDKDeviceLoginErrorAuthorizationDeclined, 1349173);
  XCTAssertEqual(FBSDKDeviceLoginErrorAuthorizationPending, 1349174);
  XCTAssertEqual(FBSDKDeviceLoginErrorCodeExpired, 1349152);
}

@end
