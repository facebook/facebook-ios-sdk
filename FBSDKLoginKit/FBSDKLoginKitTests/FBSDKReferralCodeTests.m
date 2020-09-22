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

#import <XCTest/XCTest.h>

#import "FBSDKReferralCode.h"

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
