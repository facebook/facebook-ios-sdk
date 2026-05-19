/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// VPPA Video Viewing Protections — iOS SDK side. Mirrors the JS pixel plugin
/// (`SignalsFBEvents.plugins.vvp.js`) and the Android `VVPManager`.
///
/// Consumes the JSON-encoded `vvp_config` string delivered by
/// `GraphApplicationProtectedModeRulesNode` as a sub-key of
/// `_ServerConfiguration.protectedModeRules` (same plumbing pattern used by
/// `BannedParamsManager`, `StdParamEnforcementManager`, and the other
/// Integrity managers) and exposes a typed in-memory model used by the
/// per-event hook.
///
/// This file owns parsing + lifecycle. The per-event detection runtime,
/// customData filter, content-id sanitization, and `vvp` / `vvp_md` payload
/// tagging land in D2.
final class VVPConfigManager: NSObject, MACARuleMatching {

  // MARK: - Wire-shape constants

  /// Mirror of `SignalsIntegrityCheckPlace` int values — only these two reach the SDK today.
  static let placeCustomData = 1
  static let placeEventName = 3

  // Wire field names — match the server-side `TVVPAppConfig` / `TVVPAppRule` shape.
  private static let enabledKey = "enabled"
  private static let rulesKey = "rules"
  private static let standardParamsKey = "standardParams"
  private static let inScopeEventNamesKey = "inScopeEventNames"
  private static let placeKey = "place"
  private static let keyRegexKey = "keyRegex"
  private static let valueRegexKey = "valueRegex"
  private static let keyNegativeRegexKey = "keyNegativeRegex"

  /// Sub-key inside `_ServerConfiguration.protectedModeRules` carrying the
  /// JSON-encoded VVP config string. Mirror of the JS pixel plugin and the
  /// server-side `GraphApplicationProtectedModeRulesNode::VVP_CONFIG`.
  private static let vvpConfigKey = "vvp_config"

  // MARK: - Lifecycle state

  private var isEnabled = false
  private(set) var config: VVPConfig?

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  // MARK: - MACARuleMatching

  func enable() {
    if isEnabled {
      return
    }
    guard let dependencies = try? getDependencies() else {
      return
    }
    loadConfig(dependencies: dependencies)
    if config != nil {
      isEnabled = true
    }
  }

  /// Per-event hook stub. Returns input unchanged in D2 (skeleton); D3 fills in
  /// the detection + enforcement runtime that mutates `params` to filter
  /// customData, sanitize content IDs, and tag `vvp` / `vvp_md`.
  func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? {
    params
  }

  // MARK: - Config loading

  private func loadConfig(dependencies: ObjectDependencies) {
    // VVP config is delivered as a JSON-encoded string under
    // `protected_mode_rules.vvp_config` — same plumbing as the other
    // Integrity sub-fields (`standard_params_blocked`,
    // `standard_params_schema`, `maca_rules`, etc.). See sibling pattern in
    // `BannedParamsManager.configureBlockedParams(dependencies:)`.
    guard let raw = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?[VVPConfigManager.vvpConfigKey] as? String,
      !raw.isEmpty
    else {
      // Missing / empty string is the server's "not in VVP scope" signal.
      config = nil
      return
    }
    config = VVPConfigManager.parseConfig(jsonString: raw)
  }

  // MARK: - Parser (testable static API)

  /// Parse the JSON-encoded `vvp_config` payload. Returns `nil` on any
  /// structural failure — empty rules, `enabled=false`, malformed JSON.
  static func parseConfig(jsonString: String) -> VVPConfig? {
    guard
      let data = jsonString.data(using: .utf8),
      let root = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    else { return nil }

    let enabled = (root[enabledKey] as? Bool) ?? false
    if !enabled { return nil }

    let rules = parseRules(root)
    if rules.isEmpty { return nil }

    return VVPConfig(
      rules: rules,
      standardParams: parseStandardParams(root),
      inScopeEventNames: parseInScopeEventNames(root)
    )
  }

  static func compileRule(_ ruleObj: [String: Any]) -> VVPRule? {
    let place = (ruleObj[placeKey] as? Int) ?? -1
    if place != placeCustomData, place != placeEventName {
      // Unknown place -> drop silently (mirrors the JS plugin).
      return nil
    }
    let keyRegex = optRegex(ruleObj, keyRegexKey)
    let valueRegex = optRegex(ruleObj, valueRegexKey)
    // `keyNegativeRegex` is a key-side suppression filter — the rule only
    // fires when the key matches `keyRegex` AND does NOT match
    // `keyNegativeRegex`. Lets the server suppress false positives like
    // `utm_*` whose names satisfy the positive regex. Malformed / missing /
    // empty -> nil (no suppression). Mirrors the PHP wire field added in
    // SignalsIntegrityVVPUtils::TClientRule.
    let keyNegativeRegex = optRegex(ruleObj, keyNegativeRegexKey)
    if keyRegex == nil, valueRegex == nil {
      // Rule with no constraint would match every event -> drop.
      return nil
    }
    return VVPRule(
      place: place,
      keyRegex: keyRegex,
      valueRegex: valueRegex,
      keyNegativeRegex: keyNegativeRegex
    )
  }

  private static func parseRules(_ root: [String: Any]) -> [VVPRule] {
    guard let arr = root[rulesKey] as? [Any] else { return [] }
    return arr.compactMap { entry -> VVPRule? in
      guard let dict = entry as? [String: Any] else { return nil }
      return compileRule(dict)
    }
  }

  private static func optRegex(_ obj: [String: Any], _ key: String) -> NSRegularExpression? {
    guard let raw = obj[key] as? String, !raw.isEmpty else {
      // Missing, JSON null (decoded as NSNull), or empty string -> no constraint.
      return nil
    }
    // Case-insensitive to mirror the JS plugin's `'i'` flag.
    return try? NSRegularExpression(pattern: raw, options: [.caseInsensitive])
  }

  private static func parseStandardParams(_ root: [String: Any]) -> Set<String> {
    guard let dict = root[standardParamsKey] as? [String: Any] else { return [] }
    var out = Set<String>()
    // Server emits {key: true} for every entry; preserve the contract by only
    // including keys whose value is truthy.
    for (k, v) in dict {
      if let b = v as? Bool, b {
        out.insert(k)
      } else if let n = v as? NSNumber, n.boolValue {
        out.insert(k)
      }
    }
    return out
  }

  private static func parseInScopeEventNames(_ root: [String: Any]) -> Set<String>? {
    // Missing or JSON null -> no event-name gate (NON_RETAIL).
    guard let raw = root[inScopeEventNamesKey], !(raw is NSNull) else { return nil }
    guard let arr = raw as? [Any] else { return nil }
    var out = Set<String>()
    for entry in arr {
      if let s = entry as? String, !s.isEmpty {
        out.insert(s)
      }
    }
    return out
  }
}

// MARK: - Typed model

/// One detection rule, with regexes pre-compiled at parse time. Either regex
/// can be `nil` (meaning "no constraint on that side"); a rule with both `nil`
/// is dropped during parse.
struct VVPRule: Equatable {
  let place: Int
  let keyRegex: NSRegularExpression?
  let valueRegex: NSRegularExpression?
  /// Optional key-side suppression filter. When set, a customData / event-name
  /// key matches the rule only if it satisfies `keyRegex` AND does NOT match
  /// `keyNegativeRegex`. `nil` = no suppression.
  let keyNegativeRegex: NSRegularExpression?

  static func == (lhs: VVPRule, rhs: VVPRule) -> Bool {
    lhs.place == rhs.place
      && lhs.keyRegex?.pattern == rhs.keyRegex?.pattern
      && lhs.valueRegex?.pattern == rhs.valueRegex?.pattern
      && lhs.keyNegativeRegex?.pattern == rhs.keyNegativeRegex?.pattern
  }
}

struct VVPConfig: Equatable {
  let rules: [VVPRule]
  let standardParams: Set<String>
  /// `nil` = no event-name gate (NON_RETAIL); non-nil restricts detection to
  /// this set (RETAIL purchase-funnel allowlist).
  let inScopeEventNames: Set<String>?
}

extension VVPConfigManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}

// MARK: - Testing

#if DEBUG
extension VVPConfigManager {
  func getIsEnabled() -> Bool {
    isEnabled
  }

  func reset() {
    isEnabled = false
    config = nil
  }
}
#endif
