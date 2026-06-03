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
/// This file owns parsing + lifecycle + the per-event detection /
/// enforcement runtime: filters customData against `standardParams`,
/// sanitizes `fb_content_id(s)` values to `"_removed_"`, and tags the
/// outgoing dict with `vvp = "1"` plus a JSON-encoded `vvp_md` payload.
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
  // Outgoing payload keys appended to the event params dict when VVP enforces.
  // Mirror of the JS plugin's `vvp` / `vvp_md` and the server-side
  // `AdsPixelRequestParams::VVP_CLIENT_SIDE_ENFORCED / VVP_CLIENT_SIDE_METADATA`.
  static let vvpKey = "vvp"
  static let vvpMetadataKey = "vvp_md"
  private static let vvpAppliedValue = "1"

  // Sub-buckets inside the JSON-encoded vvp_md payload — mirror PHP
  // `SIEventContextParams::RESTRICTED_PARAMS` ("rp") prefixed with "vp_".
  private static let vpRpKey = "vp_rp"
  private static let vpRpEvKey = "vp_rp_ev"

  // Sentinel pushed to vp_rp_ev when an event-name rule fires; we never
  // echo the actual event name back (it can itself be sensitive).
  private static let eventNameSentinel = "1"

  // CustomData keys whose values are sanitized (replaced with sanitizedValue)
  // instead of being deleted outright when VVP enforces. Mirror of PHP
  // `SignalsIntegrityVVPUtils::APP_CONTENT_ID_KEYS`.
  private static let contentIdSanitizeKeys: Set<String> = ["fb_content_ids", "fb_content_id"]
  private static let sanitizedValue = "_removed_"

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

  /// Per-event hook. Runs detection over the rules and, on a positive match,
  /// filters customData against `standardParams` (with `fb_content_id(s)`
  /// sanitized to `"_removed_"` rather than dropped), then tags the payload
  /// with `vvp = "1"` plus a JSON-encoded `vvp_md` describing which keys /
  /// event-name triggered the match. Returns the mutated dict.
  ///
  /// Mirrors the JS pixel plugin lines 215-240 and the Android
  /// `VVPManager.processParametersForVVP`. Returns `params` unchanged when
  /// disabled, no event name, no config, out-of-scope, or no rule matches.
  func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? {
    // swiftformat:disable:next isEmpty
    guard isEnabled, let cfg = config, let event = event, let params = params, params.count > 0 else { // swiftlint:disable:this empty_count
      return params
    }

    // inScopeEventNames gate (RETAIL apps only — NON_RETAIL leaves this nil).
    if let inScope = cfg.inScopeEventNames, !inScope.contains(event) {
      return params
    }

    let result = detectMatches(eventName: event, customData: params, rules: cfg.rules)
    if !result.matched {
      return params
    }

    let mutated = NSMutableDictionary(dictionary: params)

    // Sanitize / filter customData. Skipped when standardParams is empty —
    // otherwise we'd drop everything (no allowlist means "keep nothing",
    // which is not the intended fallback).
    if !cfg.standardParams.isEmpty {
      // Snapshot keys first since we mutate in the loop.
      for key in params.allKeys {
        guard let strKey = key as? String else { continue }
        if VVPConfigManager.contentIdSanitizeKeys.contains(strKey) {
          mutated[strKey] = VVPConfigManager.sanitizedValue
          continue
        }
        if cfg.standardParams.contains(strKey) {
          continue
        }
        mutated.removeObject(forKey: key)
      }
    }

    mutated[VVPConfigManager.vvpKey] = VVPConfigManager.vvpAppliedValue

    // Emit vvp_md only when there's something to report. JSON shape mirrors
    // the JS plugin: { vp_rp: [...customData keys], vp_rp_ev: ["1"] }.
    // Empty buckets are omitted; the entire field is omitted if both empty.
    if !result.cdKeys.isEmpty || !result.evNames.isEmpty {
      var md: [String: [String]] = [:]
      if !result.cdKeys.isEmpty {
        // Sorted for deterministic test/wire ordering.
        md[VVPConfigManager.vpRpKey] = result.cdKeys.sorted()
      }
      if !result.evNames.isEmpty {
        md[VVPConfigManager.vpRpEvKey] = result.evNames.sorted()
      }
      if let mdData = try? JSONSerialization.data(withJSONObject: md, options: [.sortedKeys]),
         let mdString = String(data: mdData, encoding: .utf8) {
        mutated[VVPConfigManager.vvpMetadataKey] = mdString
      }
    }

    return mutated
  }

  // MARK: - Detection

  /// Result of running the rules over a single event. `matched` is true if any
  /// rule fired; `cdKeys` is the set of customData keys that matched (sanitized
  /// or dropped during enforcement below); `evNames` is the sentinel `["1"]` set if any
  /// PLACE_EVENT_NAME rule fired (sentinel — never echo the actual event name).
  struct DetectionResult: Equatable {
    let matched: Bool
    let cdKeys: Set<String>
    let evNames: Set<String>
  }

  func detectMatches(
    eventName: String,
    customData: NSDictionary?,
    rules: [VVPRule]
  ) -> DetectionResult {
    var matched = false
    var cdKeys = Set<String>()
    var evNames = Set<String>()

    for rule in rules {
      switch rule.place {
      case VVPConfigManager.placeEventName:
        guard let kr = rule.keyRegex, regexMatches(kr, eventName) else { continue }
        // keyNegativeRegex suppression — `utm_*`-style false positives.
        if let kneg = rule.keyNegativeRegex, regexMatches(kneg, eventName) {
          continue
        }
        matched = true
        // Sentinel — never echo the actual event name to the wire.
        evNames.insert(VVPConfigManager.eventNameSentinel)
      case VVPConfigManager.placeCustomData:
        guard let customData = customData else { continue }
        for (k, v) in customData {
          guard let key = k as? String else { continue }
          let keyOk = rule.keyRegex.map { regexMatches($0, key) } ?? true
          let valOk = rule.valueRegex.map { regexMatches($0, String(describing: v)) } ?? true
          if !keyOk || !valOk {
            continue
          }
          // keyNegativeRegex suppression applies only on the key side. Lets
          // the server allowlist e.g. `utm_content_id` despite matching the
          // positive `content` keyRegex.
          if let kneg = rule.keyNegativeRegex, regexMatches(kneg, key) {
            continue
          }
          matched = true
          cdKeys.insert(key)
        }
      default:
        // Unknown places are filtered out at parse time but defend here too.
        continue
      }
    }
    return DetectionResult(matched: matched, cdKeys: cdKeys, evNames: evNames)
  }

  private func regexMatches(_ regex: NSRegularExpression, _ s: String) -> Bool {
    let range = NSRange(s.startIndex ..< s.endIndex, in: s)
    return regex.firstMatch(in: s, options: [], range: range) != nil
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
