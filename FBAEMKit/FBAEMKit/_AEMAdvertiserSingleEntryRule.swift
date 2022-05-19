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
@objc(FBAEMAdvertiserSingleEntryRule)
public final class _AEMAdvertiserSingleEntryRule: NSObject, NSCopying, NSSecureCoding, _AEMAdvertiserRuleMatching {

  public internal(set) var `operator`: _AEMAdvertiserRuleOperator
  public let paramKey: String
  public let linguisticCondition: String?
  public let numericalCondition: Double?
  public let arrayCondition: [String]?

  private enum Keys {
    static let `operator` = "operator"
    static let param = "param_key"
    static let stringValue = "string_value"
    static let numberValue = "number_value"
    static let arrayValue = "array_value"
  }

  private enum Delimeter {
    static let param = "."
    static let asterisk = "[*]"
  }

  // MRAK: - Init

  public init(
    operator: _AEMAdvertiserRuleOperator,
    paramKey: String,
    linguisticCondition: String?,
    numericalCondition: Double?,
    arrayCondition: [String]?
  ) {
    self.operator = `operator`
    self.paramKey = paramKey
    self.linguisticCondition = linguisticCondition
    self.numericalCondition = numericalCondition
    self.arrayCondition = arrayCondition
    super.init()
  }

  @objc(initWithOperator:paramKey:linguisticCondition:numericalCondition:arrayCondition:)
  public convenience init(
    with operator: _AEMAdvertiserRuleOperator,
    paramKey: String,
    linguisticCondition: String?,
    numericalCondition: NSNumber?,
    arrayCondition: [String]?
  ) {
    self.init(
      operator: `operator`,
      paramKey: paramKey,
      linguisticCondition: linguisticCondition,
      numericalCondition: numericalCondition?.doubleValue,
      arrayCondition: arrayCondition
    )
  }

  // MARK: - _AEMAdvertiserRuleMatching

  public func isMatchedEventParameters(_ eventParams: [String: Any]?) -> Bool {
    let paramPath = paramKey.components(separatedBy: Delimeter.param)
    return isMatchedEventParameters(eventParams: eventParams, paramPath: paramPath)
  }

  func isMatchedEventParameters(eventParams: [String: Any]?, paramPath: [String]) -> Bool {
    guard let eventParams = eventParams, !eventParams.isEmpty else {
      return false
    }
    let param = paramPath.first
    if let param = param,
       param.hasSuffix(Delimeter.asterisk) == true {
      return isMatched(withAsteriskParam: param, eventParameters: eventParams, paramPath: paramPath)
    }

    // if data does not contain the key, we should return false directly.
    guard let param = param,
          eventParams.keys.contains(param) else {
      return false
    }

    // Apply operator rule if the last param is reached
    if paramPath.count == 1 {
      var stringValue: String?
      var numericalValue: Double?
      switch `operator` {
      case .contains,
           .notContains,
           .startsWith,
           .caseInsensitiveContains,
           .caseInsensitiveNotContains,
           .caseInsensitiveStartsWith,
           .regexMatch,
           .equal,
           .notEqual,
           .caseInsensitiveIsAny,
           .caseInsensitiveIsNotAny,
           .isAny,
           .isNotAny:
        stringValue = eventParams[param] as? String

      case .lessThan,
           .lessThanOrEqual,
           .greaterThan,
           .greaterThanOrEqual:
        numericalValue = eventParams[param] as? Double

      default:
        break
      }

      return isMatched(withStringValue: stringValue, numericalValue: numericalValue)
    }

    let subParams = eventParams[param] as? [String: Any]
    let subParamPath = Array(paramPath.dropFirst())
    return isMatchedEventParameters(eventParams: subParams, paramPath: subParamPath)
  }

  func isMatched(withAsteriskParam param: String, eventParameters: [String: Any], paramPath: [String]) -> Bool {
    let length = param.count - Delimeter.asterisk.count
    let paramSubstring = String(param[param.startIndex ..< param.index(param.startIndex, offsetBy: length)])
    let items = eventParameters[paramSubstring] as? [Any] ?? []
    if items.isEmpty || paramPath.count < 2 {
      return false
    }

    var isMatched = false
    let subParamPath = Array(paramPath.dropFirst())
    for item in items {
      isMatched = isMatchedEventParameters(eventParams: item as? [String: Any], paramPath: subParamPath)
      if isMatched {
        break
      }
    }
    return isMatched
  }

  // swiftlint:disable:next cyclomatic_complexity
  func isMatched(withStringValue stringValue: String?, numericalValue: Double?) -> Bool {
    var isMatched = false
    switch `operator` {
    case .contains:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition,
         stringValue.lowercased().contains(linguisticCondition.lowercased()) {
        isMatched = true
      }

    case .notContains:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition {
        isMatched = !stringValue.lowercased().contains(linguisticCondition.lowercased())
      }

    case .startsWith:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition {
        isMatched = stringValue.lowercased().hasPrefix(linguisticCondition.lowercased())
      }

    case .caseInsensitiveContains:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition,
         stringValue.lowercased().contains(linguisticCondition.lowercased()) {
        isMatched = true
      }

    case .caseInsensitiveNotContains:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition {
        isMatched = !stringValue.lowercased().contains(linguisticCondition.lowercased())
      }

    case .caseInsensitiveStartsWith:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition,
         stringValue.lowercased().hasPrefix(linguisticCondition.lowercased()) {
        isMatched = true
      }

    case .regexMatch:
      if let stringValue = stringValue {
        isMatched = isRegexMatch(stringValue)
      }

    case .equal:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition,
         stringValue.lowercased() == linguisticCondition.lowercased() {
        isMatched = true
      }

    case .notEqual:
      if let stringValue = stringValue,
         let linguisticCondition = linguisticCondition {
        isMatched = stringValue.lowercased() != linguisticCondition.lowercased()
      }

    case .caseInsensitiveIsAny:
      if let stringValue = stringValue {
        isMatched = isAny(of: arrayCondition ?? [], stringValue: stringValue, ignoreCase: true)
      }

    case .caseInsensitiveIsNotAny:
      if let stringValue = stringValue {
        return !isAny(of: arrayCondition ?? [], stringValue: stringValue, ignoreCase: true)
      }

    case .isAny:
      if let stringValue = stringValue {
        return isAny(of: arrayCondition ?? [], stringValue: stringValue, ignoreCase: false)
      }

    case .isNotAny:
      if let stringValue = stringValue,
         !isAny(of: arrayCondition ?? [], stringValue: stringValue, ignoreCase: false) {
        isMatched = true
      }

    case .lessThan:
      if let numericalValue = numericalValue,
         let numericalCondition = numericalCondition {
        isMatched = numericalValue < numericalCondition
      }

    case .lessThanOrEqual:
      if let numericalValue = numericalValue,
         let numericalCondition = numericalCondition,
         numericalValue <= numericalCondition {
        isMatched = true
      }

    case .greaterThan:
      if let numericalValue = numericalValue,
         let numericalCondition = numericalCondition,
         numericalValue > numericalCondition {
        isMatched = true
      }

    case .greaterThanOrEqual:
      if let numericalValue = numericalValue,
         let condition = numericalCondition,
         numericalValue >= condition {
        isMatched = true
      }
    default:
      break
    }
    return isMatched
  }

  func isRegexMatch(_ stringValue: String) -> Bool {
    guard let linguisticCondition = linguisticCondition, !linguisticCondition.isEmpty else {
      return false
    }
    do {
      let regex = try NSRegularExpression(pattern: linguisticCondition, options: .allowCommentsAndWhitespace)
      let range = NSRange(location: 0, length: stringValue.count)
      let matches = regex.matches(in: stringValue, options: .anchored, range: range)
      return !matches.isEmpty
    } catch {
      return false
    }
  }

  func isAny(of arrayCondition: [String], stringValue: String, ignoreCase: Bool) -> Bool {
    var set = Set<String>()
    for item in arrayCondition {
      if ignoreCase {
        set.insert(item.lowercased())
      } else {
        set.insert(item)
      }
    }
    return set.contains(ignoreCase ? stringValue.lowercased() : stringValue)
  }

  // MARK: - NSCoding

  public static var supportsSecureCoding: Bool = true

  public init?(coder: NSCoder) {
    let operatorValue = coder.decodeInteger(forKey: Keys.operator)
    guard let `operator` = _AEMAdvertiserRuleOperator(rawValue: operatorValue),
          let paramKey = coder.decodeObject(of: NSString.self, forKey: Keys.param),
          let linguisticCondition = coder.decodeObject(of: NSString.self, forKey: Keys.stringValue),
          let numericalCondition = coder.decodeObject(of: NSNumber.self, forKey: Keys.numberValue) else {
      return nil
    }
    let arrayCondition = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: Keys.arrayValue) as? [String]

    self.operator = `operator`
    self.paramKey = paramKey as String
    self.linguisticCondition = linguisticCondition as String
    self.numericalCondition = numericalCondition.doubleValue
    self.arrayCondition = arrayCondition
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(`operator`.rawValue, forKey: Keys.operator)
    coder.encode(paramKey, forKey: Keys.param)
    coder.encode(linguisticCondition, forKey: Keys.stringValue)
    coder.encode(numericalCondition, forKey: Keys.numberValue)
    coder.encode(arrayCondition, forKey: Keys.arrayValue)
  }

  // MARK: - NSCopying

  public func copy(with zone: NSZone? = nil) -> Any {
    self
  }

  public override func isEqual(_ object: Any?) -> Bool {
    if let rule = object as? _AEMAdvertiserSingleEntryRule {
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
        || (numericalCondition == rule.numericalCondition) == true)
      return isOpEqual && isParamKeyEqual && isLinguisticConditionEqual
        && isArrayConditionEqual && isNumericConditionEqual
    }
    return false
  }
}

#endif
