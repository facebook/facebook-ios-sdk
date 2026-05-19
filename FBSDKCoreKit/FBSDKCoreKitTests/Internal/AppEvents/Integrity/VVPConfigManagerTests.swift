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
      "rules": [{"place": 1, "keyRegex": "", "valueRegex": "\\\\btt\\\\d{7,}\\\\b"}],
      "standardParams": {"fb_currency": true, "fb_value": true},
      "inScopeEventNames": null
    }
    """

  private static let validRetailConfig = """
    {
      "enabled": true,
      "rules": [{"place": 1, "keyRegex": "content_id", "valueRegex": "tt\\\\d+"}],
      "standardParams": {"fb_currency": true},
      "inScopeEventNames": ["Purchase", "AddToCart"]
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

  // MARK: - processParameters (D2: stub passthrough; D3 adds enforcement)

  func testProcessParametersStubReturnsInputUnchanged() {
    install(vvpConfig: Self.validNonRetailConfig)
    manager.enable()
    let params: NSDictionary = ["fb_content_ids": "tt1234567", "fb_value": 1.99]
    XCTAssertEqual(manager.processParameters(params, event: "Purchase"), params)
  }
}
