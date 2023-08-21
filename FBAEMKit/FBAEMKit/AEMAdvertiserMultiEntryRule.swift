/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class AEMAdvertiserMultiEntryRule: NSObject, AEMAdvertiserRuleMatching, NSSecureCoding {

  enum CodingKeys: String, CodingKey {
    case `operator`
    case rules
  }

  let `operator`: AEMAdvertiserRuleOperator
  let rules: [AEMAdvertiserRuleMatching]

  init(with operator: AEMAdvertiserRuleOperator, rules: [AEMAdvertiserRuleMatching]) {
    self.operator = `operator`
    self.rules = rules
  }

  // MARK: - AEMAdvertiserRuleMatching

  func isMatchedEventParameters(_ eventParams: [String: Any]?) -> Bool {
    var isMatched = `operator` != .or
    for rule in rules {
      let doesSubruleMatch = rule.isMatchedEventParameters(eventParams)
      if `operator` == .and {
        isMatched = isMatched && doesSubruleMatch
      }
      if `operator` == .or {
        isMatched = isMatched || doesSubruleMatch
      }
      if `operator` == .not {
        isMatched = isMatched && !doesSubruleMatch
      }
    }
    return isMatched
  }

  // MARK: - NSCoding

  static var supportsSecureCoding: Bool { true }

  convenience init?(coder: NSCoder) {
    let `operator` = AEMAdvertiserRuleOperator(rawValue: coder.decodeInteger(forKey: CodingKeys.operator.rawValue))
    let classes = [
      NSArray.self,
      AEMAdvertiserMultiEntryRule.self,
      AEMAdvertiserSingleEntryRule.self,
    ]
    let rules = coder.decodeObject(of: classes, forKey: CodingKeys.rules.rawValue) as? [AEMAdvertiserRuleMatching]
    guard let `operator` = `operator`,
          let rules = rules else {
      return nil
    }
    self.init(with: `operator`, rules: rules)
  }

  func encode(with coder: NSCoder) {
    coder.encode(`operator`.rawValue, forKey: CodingKeys.operator.rawValue)
    coder.encode(rules, forKey: CodingKeys.rules.rawValue)
  }
}
