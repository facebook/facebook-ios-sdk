/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import XCTest

final class VVPConfigManagerTests: XCTestCase {

  // MARK: - Fixtures

  private static let validNonRetailConfig = """
    {
      "enabled": true,
      "isShadowEnabled": false,
      "rules": [{"place": 1, "keyRegex": "", "valueRegex": "\\\\btt\\\\d{7,}\\\\b"}],
      "standardParams": {"fb_currency": true, "fb_value": true},
      "inScopeEventNames": null
    }
    """

  private static let validRetailConfig = """
    {
      "enabled": true,
      "isShadowEnabled": false,
      "rules": [{"place": 1, "keyRegex": "content_id", "valueRegex": "tt\\\\d+"}],
      "standardParams": {"fb_currency": true},
      "inScopeEventNames": ["Purchase", "AddToCart"]
    }
    """

  private static let shadowDefaultNonRetailConfig = """
    {
      "enabled": true,
      "rules": [{"place": 1, "keyRegex": "", "valueRegex": "\\\\btt\\\\d{7,}\\\\b"}],
      "standardParams": {"fb_currency": true, "fb_value": true},
      "inScopeEventNames": null
    }
    """

  // swiftlint:disable implicitly_unwrapped_optional
  var manager: VVPConfigManager!
  var provider: TestServerConfigurationProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    manager = VVPConfigManager()
  }

  override func tearDown() {
    super.tearDown()
    manager = nil
    provider = nil
  }

  private func install(vvpConfig: String?) {
    // Mirrors how sibling Integrity-manager tests configure server state:
    // VVP config lives under `protectedModeRules["vvp_config"]` (not a
    // top-level field on `_ServerConfiguration`).
    let serverConfig = ServerConfigurationFixtures.configuration(
      withDictionary: vvpConfig.map { ["protectedModeRules": ["vvp_config": $0]] } ?? [:]
    )
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    manager.configuredDependencies = .init(serverConfigurationProvider: provider)
  }

  // MARK: - Lifecycle

  func testDisabledByDefault() {
    XCTAssertFalse(manager.getIsEnabled())
    XCTAssertNil(manager.config)
  }

  func testEnableWithNoVvpConfigStaysDisabled() {
    install(vvpConfig: nil)
    manager.enable()
    XCTAssertFalse(manager.getIsEnabled())
    XCTAssertNil(manager.config)
  }

  func testEnableWithEmptyVvpConfigStaysDisabled() {
    install(vvpConfig: "")
    manager.enable()
    XCTAssertFalse(manager.getIsEnabled())
    XCTAssertNil(manager.config)
  }

  func testEnableWithValidConfigFlipsState() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    XCTAssertTrue(manager.getIsEnabled())
    XCTAssertNotNil(manager.config)
    XCTAssertEqual(manager.config?.rules.count, 1)
  }

  func testEnableIsIdempotent() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    XCTAssertNil(manager.config?.inScopeEventNames) // NON_RETAIL trait
    // A second enable() must not re-load — invariant relied on by AppEvents lifecycle.
    install(vvpConfig: Self.validRetailConfig)
    manager.enable()
    // Still NON_RETAIL — second enable() was a no-op.
    XCTAssertNil(manager.config?.inScopeEventNames)
  }

  // MARK: - parseConfig — top-level shape

  func testParseConfigValidNonRetail() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.validNonRetailConfig)
    XCTAssertNotNil(cfg)
    XCTAssertEqual(cfg?.rules.count, 1)
    XCTAssertEqual(cfg?.standardParams, ["fb_currency", "fb_value"])
    XCTAssertNil(cfg?.inScopeEventNames)
  }

  func testParseConfigValidRetailHasInScopeEventNames() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.validRetailConfig)
    XCTAssertEqual(cfg?.inScopeEventNames, ["Purchase", "AddToCart"])
  }

  func testParseConfigReturnsNilWhenEnabledFalse() {
    let json = """
      {"enabled": false, "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true}}
      """
    XCTAssertNil(VVPConfigManager.parseConfig(jsonString: json))
  }

  func testParseConfigReturnsNilWhenRulesEmpty() {
    let json = """
      {"enabled": true, "rules": [], "standardParams": {"fb_currency": true}}
      """
    XCTAssertNil(VVPConfigManager.parseConfig(jsonString: json))
  }

  func testParseConfigReturnsNilOnMalformedJson() {
    XCTAssertNil(VVPConfigManager.parseConfig(jsonString: "not valid json"))
  }

  func testParseConfigReturnsNilOnEmptyString() {
    XCTAssertNil(VVPConfigManager.parseConfig(jsonString: ""))
  }

  // MARK: - compileRule — rule-level edge cases

  func testCompileRuleDropsUnknownPlace() {
    let rule: [String: Any] = ["place": 99, "keyRegex": "video", "valueRegex": ""]
    XCTAssertNil(VVPConfigManager.compileRule(rule))
  }

  func testCompileRuleDropsBothRegexesEmpty() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "",
      "valueRegex": "",
    ]
    XCTAssertNil(VVPConfigManager.compileRule(rule))
  }

  func testCompileRuleDropsMalformedRegex() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "[invalid",
      "valueRegex": "",
    ]
    XCTAssertNil(VVPConfigManager.compileRule(rule))
  }

  func testCompileRuleTreatsNullRegexLikeEmpty() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": NSNull(),
      "valueRegex": "tt\\d+",
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    XCTAssertNotNil(compiled)
    XCTAssertNil(compiled?.keyRegex)
    XCTAssertNotNil(compiled?.valueRegex)
  }

  func testEventNameRuleKeepsOnlyKeyRegex() {
    let json = """
      {"enabled": true, "rules": [{"place": 3, "keyRegex": "video_view", "valueRegex": ""}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertEqual(cfg?.rules.count, 1)
    XCTAssertEqual(cfg?.rules.first?.place, VVPConfigManager.placeEventName)
    XCTAssertNotNil(cfg?.rules.first?.keyRegex)
    XCTAssertNil(cfg?.rules.first?.valueRegex)
  }

  func testCompiledRegexIsCaseInsensitive() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.validNonRetailConfig)
    let regex = cfg?.rules.first?.valueRegex
    XCTAssertNotNil(regex)
    let upper = "TT1234567"
    let range = NSRange(upper.startIndex ..< upper.endIndex, in: upper)
    XCTAssertNotNil(regex?.firstMatch(in: upper, options: [], range: range))
  }

  // MARK: - keyNegativeRegex parsing

  func testCompileRulePassesThroughKeyNegativeRegex() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "(\\b|_)(video|content)(\\b|_)",
      "valueRegex": "",
      "keyNegativeRegex": "(\\b|_)(utm|url|refer)(\\b|_)",
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    XCTAssertNotNil(compiled)
    XCTAssertEqual(compiled?.keyNegativeRegex?.pattern, "(\\b|_)(utm|url|refer)(\\b|_)")
  }

  func testCompileRuleMissingKeyNegativeRegexIsNil() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "video",
      "valueRegex": "",
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    XCTAssertNotNil(compiled)
    XCTAssertNil(compiled?.keyNegativeRegex)
  }

  func testCompileRuleNullKeyNegativeRegexIsNil() {
    // Server emits JSON null when no suppression — must be treated as "no constraint".
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "video",
      "valueRegex": "",
      "keyNegativeRegex": NSNull(),
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    XCTAssertNotNil(compiled)
    XCTAssertNil(compiled?.keyNegativeRegex)
  }

  func testCompileRuleMalformedKeyNegativeRegexIsNil() {
    // Malformed pattern -> dropped silently like keyRegex / valueRegex.
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "video",
      "valueRegex": "",
      "keyNegativeRegex": "[invalid",
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    XCTAssertNotNil(compiled)
    XCTAssertNil(compiled?.keyNegativeRegex)
  }

  func testCompiledKeyNegativeRegexIsCaseInsensitive() {
    let rule: [String: Any] = [
      "place": VVPConfigManager.placeCustomData,
      "keyRegex": "video",
      "valueRegex": "",
      "keyNegativeRegex": "utm",
    ]
    let compiled = VVPConfigManager.compileRule(rule)
    let regex = compiled?.keyNegativeRegex
    XCTAssertNotNil(regex)
    let upper = "UTM_SOURCE"
    let range = NSRange(upper.startIndex ..< upper.endIndex, in: upper)
    XCTAssertNotNil(regex?.firstMatch(in: upper, options: [], range: range))
  }

  // MARK: - standardParams parsing

  func testParseConfigDropsFalsyStandardParams() {
    let json = """
      {"enabled": true, "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"keep": true, "drop": false}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertEqual(cfg?.standardParams, ["keep"])
  }

  func testParseConfigHandlesMissingStandardParams() {
    let json = """
      {"enabled": true, "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}]}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertEqual(cfg?.standardParams, [])
  }

  // MARK: - inScopeEventNames parsing

  func testParseConfigJsonNullInScopeEventNamesIsNoGate() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.validNonRetailConfig)
    XCTAssertNil(cfg?.inScopeEventNames)
  }

  func testParseConfigMissingInScopeEventNamesIsNoGate() {
    let json = """
      {"enabled": true, "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertNil(cfg?.inScopeEventNames)
  }

  // MARK: - isShadowEnabled parsing (fail-open default)

  func testParseConfigParsesExplicitIsShadowEnabledTrue() {
    let json = """
      {"enabled": true,
       "isShadowEnabled": true,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertNotNil(cfg)
    XCTAssertTrue(cfg!.isShadowEnabled)
  }

  func testParseConfigParsesExplicitIsShadowEnabledFalse() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.validNonRetailConfig)
    XCTAssertNotNil(cfg)
    XCTAssertFalse(cfg!.isShadowEnabled)
  }

  func testParseConfigDefaultsIsShadowEnabledToTrueWhenMissing() {
    let cfg = VVPConfigManager.parseConfig(jsonString: Self.shadowDefaultNonRetailConfig)
    XCTAssertNotNil(cfg)
    XCTAssertTrue(cfg!.isShadowEnabled)
  }

  func testParseConfigDefaultsIsShadowEnabledToTrueWhenNSNull() {
    let json = """
      {"enabled": true,
       "isShadowEnabled": null,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)
    XCTAssertNotNil(cfg)
    XCTAssertTrue(cfg!.isShadowEnabled)
  }

  // MARK: - Enforcement processParameters

  func testProcessParametersReturnsInputWhenDisabled() {
    let params: NSDictionary = ["foo": "bar"]
    let out = manager.processParameters(params, event: "Purchase")
    XCTAssertEqual(out, params)
    XCTAssertNil((out as? [String: Any])?["vvp"])
  }

  func testProcessParametersReturnsInputUnchangedWhenNoMatch() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    // Value doesn't match the IMDb-style regex → no detection → no mutation.
    let params: NSDictionary = ["fb_content_ids": "sku-42", "fb_currency": "USD"]
    let out = manager.processParameters(params, event: "Purchase")
    XCTAssertEqual(out, params)
  }

  func testProcessParametersOutOfScopeRetailEventNoOps() {
    install(vvpConfig: Self.validRetailConfig)
    manager.enable()
    let params: NSDictionary = ["content_id": "tt1234567"]
    let out = manager.processParameters(params, event: "ViewContent")
    XCTAssertEqual(out, params)
  }

  func testProcessParametersInScopeRetailEventEnforces() {
    install(vvpConfig: Self.validRetailConfig)
    manager.enable()
    let params: NSDictionary = ["content_id": "tt1234567", "fb_currency": "USD"]
    let out = manager.processParameters(params, event: "Purchase")
    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertNotNil(out?["vvp_md"] as? String)
  }

  // MARK: - Tagging (vvp + vvp_md)

  func testProcessParametersTagsVvpAndEmitsVpRpOnValueMatch() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let params: NSDictionary = ["fb_content_ids": "tt1234567", "fb_currency": "USD"]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    let mdString = out?["vvp_md"] as? String
    XCTAssertNotNil(mdString)
    let md = try? JSONSerialization.jsonObject(with: mdString!.data(using: .utf8)!) as? [String: Any]
    XCTAssertEqual(md?["vp_rp"] as? [String], ["fb_content_ids"])
    XCTAssertNil(md?["vp_rp_ev"]) // omitted when empty
  }

  func testProcessParametersEmitsVpRpEvSentinelOnEventNameMatch() {
    let cfg = """
      {"enabled": true,
       "rules": [{"place": 3, "keyRegex": "video_view", "valueRegex": ""}],
       "standardParams": {"foo": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = ["foo": "bar"]

    let out = manager.processParameters(params, event: "video_view_started")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    let mdString = out?["vvp_md"] as? String
    XCTAssertNotNil(mdString)
    let md = try? JSONSerialization.jsonObject(with: mdString!.data(using: .utf8)!) as? [String: Any]
    // Sentinel — never echoes the actual event name.
    XCTAssertEqual(md?["vp_rp_ev"] as? [String], ["1"])
    XCTAssertNil(md?["vp_rp"]) // omitted when empty
  }

  func testProcessParametersEmitsBothBucketsWhenBothFire() {
    let cfg = """
      {"enabled": true,
       "rules": [
         {"place": 3, "keyRegex": "video_view", "valueRegex": ""},
         {"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}
       ],
       "standardParams": {"fb_content_ids": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = ["fb_content_ids": "tt1234567"]

    let out = manager.processParameters(params, event: "video_view_started")

    let mdString = out?["vvp_md"] as? String
    XCTAssertNotNil(mdString)
    let md = try? JSONSerialization.jsonObject(with: mdString!.data(using: .utf8)!) as? [String: Any]
    XCTAssertEqual(md?["vp_rp"] as? [String], ["fb_content_ids"])
    XCTAssertEqual(md?["vp_rp_ev"] as? [String], ["1"])
  }

  func testProcessParametersVvpMdKeysAreSorted() {
    // Two matched cdKeys → vp_rp must come back sorted (deterministic for tests/wire).
    let cfg = """
      {"enabled": true,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"alpha": true, "zebra": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = ["zebra": "tt9876543", "alpha": "tt1234567"]

    let out = manager.processParameters(params, event: "Purchase")
    let mdString = out?["vvp_md"] as? String
    let md = try? JSONSerialization.jsonObject(with: mdString!.data(using: .utf8)!) as? [String: Any]
    XCTAssertEqual(md?["vp_rp"] as? [String], ["alpha", "zebra"])
  }

  // MARK: - Sanitization / customData filter

  func testProcessParametersSanitizesFbContentIdsInsteadOfDropping() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "fb_currency": "USD",
      "video_title": "Finding Nemo",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    // Standard param preserved verbatim.
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
    // Content-ID key kept on payload, value scrubbed.
    XCTAssertEqual(out?["fb_content_ids"] as? String, "_removed_")
    // Other non-standard key dropped.
    XCTAssertNil(out?["video_title"])
    // Tag still added.
    XCTAssertEqual(out?["vvp"] as? String, "1")
  }

  func testProcessParametersSanitizesFbContentIdSingularToo() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "^fb_content_id$", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = ["fb_content_id": "tt9876543", "fb_currency": "USD"]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["fb_content_id"] as? String, "_removed_")
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
  }

  func testProcessParametersSkipsCustomDataFilterWhenStandardParamsEmpty() {
    let cfg = """
      {"enabled": true,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = ["fb_content_ids": "tt1234567", "video_title": "Nemo"]

    let out = manager.processParameters(params, event: "Purchase")

    // vvp=1 still emitted, but no filtering since allowlist empty.
    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertEqual(out?["fb_content_ids"] as? String, "tt1234567") // un-sanitized
    XCTAssertEqual(out?["video_title"] as? String, "Nemo") // not dropped
  }

  func testProcessParametersPreservesUnderscoreFrameworkKeysWhenInAllowlist() {
    // Confirms framework metadata (e.g. _logTime) survives if the server-side
    // standardParams allowlist includes it. iOS callers typically pass these
    // keys through, so the server is expected to allowlist them.
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"_logTime": true, "_implicitlyLogged": true, "fb_content_ids": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = [
      "_logTime": NSNumber(value: 1700000000),
      "_implicitlyLogged": "0",
      "fb_content_ids": "tt1234567",
    ]

    let out = manager.processParameters(params, event: "Purchase")
    XCTAssertEqual(out?["_logTime"] as? NSNumber, NSNumber(value: 1700000000))
    XCTAssertEqual(out?["_implicitlyLogged"] as? String, "0")
    XCTAssertEqual(out?["fb_content_ids"] as? String, "_removed_")
  }

  func testProcessParametersContentIdSanitizedEvenWhenInStandardParams() {
    // Content-ID keys must always be sanitized to "_removed_" regardless of
    // whether the server's standardParams allowlist includes them. The
    // allowlist keeps the key on the payload for downstream attribution, but
    // the value must be scrubbed when VVP fires. This test covers both
    // fb_content_ids and fb_content_id in the same payload.
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_content_ids": true, "fb_content_id": true, "fb_currency": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "fb_content_id": "tt7654321",
      "fb_currency": "USD",
      "custom_key": "should_be_dropped",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["fb_content_ids"] as? String, "_removed_")
    XCTAssertEqual(out?["fb_content_id"] as? String, "_removed_")
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
    XCTAssertNil(out?["custom_key"])
    XCTAssertEqual(out?["vvp"] as? String, "1")
  }

  // MARK: - isShadowEnabled enforcement gate

  func testProcessParametersShadowModeEmitsAdoptionTagsWithoutMutatingCustomData() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": true,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "\\\\btt\\\\d{7,}\\\\b"}],
       "standardParams": {"fb_currency": true, "fb_value": true},
       "inScopeEventNames": null}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "fb_currency": "USD",
      "video_title": "Finding Nemo",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    // Adoption tags emitted...
    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertNotNil(out?["vvp_md"] as? String)
    // ...but customData is left untouched in shadow mode.
    XCTAssertEqual(out?["fb_content_ids"] as? String, "tt1234567")
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
    XCTAssertEqual(out?["video_title"] as? String, "Finding Nemo")
  }

  func testProcessParametersDefaultsToShadowModeWhenIsShadowEnabledOmitted() {
    install(vvpConfig: Self.shadowDefaultNonRetailConfig)
    manager.enable()
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "video_title": "Finding Nemo",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    // Default = shadow => no mutation.
    XCTAssertEqual(out?["fb_content_ids"] as? String, "tt1234567")
    XCTAssertEqual(out?["video_title"] as? String, "Finding Nemo")
  }

  func testProcessParametersEnforceMutatesOnlyWhenExplicitFalse() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "fb_currency": "USD",
      "video_title": "Finding Nemo",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    // standardParam preserved.
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
    // content-ID key kept, value sanitized.
    XCTAssertEqual(out?["fb_content_ids"] as? String, "_removed_")
    // Non-standard non-content-ID key dropped.
    XCTAssertNil(out?["video_title"])
  }

  // MARK: - contents[].id sanitization

  func testProcessParametersScrubsIdInContentsArrayEntries() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let contentsJson = """
      [{"id":"sku_19738928","quantity":1,"item_price":50.0,"brand":"PUMA"},\
      {"id":"sku_19736278","quantity":2,"item_price":100.0,"brand":"Jordan"}]
      """
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_currency": "USD",
      "fb_content": contentsJson,
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
    let resultStr = out?["fb_content"] as? String
    XCTAssertNotNil(resultStr)
    let decoded = try? JSONSerialization.jsonObject(
      with: resultStr!.data(using: .utf8)!, options: []
    ) as? [[String: Any]]
    XCTAssertEqual(decoded?.count, 2)
    XCTAssertEqual(decoded?[0]["id"] as? String, "_removed_")
    XCTAssertEqual(decoded?[0]["quantity"] as? Int, 1)
    XCTAssertEqual(decoded?[0]["brand"] as? String, "PUMA")
    XCTAssertEqual(decoded?[1]["id"] as? String, "_removed_")
    XCTAssertEqual(decoded?[1]["quantity"] as? Int, 2)
    XCTAssertEqual(decoded?[1]["brand"] as? String, "Jordan")
  }

  func testProcessParametersScrubsIdInContentsNativeArray() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let contents: [[String: Any]] = [
      ["id": "sku_123", "quantity": 1, "item_price": 50.0],
    ]
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_currency": "USD",
      "fb_content": contents,
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    let resultArr = out?["fb_content"] as? [[String: Any]]
    XCTAssertNotNil(resultArr)
    XCTAssertEqual(resultArr?.count, 1)
    XCTAssertEqual(resultArr?[0]["id"] as? String, "_removed_")
    XCTAssertEqual(resultArr?[0]["quantity"] as? Int, 1)
  }

  func testProcessParametersContentsNoOpWhenMissing() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_currency": "USD",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertNil(out?["fb_content"])
  }

  func testProcessParametersContentsNoOpOnMalformedJson() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_content": "not_json_at_all",
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertEqual(out?["fb_content"] as? String, "not_json_at_all")
  }

  func testProcessParametersContentsDoesNotAddIdWhenEntryHadNone() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let contentsJson = """
      [{"quantity":1,"item_price":10.0},{"id":"tt9999","quantity":2}]
      """
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_content": contentsJson,
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    let resultStr = out?["fb_content"] as? String
    XCTAssertNotNil(resultStr)
    let decoded = try? JSONSerialization.jsonObject(
      with: resultStr!.data(using: .utf8)!, options: []
    ) as? [[String: Any]]
    XCTAssertEqual(decoded?.count, 2)
    XCTAssertNil(decoded?[0]["id"])
    XCTAssertEqual(decoded?[0]["quantity"] as? Int, 1)
    XCTAssertEqual(decoded?[1]["id"] as? String, "_removed_")
    XCTAssertEqual(decoded?[1]["quantity"] as? Int, 2)
  }

  func testProcessParametersContentsNotScrubedInShadowMode() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": true,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let contentsJson = """
      [{"id":"sku_19738928","quantity":1}]
      """
    let params: NSDictionary = [
      "movie_id": "tt1234567",
      "fb_content": contentsJson,
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    let resultStr = out?["fb_content"] as? String
    XCTAssertNotNil(resultStr)
    let decoded = try? JSONSerialization.jsonObject(
      with: resultStr!.data(using: .utf8)!, options: []
    ) as? [[String: Any]]
    XCTAssertEqual(decoded?[0]["id"] as? String, "sku_19738928")
  }

  func testProcessParametersContentsAndTopLevelContentIdsBothScrubbed() {
    let cfg = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1, "keyRegex": "", "valueRegex": "tt\\\\d+"}],
       "standardParams": {"fb_currency": true, "fb_content": true}}
      """
    install(vvpConfig: cfg)
    manager.enable()
    let contentsJson = """
      [{"id":"tt1234567","quantity":1}]
      """
    let params: NSDictionary = [
      "fb_content_ids": "tt1234567",
      "fb_currency": "USD",
      "fb_content": contentsJson,
    ]

    let out = manager.processParameters(params, event: "Purchase")

    XCTAssertEqual(out?["vvp"] as? String, "1")
    XCTAssertEqual(out?["fb_content_ids"] as? String, "_removed_")
    let resultStr = out?["fb_content"] as? String
    XCTAssertNotNil(resultStr)
    let decoded = try? JSONSerialization.jsonObject(
      with: resultStr!.data(using: .utf8)!, options: []
    ) as? [[String: Any]]
    XCTAssertEqual(decoded?[0]["id"] as? String, "_removed_")
    XCTAssertEqual(decoded?[0]["quantity"] as? Int, 1)
    XCTAssertEqual(out?["fb_currency"] as? String, "USD")
  }

  // MARK: - detectMatches (direct unit-level coverage)

  func testDetectMatchesPureCustomDataMatch() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let result = manager.detectMatches(
      eventName: "Purchase",
      customData: ["fb_content_ids": "tt9876543"],
      rules: manager.config?.rules ?? []
    )
    XCTAssertTrue(result.matched)
    XCTAssertEqual(result.cdKeys, ["fb_content_ids"])
    XCTAssertTrue(result.evNames.isEmpty)
  }

  func testDetectMatchesPureEventNameMatch() {
    let json = """
      {"enabled": true, "rules": [{"place": 3, "keyRegex": "VideoView", "valueRegex": ""}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)!
    let result = manager.detectMatches(
      eventName: "VideoView",
      customData: nil,
      rules: cfg.rules
    )
    XCTAssertTrue(result.matched)
    XCTAssertEqual(result.evNames, ["1"]) // sentinel — never echoes the event name
    XCTAssertTrue(result.cdKeys.isEmpty)
  }

  func testDetectMatchesNoMatch() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let result = manager.detectMatches(
      eventName: "Purchase",
      customData: ["fb_value": 1.99],
      rules: manager.config?.rules ?? []
    )
    XCTAssertFalse(result.matched)
    XCTAssertTrue(result.cdKeys.isEmpty)
    XCTAssertTrue(result.evNames.isEmpty)
  }

  // MARK: - keyNegativeRegex enforcement

  /// Mirror of the PHP guard added in SignalsIntegrityVVPUtils: a key that
  /// matches both `keyRegex` AND `keyNegativeRegex` must NOT fire — lets the
  /// server allowlist `utm_*` style false positives whose names satisfy the
  /// positive content/video regex.
  func testDetectMatchesCustomDataKeyNegativeRegexSuppressesMatch() {
    let json = """
      {"enabled": true,
       "rules": [{"place": 1,
                  "keyRegex": "(\\\\b|_)(video|content)(\\\\b|_)",
                  "valueRegex": "",
                  "keyNegativeRegex": "(\\\\b|_)(utm|url|refer)(\\\\b|_)"}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)!
    let result = manager.detectMatches(
      eventName: "Purchase",
      customData: ["utm_content_id": "anything", "video_id": "tt1234567"],
      rules: cfg.rules
    )
    XCTAssertTrue(result.matched)
    // `utm_content_id` matches positive keyRegex but is suppressed by negative.
    XCTAssertEqual(result.cdKeys, ["video_id"])
  }

  func testDetectMatchesCustomDataKeyNegativeRegexNilDoesNotSuppress() {
    // Sanity: when keyNegativeRegex is absent, the legacy positive-only behavior is preserved.
    let json = """
      {"enabled": true,
       "rules": [{"place": 1,
                  "keyRegex": "(\\\\b|_)(video|content)(\\\\b|_)",
                  "valueRegex": ""}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)!
    let result = manager.detectMatches(
      eventName: "Purchase",
      customData: ["utm_content_id": "anything", "video_id": "tt1234567"],
      rules: cfg.rules
    )
    XCTAssertTrue(result.matched)
    XCTAssertEqual(result.cdKeys, ["utm_content_id", "video_id"])
  }

  func testDetectMatchesEventNameKeyNegativeRegexSuppressesMatch() {
    let json = """
      {"enabled": true,
       "rules": [{"place": 3,
                  "keyRegex": "video",
                  "valueRegex": "",
                  "keyNegativeRegex": "utm"}],
       "standardParams": {}}
      """
    let cfg = VVPConfigManager.parseConfig(jsonString: json)!
    // Event name matches positive AND negative -> suppressed.
    let suppressed = manager.detectMatches(
      eventName: "utm_video_view",
      customData: nil,
      rules: cfg.rules
    )
    XCTAssertFalse(suppressed.matched)
    XCTAssertTrue(suppressed.evNames.isEmpty)

    // Event name matches positive only -> fires.
    let fired = manager.detectMatches(
      eventName: "video_view_started",
      customData: nil,
      rules: cfg.rules
    )
    XCTAssertTrue(fired.matched)
    XCTAssertEqual(fired.evNames, ["1"])
  }

  func testProcessParametersKeyNegativeRegexSuppressesEnforcement() {
    // End-to-end: a single-rule config whose only matching key is suppressed
    // by keyNegativeRegex must leave the payload untouched (no vvp tag, no
    // sanitization).
    let json = """
      {"enabled": true,
       "isShadowEnabled": false,
       "rules": [{"place": 1,
                  "keyRegex": "content",
                  "valueRegex": "",
                  "keyNegativeRegex": "utm"}],
       "standardParams": {"fb_currency": true}}
      """
    install(vvpConfig: json)
    manager.enable()
    let params: NSDictionary = ["utm_content_id": "x", "fb_currency": "USD"]
    let out = manager.processParameters(params, event: "Purchase")
    XCTAssertEqual(out, params)
    XCTAssertNil(out?["vvp"])
    XCTAssertNil(out?["vvp_md"])
  }
}
