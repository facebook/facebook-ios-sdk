/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

let validReferralCode1 = "abcd"
let validReferralCode2 = "123"
let validReferralCode3 = "123abc"

let invalidReferralCode1 = "abd?"
let invalidReferralCode2 = "a b1"
let invalidReferralCode3 = "  "
let invalidReferralCode4 = "\n\n"

let emptyReferralCode = ""

final class ReferralCodeTests: XCTestCase {

  func testCreateValidReferralCodeShouldSucceed() {
    self.assertCreationSucceedWithString(validReferralCode1)
    self.assertCreationSucceedWithString(validReferralCode2)
  }

  func testCreateInvalidReferralCodeShoudFail() {
    self.assertCreationFailWithString(invalidReferralCode1)
    self.assertCreationFailWithString(invalidReferralCode2)
    self.assertCreationFailWithString(invalidReferralCode3)
    self.assertCreationFailWithString(invalidReferralCode4)
  }

  func testCreateEmptyReferralCodeShoudFail() {
    self.assertCreationFailWithString(emptyReferralCode)
  }

  func assertCreationFailWithString(_ string: String, file: StaticString = #file, line: UInt = #line) {
    let referralCode = ReferralCode.initWith(string)
    XCTAssertNil(referralCode, file: file, line: line)
  }

  func assertCreationSucceedWithString(_ string: String, file: StaticString = #file, line: UInt = #line) {
    let referralCode = ReferralCode.initWith(string)
    XCTAssertNotNil(referralCode)
    XCTAssertEqual(referralCode?.value, string)
  }
}
