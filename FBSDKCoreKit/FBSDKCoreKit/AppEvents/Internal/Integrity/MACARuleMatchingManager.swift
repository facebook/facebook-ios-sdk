/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKMACARuleMatchingManager)
final class MACARuleMatchingManager: NSObject, MACARuleMatching {
  private var isEnable = false
  private var macaRules = [String]()

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    guard !isEnable,
          let dependencies = try? getDependencies() else {
      return
    }

    if let macaRulesFromServer = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?["maca_rules"] as? [String] {
      macaRules = macaRulesFromServer
      isEnable = true
    }
  }

  func getKey(logic: [String: Any]) -> String? {
    logic.keys.first
  }

  // swiftlint:disable:next cyclomatic_complexity
  func stringComparison(
    variable: String,
    values: [String: String],
    data: [String: Any]
  ) -> Bool {
    // swiftlint:disable:next identifier_name
    guard let op = getKey(logic: values),
          let ruleValue = values[op],
          let dataValue = data[variable.lowercased()] ?? data[variable]
    else { return false }

    switch op {
    case "contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return dataValue.contains(ruleValue)
    case "i_contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return dataValue.lowercased().contains(ruleValue.lowercased())
    case "i_not_contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return !dataValue.lowercased().contains(ruleValue.lowercased())
    case "regex_match":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return dataValue.range(of: ruleValue, options: .regularExpression, range: nil, locale: nil) != nil
    case "eq":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return dataValue == ruleValue
    case "neq":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue) else { return false }
      return dataValue != ruleValue
    case "lt":
      return doubleValueOf(dataValue) < doubleValueOf(ruleValue)
    case "lte":
      return doubleValueOf(dataValue) <= doubleValueOf(ruleValue)
    case "gt":
      return doubleValueOf(dataValue) > doubleValueOf(ruleValue)
    case "gte":
      return doubleValueOf(dataValue) >= doubleValueOf(ruleValue)
    default:
      return false
    }
  }

  func stringValueOf(_ value: Any?) -> String? {
    if let str = value as? String {
      return str
    } else if let num = value as? NSNumber {
      return num.stringValue
    }
    return nil
  }

  func doubleValueOf(_ value: Any?) -> Double {
    if let num = value as? NSNumber {
      return num.doubleValue
    } else if let str = value as? String,
              let doubleValue = Double(str) {
      return doubleValue
    }
    return 0
  }

  func isMatchCCRule(
    _ rule: String?,
    data: [String: Any]
  ) -> Bool {
    guard let ruleData = rule?.data(using: String.Encoding.utf8),
          let ruleJson = try? JSONSerialization.jsonObject(
            with: ruleData, options: .mutableContainers
          ) as? [String: Any],
          let thisOp = getKey(logic: ruleJson),
          let values = ruleJson[thisOp]
    else { return false }

    if thisOp == "and" {
      guard let values = values as? [Any] else { return false }

      for ent in values {
        let ruleString = try? BasicUtility.jsonString(for: ent)
        let thisRes = isMatchCCRule(ruleString, data: data)
        if !thisRes {
          return false
        }
      }
      return true
    } else if thisOp == "or" {
      guard let values = values as? [Any] else { return false }

      for ent in values {
        let ruleString = try? BasicUtility.jsonString(for: ent)
        let thisRes = isMatchCCRule(ruleString, data: data)
        if thisRes {
          return true
        }
      }
      return false
    } else if thisOp == "not" {
      let ruleString = try? BasicUtility.jsonString(for: values)
      return !isMatchCCRule(ruleString, data: data)
    } else {
      guard let values = values as? [String: String] else { return false }

      return stringComparison(variable: thisOp, values: values, data: data)
    }
  }

  func getMatchPropertyIDs(params: [String: Any]) -> String {
    guard !macaRules.isEmpty else { return "[]" }

    let res = NSMutableArray()
    for entry in macaRules {
      guard let json = try? BasicUtility.object(forJSONString: entry) as? [String: Any],
            let pid = json["id"] as? Int64,
            let rule = json["rule"] as? String
      else { continue }
      if isMatchCCRule(rule, data: params) {
        res.add(pid)
      }
    }
    let resString = try? BasicUtility.jsonString(for: res)
    return resString ?? "[]"
  }

  @objc func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? {
    guard isEnable, let params = params, var res = params.mutableCopy() as? [String: Any]
    else { return params }

    if isEnable {
      res["event"] = event ?? ""
      res["cs_maca"] = true
      res["_audiencePropertyIds"] = getMatchPropertyIDs(params: res)
      res.removeValue(forKey: "event")
    }

    return res as NSDictionary
  }
}

extension MACARuleMatchingManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
