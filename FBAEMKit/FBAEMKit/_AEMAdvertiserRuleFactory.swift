/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMAdvertiserRuleFactory)
public final class _AEMAdvertiserRuleFactory: NSObject, _AEMAdvertiserRuleProviding {

  // MARK: - _AEMAdvertiserRuleProviding

  public func createRule(json: String?) -> _AEMAdvertiserRuleMatching? {
    guard let json = json,
          let data = json.data(using: .utf8)
    else {
      return nil
    }

    do {
      let rule = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
      return createRule(dictionary: rule)
    } catch {
      print("Fail to parse Advertiser Rules with JSON")
      return nil
    }
  }

  public func createRule(dictionary: [String: Any]) -> _AEMAdvertiserRuleMatching? {
    let `operator` = getOperator(from: dictionary)

    if isOperatorForMultiEntryRule(`operator`) {
      return createMultiEntryRule(from: dictionary)
    } else {
      return createSingleEntryRule(from: dictionary)
    }
  }

  // MARK: - Internal

  func createMultiEntryRule(from dictionary: [String: Any]) -> _AEMAdvertiserMultiEntryRule? {
    guard !dictionary.isEmpty,
          let opString = primaryKey(for: dictionary)
    else {
      return nil
    }

    let `operator` = getOperator(from: dictionary)

    if !isOperatorForMultiEntryRule(`operator`) {
      return nil
    }

    let subrules: [[String: Any]] = dictionary[opString] as? [[String: Any]] ?? []
    var rules: [_AEMAdvertiserRuleMatching] = []

    for subrule in subrules {
      guard let entryRule = createRule(dictionary: subrule) else {
        return nil
      }
      rules.append(entryRule)
    }

    guard !rules.isEmpty else {
      return nil
    }

    return _AEMAdvertiserMultiEntryRule(with: `operator`, rules: rules)
  }

  func createSingleEntryRule(from dictionary: [String: Any]) -> _AEMAdvertiserSingleEntryRule? {
    guard let paramKey = primaryKey(for: dictionary) else {
      return nil
    }

    let rawRule: [String: Any] = dictionary[paramKey] as? [String: Any] ?? [:]

    guard let encodedOperator = primaryKey(for: rawRule) else {
      return nil
    }

    let `operator`: _AEMAdvertiserRuleOperator = getOperator(from: rawRule)

    var linguisticCondition: String?
    var numericalCondition: NSNumber?
    var arrayCondition: [String]?

    switch `operator` {
    case .contains,
         .notContains,
         .startsWith,
         .caseInsensitiveContains,
         .caseInsensitiveNotContains,
         .caseInsensitiveStartsWith,
         .regexMatch,
         .equal,
         .notEqual:
      linguisticCondition = rawRule[encodedOperator] as? String

    case .lessThan,
         .lessThanOrEqual,
         .greaterThan,
         .greaterThanOrEqual:
      numericalCondition = rawRule[encodedOperator] as? NSNumber

    case .caseInsensitiveIsAny, .caseInsensitiveIsNotAny, .isAny, .isNotAny:
      arrayCondition = rawRule[encodedOperator] as? [String]

    case .unknown:
      return nil
    default:
      return nil
    }

    if linguisticCondition != nil || numericalCondition != nil || arrayCondition?.isEmpty == false {
      return _AEMAdvertiserSingleEntryRule(
        with: `operator`,
        paramKey: paramKey,
        linguisticCondition: linguisticCondition,
        numericalCondition: numericalCondition,
        arrayCondition: arrayCondition
      )
    } else {
      return nil
    }
  }

  func primaryKey(for rule: [String: Any]) -> String? {
    rule.keys.first
  }

  func getOperator(from rule: [String: Any]) -> _AEMAdvertiserRuleOperator {
    guard let key = primaryKey(for: rule) else {
      return .unknown
    }

    let operatorKeys: [String] = [
      // UNCRUSTIFY_FORMAT_OFF
      "unknown", // FBAEMAdvertiserRuleOperatorUnknown
      "and", // FBAEMAdvertiserRuleOperatorAnd
      "or", // FBAEMAdvertiserRuleOperatorOr
      "not", // FBAEMAdvertiserRuleOperatorNot
      "contains", // FBAEMAdvertiserRuleOperatorContains
      "not_contains", // FBAEMAdvertiserRuleOperatorNotContains
      "starts_with", // FBAEMAdvertiserRuleOperatorStartsWith
      "i_contains", // FBAEMAdvertiserRuleOperatorCaseInsensitiveContains
      "i_not_contains", // FBAEMAdvertiserRuleOperatorCaseInsensitiveNotContains
      "i_starts_with", // FBAEMAdvertiserRuleOperatorCaseInsensitiveStartsWith
      "regex_match", // FBAEMAdvertiserRuleOperatorRegexMatch
      "eq", // FBAEMAdvertiserRuleOperatorEqual
      "neq", // FBAEMAdvertiserRuleOperatorNotEqual
      "lt", // FBAEMAdvertiserRuleOperatorLessThan
      "lte", // FBAEMAdvertiserRuleOperatorLessThanOrEqual
      "gt", // FBAEMAdvertiserRuleOperatorGreaterThan
      "gte", // FBAEMAdvertiserRuleOperatorGreaterThanOrEqual
      "i_is_any", // FBAEMAdvertiserRuleOperatorCaseInsensitiveIsAny
      "i_is_not_any", // FBAEMAdvertiserRuleOperatorCaseInsensitiveIsNotAny
      "is_any", // FBAEMAdvertiserRuleOperatorIsAny
      "is_not_any", // FBAEMAdvertiserRuleOperatorIsNotAny
      // UNCRUSTIFY_FORMAT_ON
    ]

    guard let index = operatorKeys.firstIndex(of: key.lowercased()) else {
      return .unknown
    }

    return _AEMAdvertiserRuleOperator(rawValue: index) ?? .unknown
  }

  func isOperatorForMultiEntryRule(_ operator: _AEMAdvertiserRuleOperator) -> Bool {
    let operators: [_AEMAdvertiserRuleOperator] = [.and, .or, .not]
    return operators.contains(`operator`)
  }
}

#endif
