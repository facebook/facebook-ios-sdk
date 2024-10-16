/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class StdParamEnforcementManager: NSObject, MACARuleMatching {
  private var isEnabled = false
  private var regexRestrictionsConfig = [String: Set<String>]()
  private var enumRestrictionsConfig = [String: Set<String>]()
  private static let stdParamsSchemaKey = "standard_params_schema"
  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    if isEnabled {
      return
    }
    guard let dependencies = try? getDependencies() else {
      return
    }
    configureSchemaRestrictions(dependencies: dependencies)

    if !regexRestrictionsConfig.isEmpty || !enumRestrictionsConfig.isEmpty {
      isEnabled = true
    }
  }

  func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? {
    if !isEnabled {
      return params
    }
    guard let params = params else { return params }

    var updatedParams = params.mutableCopy() as? NSMutableDictionary
    for (key, value) in params {
      let strKey = String(describing: key)
      let strValue = String(describing: value)
      let regexKeyExists = regexRestrictionsConfig[strKey] != nil
      let enumKeyExists = enumRestrictionsConfig[strKey] != nil
      // If no schema restriction exist, do not filter
      if !regexKeyExists, !enumKeyExists {
        continue
      }
      let regexMatches = isAnyRegexMatched(value: strValue, expressions: regexRestrictionsConfig[strKey])
      let enumMatches = isAnyEnumMatched(value: strValue, enumValues: enumRestrictionsConfig[strKey])
      if !regexMatches, !enumMatches {
        // filter if no rule matches
        updatedParams?.removeObject(forKey: key)
      }
    }
    return updatedParams
  }

  private func isAnyRegexMatched(value: String, expressions: Set<String>?) -> Bool {
    if let expressions = expressions, !expressions.isEmpty {
      for expression in expressions {
        if value.range(of: expression, options: .regularExpression) != nil {
          return true
        }
      }
    }
    return false
  }

  private func isAnyEnumMatched(value: String, enumValues: Set<String>?) -> Bool {
    guard let enumValues = enumValues else { return false }

    for enumValue in enumValues {
      if value.lowercased() == enumValue.lowercased() {
        return true
      }
    }

    return false
  }

  private func configureSchemaRestrictions(dependencies: ObjectDependencies) {
    guard let schemaRestrictions = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[StdParamEnforcementManager.stdParamsSchemaKey]
      as? [[String: Any]]
    else {
      return
    }

    for schemaRestriction in schemaRestrictions {
      if let key = schemaRestriction["key"] as? String,
         let value = schemaRestriction["value"] as? [[String: Any]] {
        for restriction in value {
          if let requireExactMatch = restriction["require_exact_match"] as? Bool,
             let potentialMatches = restriction["potential_matches"] as? [String] {
            if requireExactMatch {
              // Handle exact match enum restrictions
              let enumParamSet = Set(potentialMatches)
              if !enumRestrictionsConfig.keys.contains(key) {
                enumRestrictionsConfig[key] = enumParamSet
              } else {
                enumRestrictionsConfig[key] = enumRestrictionsConfig[key]?.union(enumParamSet)
              }
            } else {
              // Handle regex restrictions
              let regexParamSet = Set(potentialMatches)
              if !regexRestrictionsConfig.keys.contains(key) {
                regexRestrictionsConfig[key] = regexParamSet
              } else {
                regexRestrictionsConfig[key] = regexRestrictionsConfig[key]?.union(regexParamSet)
              }
            }
          }
        }
      }
    }
  }
}

extension StdParamEnforcementManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}

// MARK: - Testing

#if DEBUG
extension StdParamEnforcementManager {
  func getIsEnabled() -> Bool {
    isEnabled
  }

  func getRegexRestrictionsConfig() -> [String: Set<String>] {
    regexRestrictionsConfig
  }

  func getEnumRestrictionsConfig() -> [String: Set<String>] {
    enumRestrictionsConfig
  }
}
#endif
