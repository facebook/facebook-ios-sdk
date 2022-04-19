/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMAdvertiserMultiEntryRule)
public final class _AEMAdvertiserMultiEntryRule: NSObject, _AEMAdvertiserRuleMatching, NSCopying, NSSecureCoding {

  enum CodingKeys: String, CodingKey {
    case `operator`
    case rules
  }

  let `operator`: _AEMAdvertiserRuleOperator
  let rules: [_AEMAdvertiserRuleMatching]

  @objc(initWithOperator:rules:)
  public init(with operator: _AEMAdvertiserRuleOperator, rules: [_AEMAdvertiserRuleMatching]) {
    self.operator = `operator`
    self.rules = rules
  }

  // MARK: - _AEMAdvertiserRuleMatching

  public func isMatchedEventParameters(_ eventParams: [String: Any]?) -> Bool {
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

  public static var supportsSecureCoding: Bool { true }

  public convenience init?(coder: NSCoder) {
    let `operator` = _AEMAdvertiserRuleOperator(rawValue: coder.decodeInteger(forKey: CodingKeys.operator.rawValue))
    let classes = [
      NSArray.self,
      _AEMAdvertiserMultiEntryRule.self,
      _AEMAdvertiserSingleEntryRule.self,
    ]
    let rules = coder.decodeObject(of: classes, forKey: CodingKeys.rules.rawValue) as? [_AEMAdvertiserRuleMatching]
    guard let `operator` = `operator`,
          let rules = rules else {
      return nil
    }
    self.init(with: `operator`, rules: rules)
  }

  public func encode(with coder: NSCoder) {
    coder.encode(`operator`.rawValue, forKey: CodingKeys.operator.rawValue)
    coder.encode(rules, forKey: CodingKeys.rules.rawValue)
  }

  // MARK: - NSCopying

  public func copy(with zone: NSZone? = nil) -> Any {
    self
  }
}

#endif
