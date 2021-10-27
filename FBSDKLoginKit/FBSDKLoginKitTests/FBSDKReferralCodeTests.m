/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKLoginKit/FBSDKReferralCode.h>
#else
 #import "FBSDKReferralCode.h"
#endif

static NSString *const _validReferralCode1 = @"abcd";
static NSString *const _validReferralCode2 = @"123";
static NSString *const _validReferralCode3 = @"123abc";

static NSString *const _invalidReferralCode1 = @"abd?";
static NSString *const _invalidReferralCode2 = @"a b1";
static NSString *const _invalidReferralCode3 = @"  ";
static NSString *const _invalidReferralCode4 = @"\n\n";

static NSString *const _emptyReferralCode = @"";

@interface FBSDKReferralCodeTests : XCTestCase

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FBSDKReferralCodeTests

- (void)testCreateValidReferralCodeShouldSucceed
{
  [self assertCreationSucceedWithString:_validReferralCode1];
  [self assertCreationSucceedWithString:_validReferralCode2];
}

- (void)testCreateInvalidReferralCodeShoudFail
{
  [self assertCreationFailWithString:_invalidReferralCode1];
  [self assertCreationFailWithString:_invalidReferralCode2];
  [self assertCreationFailWithString:_invalidReferralCode3];
  [self assertCreationFailWithString:_invalidReferralCode4];
}

- (void)testCreateEmptyReferralCodeShoudFail
{
  [self assertCreationFailWithString:_emptyReferralCode];
}

- (void)assertCreationFailWithString:(NSString *)string
{
  FBSDKReferralCode *referralCode = [FBSDKReferralCode initWithString:string];

  XCTAssertNil(referralCode);
}

- (void)assertCreationSucceedWithString:(NSString *)string
{
  FBSDKReferralCode *referralCode = [FBSDKReferralCode initWithString:string];
  XCTAssertNotNil(referralCode);
  XCTAssertEqual(referralCode.value, string);
}

@end

#pragma clange diagnostic pop
