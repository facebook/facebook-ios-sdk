/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

import XCTest

#if !os(tvOS)

final class AEMAdvertiserMultiEntryRuleTests: XCTestCase {

  enum Keys {
    static let ruleOperator = "operator"
    static let rules = "rules"
  }

  func testIsMatchedEventParametersForAnd() {
    let rule = _AEMAdvertiserMultiEntryRule(
      with: .and,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Should expect the parameter matched with the rule"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1),
        ]
      ),
      "Should not expect the parameter matched with the rule if the amount is low"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Should not expect the parameter matched with the rule if the card type is wrong"
    )
  }

  func testIsMatchedEventParametersForOr() {
    let rule = _AEMAdvertiserMultiEntryRule(
      with: .or,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 1),
        ]
      ),
      "Should not expect the parameter matched with the rule"
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1),
        ]
      ),
      "Should expect the parameter matched with the rule if the card type is the same"
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Should expect the parameter matched with the rule if amount is high"
    )
  }

  func testIsMatchedEventParametersForNot() {
    let rule = _AEMAdvertiserMultiEntryRule(
      with: .not,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 1),
        ]
      ),
      "Should expect the parameter matched with the rule"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1),
        ]
      ),
      "Should not expect the parameter matched with the rule if the card type is the same"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Should not expect the parameter matched with the rule if amount is high"
    )
  }

  func testIsMatchedEventParametersForNestedRules() {
    let andRule = _AEMAdvertiserMultiEntryRule(
      with: .and,
      rules: [SampleAEMSingleEntryRules.cardTypeRule2, SampleAEMSingleEntryRules.valueRule]
    )
    let orRule = _AEMAdvertiserMultiEntryRule(
      with: .or,
      rules: [SampleAEMSingleEntryRules.contentNameRule, SampleAEMSingleEntryRules.contentCategoryRule]
    )
    let nestedRule = _AEMAdvertiserMultiEntryRule(
      with: .and,
      rules: [andRule, orRule, SampleAEMSingleEntryRules.urlRule]
    )
    XCTAssertTrue(
      nestedRule.isMatchedEventParameters(
        [
          "URL": "thankyou.do.com",
          "content_category": "demand",
          "card_type": "blue_credit",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Shoule expect the rule is matched"
    )
    XCTAssertFalse(
      nestedRule.isMatchedEventParameters(
        [
          "URL": "thankyou.com",
          "content_category": "demand",
          "card_type": "blue_credit",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Shoule not expect the rule is matched with wrong URL"
    )
    XCTAssertFalse(
      nestedRule.isMatchedEventParameters(
        [
          "URL": "thankyou.do.com",
          "content_category": "required",
          "card_type": "blue_credit",
          "amount": NSNumber(value: 100),
        ]
      ),
      "Shoule not expect the rule is matched with wrong content_category"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      _AEMAdvertiserMultiEntryRule.supportsSecureCoding,
      "AEM Advertiser Multi Entry Rule should support secure coding"
    )
  }

  func testEncodingAndDecoding() throws {
    let entryRule = SampleAEMData.validAdvertiserMultiEntryRule
    let decodedObject = try CodabilityTesting.encodeAndDecode(entryRule)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, entryRule, .isCodable)
    XCTAssertNotEqual(decodedObject, entryRule, .isCodable) // isEqual Method hasn't been implemented

    // Test Properties
    XCTAssertEqual(decodedObject.operator.rawValue, entryRule.operator.rawValue)
    let rules = try XCTUnwrap(
      entryRule.rules as? [_AEMAdvertiserSingleEntryRule]
    )
    let decodedRules = try XCTUnwrap(
      decodedObject.rules as? [_AEMAdvertiserSingleEntryRule]
    )
    XCTAssertEqual(decodedRules, rules)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AEMAdvertiserMultiEntryRule should be encodable and decodable"
}

#endif
