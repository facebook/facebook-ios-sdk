/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation

final class MACARuleMatchingManagerTests: XCTestCase {
  let macaRuleMatchingManager = MACARuleMatchingManager()

  func testStringCompNotExistedDataValue() {
    XCTAssertFalse(
      macaRuleMatchingManager.stringComparison(
        variable: "card_type", values: ["eq": "platinum"], data: ["event": "CompleteRegistration"]
      ),
      "It should be considered as unmatched if data doesn't have the variable"
    )
  }

  func testStringCompContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["contains": "xxxxx"],
        data: ["event": "CompleteRegistration", "url": "www.xxxxx.com"]
      )
    )
  }

  func testStringCompIContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["i_contains": "xxxxx"],
        data: ["event": "CompleteRegistration", "url": "www.xxXxx.com"]
      )
    )
  }

  func testStringCompRegexMatch() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["regex_match": "eylea.us/support/?$|eylea.us/support/?"],
        data: ["event": "CompleteRegistration", "url": "eylea.us/support"]
      )
    )
  }

  func testStringCompEq() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "event",
        values: ["eq": "CompleteRegistration"],
        data: ["event": "CompleteRegistration", "url": "eylea.us/support"]
      )
    )
  }

  func testStringCompNeq() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["neq": "0"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompLt() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["lt": "10"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompLte() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["lte": "30"],
        data: ["value": "30"]
      )
    )
  }

  func testStringCompGt() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["gt": "0"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompGte() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["gte": "100"],
        data: ["value": "100"]
      )
    )
  }

  func testStringCompInvalidOp() {
    XCTAssertFalse(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["none": "0"],
        data: ["value": "1"]
      )
    )
  }
}
