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

  private let keys = [
    "event",
    "_locale",
    "_appVersion",
    "_deviceOS",
    "_platform",
    "_deviceModel",
    "_nativeAppID",
    "_nativeAppShortVersion",
    "_timezone",
    "_carrier",
    "_deviceOSTypeName",
    "_deviceOSVersion",
    "_remainingDiskGB",
  ]

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared,
    deviceInformationProvider: _AppEventsDeviceInfo.shared,
    settings: Settings.shared
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
    values: [String: Any],
    data: [String: Any]
  ) -> Bool {
    // swiftlint:disable:next identifier_name
    guard let op = getKey(logic: values),
          let ruleValue = values[op]
    else { return false }

    if op == "exists" {
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let ruleBoolValue = ruleValue as? Bool else { return false }
      return data.keys.contains(variable) == ruleBoolValue
    }

    guard let dataValue = data[variable.lowercased()] ?? data[variable]
    else { return false }

    let ruleStringValue = ruleValue as? String
    let ruleArrayValue = ruleValue as? [String]

    switch op {
    case "contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.contains(ruleStringValue)
    case "i_contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.lowercased().contains(ruleStringValue.lowercased())
    case "not_contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return !dataValue.contains(ruleStringValue)
    case "i_not_contains":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return !dataValue.lowercased().contains(ruleStringValue.lowercased())
    case "starts_with":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.starts(with: ruleStringValue)
    case "i_starts_with":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.lowercased().starts(with: ruleStringValue.lowercased())
    case "i_str_eq":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.lowercased() == ruleStringValue.lowercased()
    case "i_str_neq":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.lowercased() != ruleStringValue.lowercased()
    case "in", "is_any":
      guard let dataValue = stringValueOf(dataValue),
            let ruleArrayValue = ruleArrayValue
      else { return false }
      return ruleArrayValue.contains(dataValue)
    case "i_str_in", "i_is_any":
      guard let dataValue = stringValueOf(dataValue),
            let ruleArrayValue = ruleArrayValue
      else { return false }
      return ruleArrayValue.contains(where: { $0.compare(dataValue, options: .caseInsensitive) == .orderedSame })
    case "not_in", "is_not_any":
      guard let dataValue = stringValueOf(dataValue),
            let ruleArrayValue = ruleArrayValue
      else { return false }
      return !ruleArrayValue.contains(dataValue)
    case "i_str_not_in", "i_is_not_any":
      guard let dataValue = stringValueOf(dataValue),
            let ruleArrayValue = ruleArrayValue
      else { return false }
      return !ruleArrayValue.contains(where: { $0.compare(dataValue, options: .caseInsensitive) == .orderedSame })
    case "regex_match":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue.range(of: ruleStringValue, options: .regularExpression, range: nil, locale: nil) != nil
    case "eq", "=", "==":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue == ruleStringValue
    case "neq", "ne", "!=":
      // swiftlint:disable:next blank_line_after_single_line_guard
      guard let dataValue = stringValueOf(dataValue),
            let ruleStringValue = ruleStringValue
      else { return false }
      return dataValue != ruleStringValue
    case "lt", "<":
      return doubleValueOf(dataValue) < doubleValueOf(ruleValue)
    case "lte", "le", "<=":
      return doubleValueOf(dataValue) <= doubleValueOf(ruleValue)
    case "gt", ">":
      return doubleValueOf(dataValue) > doubleValueOf(ruleValue)
    case "gte", "ge", ">=":
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
      guard let values = values as? [String: Any] else { return false }

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
      generateInfo(params: &res, event: event)
      res["cs_maca"] = true
      res["_audiencePropertyIds"] = getMatchPropertyIDs(params: res)
      removeGeneratedInfo(params: &res)
    }

    return res as NSDictionary
  }

  func generateInfo(params: inout [String: Any], event: String?) {
    guard let dependencies = try? getDependencies() else {
      return
    }
    params["event"] = event ?? ""
    params["_locale"] = dependencies.deviceInformationProvider.language ?? ""
    params["_appVersion"] = dependencies.deviceInformationProvider.shortVersion ?? ""
    params["_deviceOS"] = "IOS"
    params["_platform"] = "mobile"
    params["_deviceModel"] = dependencies.deviceInformationProvider.machine ?? ""
    params["_nativeAppID"] = dependencies.settings.appID ?? ""
    params["_nativeAppShortVersion"] = dependencies.deviceInformationProvider.shortVersion ?? ""
    params["_timezone"] = dependencies.deviceInformationProvider.timeZoneName ?? ""
    params["_carrier"] = dependencies.deviceInformationProvider.carrierName ?? ""
    params["_deviceOSTypeName"] = "IOS"
    params["_deviceOSVersion"] = dependencies.deviceInformationProvider.sysVersion ?? ""
    params["_remainingDiskGB"] = dependencies.deviceInformationProvider.remainingDiskSpaceGB
  }

  func removeGeneratedInfo(params: inout [String: Any]) {
    for key in keys {
      params.removeValue(forKey: key)
    }
  }
}

extension MACARuleMatchingManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
    var deviceInformationProvider: _DeviceInformationProviding
    var settings: SettingsProtocol
  }
}
