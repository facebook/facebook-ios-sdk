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

import FBAEMKit
import XCTest

#if !os(tvOS)

class FBAEMAdvertiserMultiEntryRuleTests: XCTestCase {

  enum Keys {
      static let ruleOperator = "operator"
      static let rules = "rules"
  }

  func testIsMatchedEventParametersForAnd() {
    let rule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 100)
        ]
      ),
      "Should expect the parameter matched with the rule"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1)
        ]
      ),
      "Should not expect the parameter matched with the rule if the amount is low"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100)
        ]
      ),
      "Should not expect the parameter matched with the rule if the card type is wrong"
    )
  }

  func testIsMatchedEventParametersForOr() {
    let rule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorOr,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 1)
        ]
      ),
      "Should not expect the parameter matched with the rule"
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1)
        ]
      ),
      "Should expect the parameter matched with the rule if the card type is the same"
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100)
        ]
      ),
      "Should expect the parameter matched with the rule if amount is high"
    )
  }

  func testIsMatchedEventParametersForNot() {
    let rule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNot,
      rules: [SampleAEMSingleEntryRules.cardTypeRule1, SampleAEMSingleEntryRules.valueRule]
    )
    XCTAssertTrue(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 1)
        ]
      ),
      "Should expect the parameter matched with the rule"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "platium",
          "amount": NSNumber(value: 1)
        ]
      ),
      "Should not expect the parameter matched with the rule if the card type is the same"
    )
    XCTAssertFalse(
      rule.isMatchedEventParameters(
        [
          "card_type": "gold",
          "amount": NSNumber(value: 100)
        ]
      ),
      "Should not expect the parameter matched with the rule if amount is high"
    )
  }

  func testIsMatchedEventParametersForNestedRules() {
    let andRule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      rules: [SampleAEMSingleEntryRules.cardTypeRule2, SampleAEMSingleEntryRules.valueRule]
    )
    let orRule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorOr,
      rules: [SampleAEMSingleEntryRules.contentNameRule, SampleAEMSingleEntryRules.contentCategoryRule]
    )
    let nestedRule = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      rules: [andRule, orRule, SampleAEMSingleEntryRules.urlRule]
    )
    XCTAssertTrue(
      nestedRule.isMatchedEventParameters(
        [
          "URL": "thankyou.do.com",
          "content_category": "demand",
          "card_type": "blue_credit",
          "amount": NSNumber(value: 100)
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
          "amount": NSNumber(value: 100)
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
          "amount": NSNumber(value: 100)
        ]
      ),
      "Shoule not expect the rule is matched with wrong content_category"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AEMAdvertiserMultiEntryRule.supportsSecureCoding,
      "AEM Advertiser Multi Entry Rule should support secure coding"
    )
  }

  func testEncoding() throws {
    let coder = TestCoder()
    let entryRule = SampleAEMData.validAdvertiserMultiEntryRule
    entryRule.encode(with: coder)

    let ruleOperator = coder.encodedObject[Keys.ruleOperator] as? NSNumber
    XCTAssertEqual(
      ruleOperator?.intValue,
      entryRule.operator.rawValue,
      "Should encode the expected operator with the correct key"
    )
    let rules = try XCTUnwrap(coder.encodedObject[Keys.rules] as? [FBAEMAdvertiserRuleMatching])
    let rule = try XCTUnwrap(rules[0] as? AEMAdvertiserSingleEntryRule)
    let expectedRule = try XCTUnwrap(entryRule.rules[0] as? AEMAdvertiserSingleEntryRule)
    XCTAssertEqual(
      rule,
      expectedRule,
      "Should encode the expected rule with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AEMAdvertiserMultiEntryRule(coder: decoder)

    XCTAssertEqual(
      decoder.decodedObject[Keys.ruleOperator] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the operator key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.rules] as? NSSet,
      [NSArray.self, AEMAdvertiserMultiEntryRule.self, AEMAdvertiserSingleEntryRule.self],
      "Should decode the expected type for the rules key"
    )
  }
}

#endif
