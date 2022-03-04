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

final class AEMAdvertiserRuleFactoryTests: XCTestCase {

  let factory = AEMAdvertiserRuleFactory()

  func testCreateRuleWithJson() {
    XCTAssertNil(
      factory.createRule(withJson: nil),
      "Should not create valid Single Entry Rule with nil"
    )
    XCTAssertNil(
      factory.createRule(withJson: ""),
      "Should not create valid Single Entry Rule with empty string"
    )
    XCTAssertNil(
      factory.createRule(withJson: nil),
      "Should not create valid Single Entry Rule with nil"
    )
    XCTAssertNotNil(
      factory.createRule(withJson: #"{"and": [{"value": {"contains": "abc"}}]}"#),
      "Should create expected Multi Entry Rule"
    )
    XCTAssertNotNil(
      factory.createRule(withJson: #"{"value": {"contains": "abc"}}"#),
      "Should create expected Single Entry Rule"
    )
    XCTAssertNotNil(
      factory.createRule(withJson: #"{"and": [{"event": {"eq": "Lead"}}, {"or": [{"URL": {"contains": "achievetestprep.com"}}]}]}"#), // swiftlint:disable:this line_length
      "Should create expected nested Multi Entry Rule"
    )
  }

  func testCreateRuleWithDict() {
    XCTAssertNil(
      factory.createRule(withDict: [:]),
      "Should not create valid Single Entry Rule with emtpy dictionary"
    )
    XCTAssertNil(
      factory.createRule(withDict: ["value": ["contains": 10]]),
      "Should not create valid Single Entry Rule with invalid dictionary"
    )
    let multiEntryRule = factory.createRule(withDict: ["and": [SampleAEMData.validAdvertiserSingleEntryRuleJson1]]) as? AEMAdvertiserMultiEntryRule // swiftlint:disable:this line_length
    XCTAssertNotNil(
      multiEntryRule,
      "Should create expected Multi Entry Rule"
    )
    let singleEntryRule = factory.createRule(withDict: ["value": ["contains": "abc"]]) as? AEMAdvertiserSingleEntryRule // swiftlint:disable:this line_length
    XCTAssertNotNil(
      singleEntryRule,
      "Should create expected Single Entry Rule"
    )
  }

  func testCreateSingleEntryRuleWithValidDict() {
    var rule: AEMAdvertiserSingleEntryRule?
    rule = factory.createSingleEntryRule(withDict: SampleAEMData.validAdvertiserSingleEntryRuleJson1)
    XCTAssertTrue(
      SampleAEMData.advertiserSingleEntryRule1.isEqual(rule),
      "Should create the expected Single Entry Rule"
    )
    rule = factory.createSingleEntryRule(withDict: SampleAEMData.validAdvertiserSingleEntryRuleJson2)
    XCTAssertTrue(
      SampleAEMData.advertiserSingleEntryRule2.isEqual(rule),
      "Should create the expected Single Entry Rule"
    )
    rule = factory.createSingleEntryRule(withDict: SampleAEMData.validAdvertiserSingleEntryRuleJson3)
    XCTAssertTrue(
      SampleAEMData.advertiserSingleEntryRule3.isEqual(rule),
      "Should create the expected Single Entry Rule"
    )
  }

  func testCreateSingleEntryRuleWithInvalidDict() {
    XCTAssertNil(
      factory.createSingleEntryRule(withDict: [:]),
      "Should not create valid Single Entry Rule with empty dictionary"
    )
    XCTAssertNil(
      factory.createSingleEntryRule(withDict: ["contains": []]),
      "Should not create valid Single Entry Rule with invalid dictionary"
    )
    XCTAssertNil(
      factory.createSingleEntryRule(withDict: ["value": ["contains": 10]]),
      "Should not create valid Single Entry Rule with invalid dictionary"
    )
    XCTAssertNil(
      factory.createSingleEntryRule(withDict: ["value": ["lt": "abc"]]),
      "Should not create valid Single Entry Rule with invalid dictionary"
    )
  }

  func testCreateMultiEntryRuleWithValidDict() {
    zip(
      ["and", "or", "not"],
      [
        AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
        AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorOr,
        AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNot,
      ]
    ).forEach { opString, expectedOperator in
      let rule: AEMAdvertiserMultiEntryRule? = factory.createMultiEntryRule(
        withDict: [opString: [SampleAEMData.validAdvertiserSingleEntryRuleJson1, SampleAEMData.validAdvertiserSingleEntryRuleJson2]]) // swiftlint:disable:this line_length
      XCTAssertNotNil(
        rule,
        "Should create Multi Entry Rule with valid dictionary"
      )
      XCTAssertEqual(
        expectedOperator,
        rule?.operator,
        "Multi Entry Rule should have the expected operator"
      )
      XCTAssertEqual(
        2,
        rule?.rules.count,
        "Multi Entry Rule should have the expected number of subrules"
      )
    }
  }

  func testCreateMultiEntryRuleWithInvalidDict() {
    XCTAssertNil(
      factory.createMultiEntryRule(withDict: [:]),
      "Should not create valid Multi Entry Rule with empty dictionary"
    )
    XCTAssertNil(
      factory.createMultiEntryRule(withDict: ["contains": [["content": ["starts_with": "abc"]]]]),
      "Should not create valid Multi Entry Rule with invlaid operator"
    )
    XCTAssertNil(
      factory.createMultiEntryRule(withDict: ["and": []]),
      "Should not create valid Multi Entry Rule with empty subrules"
    )
    XCTAssertNil(
      factory.createMultiEntryRule(withDict: ["and": ["value": ["contains": 10]]]),
      "Should not create valid Multi Entry Rule with invlaid subrule"
    )
  }

  func testGetPrimaryKey() {
    XCTAssertEqual(
      factory.primaryKey(forRule: ["test_key": "abc"]),
      "test_key",
      "Should get the expected key of the dictionary"
    )
    XCTAssertNil(
      factory.primaryKey(forRule: [:]),
      "Should not get the unexpected key while the dictionay is empty"
    )
  }

  func testGetOperator() {
    XCTAssertEqual(
      factory.getOperator(["test_key": "abc"]),
      .Unknown,
      "Should get the expected Unknown operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["And": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      "Should get the expected AND operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["and": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      "Should get the expected AND operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["or": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorOr,
      "Should get the expected OR operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["not": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNot,
      "Should get the expected NOT operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["contains": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorContains,
      "Should get the expected Contains operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["not_contains": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNotContains,
      "Should get the expected NotContains operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["starts_with": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorStartsWith,
      "Should get the expected StartsWith operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["i_contains": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_Contains,
      "Should get the expected I_Contains operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["i_not_contains": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_NotContains,
      "Should get the expected I_NotContains operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["i_starts_with": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_StartsWith,
      "Should get the expected I_StartsWith operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["regex_match": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorRegexMatch,
      "Should get the expected REGEX_MATCH operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["eq": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
      "Should get the expected EQ operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["neq": "abc"]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNotEqual,
      "Should get the expected NEQ operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["lt": 10]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorLessThan,
      "Should get the expected LT operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["lte": 10]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorLessThanOrEqual,
      "Should get the expected LTE operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["gt": 10]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorGreaterThan,
      "Should get the expected GT operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["gte": 10]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorGreaterThanOrEqual,
      "Should get the expected GTE operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["i_is_any": ["abc"]]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_IsAny,
      "Should get the expected I_IsAny operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["i_is_not_any": ["abc"]]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_IsNotAny,
      "Should get the expected I_IsNotAny operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["is_any": ["abc"]]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorIsAny,
      "Should get the expected IsAny operator of the dictionary"
    )
    XCTAssertEqual(
      factory.getOperator(["is_not_any": ["abc"]]),
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorIsNotAny,
      "Should get the expected IsNotAny operator of the dictionary"
    )
  }

  func testIsOperatorForMultiEntryRule() {
    for ruleOperator in [
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorOr,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNot,
    ] {
      XCTAssertTrue(
        factory.isOperator(forMultiEntryRule: ruleOperator),
        "Should expect the operator for multi entry rule"
      )
    }
    for ruleOperator in [
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorContains,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNotContains,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorStartsWith,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_Contains,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_NotContains,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_StartsWith,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorRegexMatch,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorNotEqual,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorLessThan,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorLessThanOrEqual,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorGreaterThan,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorGreaterThanOrEqual,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_IsAny,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_IsNotAny,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorIsAny,
      AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorIsNotAny,
    ] {
      XCTAssertFalse(
        factory.isOperator(forMultiEntryRule: ruleOperator),
        "Should expect the operator not for multi entry rule"
      )
    }
  }
}

extension AEMAdvertiserSingleEntryRule {
  open override func isEqual(_ object: Any?) -> Bool { // swiftlint:disable:this override_in_extension
    if let rule = object as? AEMAdvertiserSingleEntryRule {
      let isOpEqual = self.operator == rule.operator
      let isParamKeyEqual = paramKey == rule.paramKey
      let isLinguisticConditionEqual = linguisticCondition == rule.linguisticCondition
      var isArrayConditionEqual = false
      if let array1 = arrayCondition {
        let array2 = rule.arrayCondition
        isArrayConditionEqual = array1 == array2
      } else {
        isArrayConditionEqual = rule.arrayCondition == nil
      }
      let isNumericConditionEqual = ((numericalCondition == nil && rule.numericalCondition == nil)
        || (numericalCondition?.isEqual(to: rule.numericalCondition ?? NSNumber(value: -1)) == true))
      return isOpEqual && isParamKeyEqual && isLinguisticConditionEqual
        && isArrayConditionEqual && isNumericConditionEqual
    }
    return false
  }
}

#endif
