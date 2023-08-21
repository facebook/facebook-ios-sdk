/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ServerConfigurationTests: XCTestCase {

  var configuration = Fixtures.defaultConfiguration

  typealias Fixtures = ServerConfigurationFixtures

  let exampleURL = SampleURLs.valid

  override func setUp() {
    super.setUp()

    configuration = Fixtures.defaultConfiguration
  }

  func testUsingDefaults() {
    XCTAssertTrue(configuration.isDefaults, "Should assume defaults are being used unless otherwise expressed")

    configuration = Fixtures.configuration(withDictionary: ["defaults": false])
    XCTAssertFalse(configuration.isDefaults, "Should store whether or not defaults are being used")
  }

  func testCreatingWithEmptyAppID() {
    configuration = Fixtures.configuration(withDictionary: ["appID": ""])
    XCTAssertEqual(
      configuration.appID,
      "",
      "Should use the given app identifier regardless of value"
    )
  }

  func testCreatingWithDefaultAdvertisingIdEnabled() {
    XCTAssertFalse(
      configuration.isAdvertisingIDEnabled,
      "Advertising identifier enabled should default to false"
    )
  }

  func testCreatingWithKnownAdvertisingIdEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["advertisingIDEnabled": true])
    XCTAssertTrue(
      configuration.isAdvertisingIDEnabled,
      "Advertising identifier enabled should be settable"
    )
  }

  func testCreatingWithDefaultImplicitPurchaseLoggingEnabled() {
    XCTAssertFalse(
      configuration.isImplicitPurchaseLoggingSupported,
      "Implicit purchase logging enabled should default to false"
    )
  }

  func testCreatingWithKnownImplicitPurchaseLoggingEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["implicitPurchaseLoggingEnabled": true])
    XCTAssertTrue(
      configuration.isImplicitPurchaseLoggingSupported,
      "Implicit purchase logging enabled should be settable"
    )
  }

  func testCreatingWithDefaultImplicitLoggingEnabled() {
    XCTAssertFalse(
      configuration.isImplicitLoggingSupported,
      "Implicit logging enabled should default to false"
    )
  }

  func testCreatingWithKnownImplicitLoggingEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["implicitLoggingEnabled": true])
    XCTAssertTrue(
      configuration.isImplicitLoggingSupported,
      "Implicit logging enabled should be settable"
    )
  }

  func testCreatingWithDefaultCodelessEventsEnabled() {
    XCTAssertFalse(
      configuration.isCodelessEventsEnabled,
      "Codeless events enabled should default to false"
    )
  }

  func testCreatingWithKnownCodelessEventsEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["codelessEventsEnabled": true])
    XCTAssertTrue(
      configuration.isCodelessEventsEnabled,
      "Codeless events enabled should be settable"
    )
  }

  func testCreatingWithDefaultUninstallTrackingEnabled() {
    XCTAssertFalse(
      configuration.isUninstallTrackingEnabled,
      "Uninstall tracking enabled should default to false"
    )
  }

  func testCreatingWithKnownUninstallTrackingEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["uninstallTrackingEnabled": true])
    XCTAssertTrue(
      configuration.isUninstallTrackingEnabled,
      "Uninstall tracking enabled should be settable"
    )
  }

  func testCreatingWithoutAppName() {
    XCTAssertNil(configuration.appName, "Should not use a default value for app name")
  }

  func testCreatingWithEmptyAppName() {
    configuration = Fixtures.configuration(withDictionary: ["appName": ""])
    XCTAssertEqual(
      configuration.appName,
      "",
      "Should use the given app name regardless of value"
    )
  }

  func testCreatingWithKnownAppName() {
    configuration = Fixtures.configuration(withDictionary: ["appName": "foo"])
    XCTAssertEqual(
      configuration.appName,
      "foo",
      "App name should be settable"
    )
  }

  func testCreatingWithoutDefaultShareMode() {
    XCTAssertNil(
      configuration.defaultShareMode,
      "Should not provide a default for the default share mode"
    )
  }

  func testCreatingWithKnownDefaultShareMode() {
    configuration = Fixtures.configuration(withDictionary: ["defaultShareMode": "native"])
    XCTAssertEqual(
      configuration.defaultShareMode,
      "native",
      "Default share mode should be settable"
    )
  }

  func testCreatingWithEmptyDefaultShareMode() {
    configuration = Fixtures.configuration(withDictionary: ["defaultShareMode": ""])
    XCTAssertEqual(
      configuration.defaultShareMode,
      "",
      "Should use the given share mode regardless of value"
    )
  }

  func testCreatingWithDefaultLoginTooltipEnabled() {
    XCTAssertFalse(
      configuration.isLoginTooltipEnabled,
      "Login tooltip enabled should default to false"
    )
  }

  func testCreatingWithKnownLoginTooltipEnabled() {
    configuration = Fixtures.configuration(withDictionary: ["loginTooltipEnabled": true])
    XCTAssertTrue(
      configuration.isLoginTooltipEnabled,
      "Login tooltip enabled should be settable"
    )
  }

  func testCreatingWithoutLoginTooltipText() {
    XCTAssertNil(configuration.loginTooltipText, "Should not use a default value for the login tooltip text")
  }

  func testCreatingWithEmptyLoginTooltipText() {
    configuration = Fixtures.configuration(withDictionary: ["loginTooltipText": ""])
    XCTAssertEqual(
      configuration.loginTooltipText,
      "",
      "Should use the given login tooltip text regardless of value"
    )
  }

  func testCreatingWithKnownLoginTooltipText() {
    configuration = Fixtures.configuration(withDictionary: ["loginTooltipText": "foo"])
    XCTAssertEqual(
      configuration.loginTooltipText,
      "foo",
      "Login tooltip text should be settable"
    )
  }

  func testCreatingWithoutTimestamp() {
    XCTAssertNil(configuration.timestamp, "Should not have a timestamp by default")
  }

  func testCreatingWithTimestamp() {
    let date = Date()
    configuration = Fixtures.configuration(withDictionary: ["timestamp": date])
    XCTAssertEqual(
      configuration.timestamp,
      date,
      "Should use the timestamp given during creation"
    )
  }

  func testCreatingWithDefaultSessionTimeoutInterval() {
    XCTAssertEqual(
      configuration.sessionTimeoutInterval,
      60,
      "Should set the correct default timeout interval"
    )
  }

  func testCreatingWithSessionTimeoutInterval() {
    configuration = Fixtures.configuration(withDictionary: ["sessionTimeoutInterval": 200])
    XCTAssertEqual(
      configuration.sessionTimeoutInterval,
      200,
      "Should set the session timeout interval from the remote"
    )
  }

  func testCreatingWithoutLoggingToken() {
    XCTAssertNil(
      configuration.loggingToken,
      "Should not provide a default for the logging token"
    )
  }

  func testCreatingWithEmptyLoggingToken() {
    configuration = Fixtures.configuration(withDictionary: ["loggingToken": ""])
    XCTAssertEqual(
      configuration.loggingToken,
      "",
      "Should use the logging token given during creation"
    )
  }

  func testCreatingWithKnownLoggingToken() {
    configuration = Fixtures.configuration(withDictionary: ["loggingToken": "foo"])
    XCTAssertEqual(
      configuration.loggingToken,
      "foo",
      "Should use the logging token given during creation"
    )
  }

  func testCreatingWithoutSmartLoginBookmarkUrl() {
    XCTAssertNil(
      configuration.smartLoginBookmarkIconURL,
      "Should not provide a default url for the smart login bookmark icon"
    )
  }

  func testCreatingWithInvalidSmartLoginBookmarkUrl() {
    configuration = Fixtures.configuration(withDictionary: ["smartLoginBookmarkIconURL": exampleURL])
    XCTAssertEqual(
      configuration.smartLoginBookmarkIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithValidSmartBookmarkUrl() {
    configuration = Fixtures.configuration(withDictionary: ["smartLoginBookmarkIconURL": exampleURL])
    XCTAssertEqual(
      configuration.smartLoginBookmarkIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithSmartLoginOptionsDefault() {
    XCTAssertEqual(
      configuration.smartLoginOptions,
      [],
      "Should default smart login options to unknown"
    )
  }

  func testCreatingWithSmartLoginOptionsEnabled() {
    configuration = Fixtures.configuration(
      withDictionary: ["smartLoginOptions": FBSDKServerConfigurationSmartLoginOptions.enabled.rawValue]
    )
    XCTAssertEqual(
      configuration.smartLoginOptions,
      FBSDKServerConfigurationSmartLoginOptions.enabled,
      "Should use the smartLoginOptions given during creation"
    )
  }

  func testCreatingWithoutErrorConfiguration() {
    XCTAssertNil(configuration.errorConfiguration, "Should not have an error configuration by default")
  }

  func testCreatingWithErrorConfiguration() {
    let errorConfiguration = _ErrorConfiguration(dictionary: nil)
    configuration = Fixtures.configuration(withDictionary: ["errorConfiguration": errorConfiguration])

    XCTAssertEqual(
      configuration.errorConfiguration,
      errorConfiguration,
      "Error configuration should be settable"
    )
  }

  func testCreatingWithoutSmartLoginMenuUrl() {
    XCTAssertNil(
      configuration.smartLoginMenuIconURL,
      "Should not provide a default url for the smart login menu icon"
    )
  }

  func testCreatingWithInvalidSmartLoginMenuUrl() {
    configuration = Fixtures.configuration(withDictionary: ["smartLoginMenuIconURL": exampleURL])
    XCTAssertEqual(
      configuration.smartLoginMenuIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithValidSmartLoginMenuUrl() {
    configuration = Fixtures.configuration(withDictionary: ["smartLoginMenuIconURL": exampleURL])
    XCTAssertEqual(
      configuration.smartLoginMenuIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithoutUpdateMessage() {
    XCTAssertNil(
      configuration.updateMessage,
      "Should not provide a default for the update message"
    )
  }

  func testCreatingWithEmptyUpdateMessage() {
    configuration = Fixtures.configuration(withDictionary: ["updateMessage": ""])
    XCTAssertEqual(
      configuration.updateMessage,
      "",
      "Should use the update message given during creation"
    )
  }

  func testCreatingWithKnownUpdateMessage() {
    configuration = Fixtures.configuration(withDictionary: ["updateMessage": "foo"])
    XCTAssertEqual(
      configuration.updateMessage,
      "foo",
      "Should use the update message given during creation"
    )
  }

  func testCreatingWithoutEventBindings() {
    XCTAssertNil(
      configuration.eventBindings,
      "Should not provide default event bindings"
    )
  }

  func testCreatingWithEmptyEventBindings() {
    configuration = Fixtures.configuration(withDictionary: ["eventBindings": []])
    XCTAssertNotNil(configuration.eventBindings, "Should use the empty list of event bindings it was created with")
    XCTAssertEqual(
      configuration.eventBindings?.isEmpty,
      true,
      "Should use the empty list of event bindings it was created with"
    )
  }

  func testCreatingWithEventBindings() {
    let bindings = [["a": "b"]]
    configuration = Fixtures.configuration(withDictionary: ["eventBindings": bindings])

    XCTAssertEqual(
      configuration.eventBindings as? [[String: String]],
      bindings,
      "Event binding should be settable"
    )
  }

  func testCreatingWithoutDialogConfigurations() {
    XCTAssertNil(
      configuration.dialogConfigurations(),
      "Should not have dialog configurations by default"
    )
  }

  func testCreatingWithDialogConfigurations() {
    let dialogConfigurations = [
      "dialog": "Hello",
      "dialog2": "World",
    ]

    configuration = Fixtures.configuration(withDictionary: ["dialogConfigurations": dialogConfigurations])
    XCTAssertEqual(
      configuration.dialogConfigurations() as? [String: String],
      dialogConfigurations,
      "Should set the exact dialog configurations it was created with"
    )
  }

  func testCreatingWithoutDialogFlows() {
    // Need to recreate with a new appID to invalidate cache of default configuration
    configuration = _ServerConfiguration.defaultServerConfiguration(forAppID: name)

    let expectedDefaultDialogFlows = [
      FBSDKDialogConfigurationNameDefault: [
        FBSDKDialogConfigurationFeatureUseNativeFlow: false,
        FBSDKDialogConfigurationFeatureUseSafariViewController: true,
      ],
      DialogConfigurationName.message: [
        FBSDKDialogConfigurationFeatureUseNativeFlow: true,
      ],
    ]

    XCTAssertEqual(
      configuration.dialogFlows() as? [String: [String: Bool]],
      expectedDefaultDialogFlows,
      "Should use the expected default dialog flow"
    )
  }

  func testCreatingWithDialogFlows() {
    let dialogFlows = [
      "foo": [
        FBSDKDialogConfigurationFeatureUseNativeFlow: true,
        FBSDKDialogConfigurationFeatureUseSafariViewController: true,
      ],
      "bar": [
        FBSDKDialogConfigurationFeatureUseNativeFlow: false,
      ],
    ]

    configuration = Fixtures.configuration(withDictionary: ["dialogFlows": dialogFlows])

    XCTAssertEqual(
      configuration.dialogFlows() as? [String: [String: Bool]],
      dialogFlows,
      "Should set the exact dialog flows it was created with"
    )
  }

  func testCreatingWithoutAAMRules() {
    XCTAssertNil(
      configuration.aamRules,
      "Should not have aam rules by default"
    )
  }

  func testCreatingWithAAMRules() {
    let rules = ["foo": "bar"]

    configuration = Fixtures.configuration(withDictionary: ["aamRules": rules])

    XCTAssertEqual(
      configuration.aamRules as? [String: String],
      rules,
      "Should set the exact aam rules it was created with"
    )
  }

  func testCreatingWithoutRestrictiveParams() {
    XCTAssertNil(
      configuration.restrictiveParams,
      "Should not have restrictive params by default"
    )
  }

  func testCreatingWithRestrictiveParams() {
    let params = ["foo": "bar"]

    configuration = Fixtures.configuration(withDictionary: ["restrictiveParams": params])

    XCTAssertEqual(
      configuration.restrictiveParams as? [String: String],
      params,
      "Should set the exact restrictive params it was created with"
    )
  }

  func testCreatingWithoutSuggestedEventSetting() {
    XCTAssertNil(
      configuration.suggestedEventsSetting,
      "Should not have a suggested events setting by default"
    )
  }

  func testCreatingWithSuggestedEventSetting() {
    let setting = ["foo": "bar"]
    configuration = Fixtures.configuration(withDictionary: ["suggestedEventsSetting": setting])

    XCTAssertEqual(
      configuration.suggestedEventsSetting as? [String: String],
      setting,
      "Should set the exact suggested events setting it was created with"
    )
  }

  func testEncodingAndDecoding() throws {
    let errorConfiguration = _ErrorConfiguration(dictionary: nil)

    configuration = Fixtures.configuration(withDictionary: [
      "appID": "appID",
      "appName": "appName",
      "loginTooltipEnabled": true,
      "loginTooltipText": "loginTooltipText",
      "defaultShareMode": "defaultShareMode",
      "advertisingIDEnabled": true,
      "implicitLoggingEnabled": true,
      "implicitPurchaseLoggingEnabled": true,
      "codelessEventsEnabled": true,
      "uninstallTrackingEnabled": true,
      "dialogFlows": ["foo": "Bar"],
      "timestamp": Date(),
      "errorConfiguration": errorConfiguration,
      "sessionTimeoutInterval": 100,
      "defaults": true,
      "loggingToken": "loggingToken",
      "smartLoginOptions": FBSDKServerConfigurationSmartLoginOptions.enabled.rawValue,
      "smartLoginBookmarkIconURL": exampleURL,
      "smartLoginMenuIconURL": exampleURL,
      "updateMessage": "updateMessage",
      "eventBindings": [["foo": "bar"]],
      "restrictiveParams": ["restrictiveParams": "foo"],
      "AAMRules": ["AAMRules": "foo"],
      "suggestedEventsSetting": ["suggestedEventsSetting": "foo"],
    ])

    // Encode and Decode
    let object = configuration
    let decodedObject = try CodabilityTesting.encodeAndDecode(object)

    // Test Objects
    // XCTAssertEqual(decodedObject, object, .isCodable) // Doesn't work since isEqual not implemented
    XCTAssertNotIdentical(decodedObject, object, .isCodable)

    // Test Codable Properties
    XCTAssertEqual(decodedObject.isAdvertisingIDEnabled, object.isAdvertisingIDEnabled, .isCodable)
    XCTAssertEqual(decodedObject.appID, object.appID, .isCodable)
    XCTAssertEqual(decodedObject.appName, object.appName, .isCodable)
    XCTAssertEqual(decodedObject.defaultShareMode, object.defaultShareMode, .isCodable)
    XCTAssertEqualDicts(decodedObject.dialogFlows(), object.dialogFlows(), .isCodable)
    XCTAssertEqualDicts(decodedObject.dialogConfigurations(), object.dialogConfigurations(), .isCodable)
    // FBSDKErrorConfiguration does not implement isEqual: so just test for not nil
    XCTAssertNotNil(decodedObject.errorConfiguration)
    XCTAssertEqual(decodedObject.isImplicitLoggingSupported, object.isImplicitLoggingSupported, .isCodable)
    XCTAssertEqual(decodedObject.isImplicitPurchaseLoggingSupported, object.isImplicitPurchaseLoggingSupported)
    XCTAssertEqual(decodedObject.isCodelessEventsEnabled, object.isCodelessEventsEnabled, .isCodable)
    XCTAssertEqual(decodedObject.isLoginTooltipEnabled, object.isLoginTooltipEnabled, .isCodable)
    XCTAssertEqual(decodedObject.isUninstallTrackingEnabled, object.isUninstallTrackingEnabled, .isCodable)
    XCTAssertEqual(decodedObject.loginTooltipText, object.loginTooltipText, .isCodable)
    XCTAssertEqual(decodedObject.timestamp, object.timestamp, .isCodable)
    XCTAssertEqual(decodedObject.sessionTimeoutInterval, object.sessionTimeoutInterval, .isCodable)
    XCTAssertEqual(decodedObject.loggingToken, object.loggingToken, .isCodable)
    XCTAssertEqual(decodedObject.smartLoginOptions, object.smartLoginOptions, .isCodable)
    XCTAssertEqual(decodedObject.smartLoginBookmarkIconURL, object.smartLoginBookmarkIconURL, .isCodable)
    XCTAssertEqual(decodedObject.smartLoginMenuIconURL, object.smartLoginMenuIconURL, .isCodable)
    XCTAssertEqual(decodedObject.updateMessage, object.updateMessage, .isCodable)
    XCTAssertEqualDicts(decodedObject.restrictiveParams, object.restrictiveParams, .isCodable)
    XCTAssertEqualDicts(decodedObject.aamRules, object.aamRules, .isCodable)
    XCTAssertEqualDicts(decodedObject.suggestedEventsSetting, object.suggestedEventsSetting, .isCodable)
    XCTAssertEqual(decodedObject.version, object.version, .isCodable)

    // Event bindings is [[String: String]], i.e. an array of dicts
    let objectEventBindings = try XCTUnwrap(object.eventBindings)
    let decodedObjectEventBindings = try XCTUnwrap(decodedObject.eventBindings)
    for (decodedDict, objectDict) in zip(objectEventBindings, decodedObjectEventBindings) {
      XCTAssertEqualDicts(decodedDict, objectDict, .isCodable)
    }

    // isDefaults is not codable
    XCTAssertFalse(
      decodedObject.isDefaults, // was set to true
      "Should not encode whether default values were used to create server configuration"
    )
  }

  func testRetrievingInvalidDialogConfigurationForDialogName() {
    configuration = Fixtures.configuration(withDictionary: [
      "dialogConfigurations": [
        "foo": "bar",
      ],
    ])

    XCTAssertEqual(
      configuration.dialogConfigurations()?["foo"] as? String,
      "bar",
      "Should be able to retrieve an invalid dialog configuration by name"
    )
  }

  func testRetrievingValidDialogConfigurationForDialogName() {
    let fooConfiguration = _DialogConfiguration(
      name: "foo",
      url: exampleURL,
      appVersions: ["1", "2"]
    )

    configuration = Fixtures.configuration(withDictionary: [
      "dialogConfigurations": [
        "foo": fooConfiguration,
      ],
    ])

    XCTAssertEqual(
      configuration.dialogConfiguration(forDialogName: "foo"),
      fooConfiguration,
      "Should be able to retrieve a valid dialog configuration by name"
    )
  }

  // MARK: - Native Dialog Checks

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / nil            / false
  func testNativeDialogForMissingLoginMissingSharingMissingDefaultValue() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / true           / true
  func testNativeDialogForMissingLoginMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / false          / false
  func testNativeDialogForMissingLoginMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / nil            / false
  func testNativeDialogForMissingLoginTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / true           / true
  func testNativeDialogForMissingLoginTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / false          / false
  func testNativeDialogForMissingLoginTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / nil            / false
  func testNativeDialogForMissingLoginFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / true           / true
  func testNativeDialogForMissingLoginFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / false          / false
  func testNativeDialogForMissingLoginFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / nil            / true
  func testNativeDialogForTrueLoginMissingSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / true           / true
  func testNativeDialogForTrueLoginMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / false          / true
  func testNativeDialogForTrueLoginMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / nil            / true
  func testNativeDialogForTrueLoginTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / true           / true
  func testNativeDialogForTrueLoginTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / false          / true
  func testNativeDialogForTrueLoginTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / nil            / true
  func testNativeDialogForTrueLoginFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / true           / true
  func testNativeDialogForTrueLoginFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / false          / true
  func testNativeDialogForTrueLoginFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / nil            / false
  func testNativeDialogForFalseLoginMissingSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / true           / false
  func testNativeDialogForFalseLoginMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / false          / false
  func testNativeDialogForFalseLoginMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / nil            / false
  func testNativeDialogForFalseLoginTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / true           / false
  func testNativeDialogForFalseLoginTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / false          / false
  func testNativeDialogForFalseLoginTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / nil            / false
  func testNativeDialogForFalseLoginFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / true           / false
  func testNativeDialogForFalseLoginFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / false          / false
  func testNativeDialogForFalseLoginFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / nil            / false
  func testNativeDialogForMissingDialogMissingSharingMissingDefaultValue() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / true           / true
  func testNativeDialogForMissingDialogMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / false          / false
  func testNativeDialogForMissingDialogMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / nil            / false
  func testNativeDialogForMissingDialogTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / true           / true
  func testNativeDialogForMissingDialogTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / false          / true
  func testNativeDialogForMissingDialogTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / nil            / false
  func testNativeDialogForMissingDialogFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / true           / false
  func testNativeDialogForMissingDialogFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / false          / false
  func testNativeDialogForMissingDialogFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / nil            / true
  func testNativeDialogForTrueDialogMissingSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / true           / true
  func testNativeDialogForTrueDialogMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / false          / true
  func testNativeDialogForTrueDialogMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / nil            / true
  func testNativeDialogForTrueDialogTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / true           / true
  func testNativeDialogForTrueDialogTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / false          / true
  func testNativeDialogForTrueDialogTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / nil            / true
  func testNativeDialogForTrueDialogFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / true           / true
  func testNativeDialogForTrueDialogFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / false          / true
  func testNativeDialogForTrueDialogFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / nil            / false
  func testNativeDialogForFalseDialogMissingSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / true           / false
  func testNativeDialogForFalseDialogMissingSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / false          / false
  func testNativeDialogForFalseDialogMissingSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / nil            / false
  func testNativeDialogForFalseDialogTrueSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / true           / false
  func testNativeDialogForFalseDialogTrueSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / false          / false
  func testNativeDialogForFalseDialogTrueSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / nil            / false
  func testNativeDialogForFalseDialogFalseSharingMissingDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / true           / false
  func testNativeDialogForFalseDialogFalseSharingTrueDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / false          / false
  func testNativeDialogForFalseDialogFalseSharingFalseDefault() {
    assertNativeDialogIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: false
    )
  }

  // MARK: - SafariVC Checks

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / nil            / false
  func testSafariVCForMissingLoginMissingSharingMissingDefaultValue() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / true           / true
  func testSafariVCForMissingLoginMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / nil           / false          / false
  func testSafariVCForMissingLoginMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / nil            / false
  func testSafariVCForMissingLoginTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / true           / true
  func testSafariVCForMissingLoginTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / true          / false          / false
  func testSafariVCForMissingLoginTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / nil            / false
  func testSafariVCForMissingLoginFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / true           / true
  func testSafariVCForMissingLoginFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / nil   / false         / false          / false
  func testSafariVCForMissingLoginFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / nil            / true
  func testSafariVCForTrueLoginMissingSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / true           / true
  func testSafariVCForTrueLoginMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / nil           / false          / true
  func testSafariVCForTrueLoginMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / nil            / true
  func testSafariVCForTrueLoginTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / true           / true
  func testSafariVCForTrueLoginTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / true          / false          / true
  func testSafariVCForTrueLoginTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / nil            / true
  func testSafariVCForTrueLoginFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / true           / true
  func testSafariVCForTrueLoginFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / true  / false         / false          / true
  func testSafariVCForTrueLoginFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "login",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / nil            / false
  func testSafariVCForFalseLoginMissingSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / true           / false
  func testSafariVCForFalseLoginMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / nil           / false          / false
  func testSafariVCForFalseLoginMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / nil            / false
  func testSafariVCForFalseLoginTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / true           / false
  func testSafariVCForFalseLoginTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / true          / false          / false
  func testSafariVCForFalseLoginTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / nil            / false
  func testSafariVCForFalseLoginFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / true           / false
  func testSafariVCForFalseLoginFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'login'  / false / false         / false          / false
  func testSafariVCForFalseLoginFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "login",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / nil            / false
  func testSafariVCForMissingDialogMissingSharingMissingDefaultValue() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / true           / true
  func testSafariVCForMissingDialogMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / nil           / false          / false
  func testSafariVCForMissingDialogMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / nil            / false
  func testSafariVCForMissingDialogTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / true           / true
  func testSafariVCForMissingDialogTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / true          / false          / true
  func testSafariVCForMissingDialogTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / nil            / false
  func testSafariVCForMissingDialogFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / true           / false
  func testSafariVCForMissingDialogFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / nil   / false         / false          / false
  func testSafariVCForMissingDialogFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: nil,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / nil            / true
  func testSafariVCForTrueDialogMissingSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / true           / true
  func testSafariVCForTrueDialogMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / nil           / false          / true
  func testSafariVCForTrueDialogMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / nil            / true
  func testSafariVCForTrueDialogTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / true           / true
  func testSafariVCForTrueDialogTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / true          / false          / true
  func testSafariVCForTrueDialogTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / nil            / true
  func testSafariVCForTrueDialogFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / true           / true
  func testSafariVCForTrueDialogFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / true  / false         / false          / true
  func testSafariVCForTrueDialogFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: true,
      forFeatureName: "foo",
      withFeatureValue: true,
      sharingValue: false,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / nil            / false
  func testSafariVCForFalseDialogMissingSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / true           / false
  func testSafariVCForFalseDialogMissingSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / nil           / false          / false
  func testSafariVCForFalseDialogMissingSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: nil,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / nil            / false
  func testSafariVCForFalseDialogTrueSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / true           / false
  func testSafariVCForFalseDialogTrueSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / true          / false          / false
  func testSafariVCForFalseDialogTrueSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: true,
      defaultValue: false
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / nil            / false
  func testSafariVCForFalseDialogFalseSharingMissingDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: nil
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / true           / false
  func testSafariVCForFalseDialogFalseSharingTrueDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: true
    )
  }

  // querying / value / sharing value / default value  / expected
  // 'foo'    / false / false         / false          / false
  func testSafariVCForFalseDialogFalseSharingFalseDefault() {
    assertSafariVcIs(
      expected: false,
      forFeatureName: "foo",
      withFeatureValue: false,
      sharingValue: false,
      defaultValue: false
    )
  }

  // MARK: - Helpers

  func setupConfigWithDialogFlowKey(
    flowKey: String,
    forFeatureName name: String,
    withFeatureValue featureValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    sharingValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    defaultValue: Bool? // swiftlint:disable:this discouraged_optional_boolean
  ) {
    var dialogFlows: [String: Any] = [:]
    if featureValue != nil {
      dialogFlows[name] = [
        flowKey: featureValue,
      ]
    }
    if sharingValue != nil {
      dialogFlows["sharing"] = [
        flowKey: sharingValue,
      ]
    }
    if defaultValue != nil {
      dialogFlows["default"] = [
        flowKey: defaultValue,
      ]
    }

    configuration = Fixtures.configuration(withDictionary: ["dialogFlows": dialogFlows])
  }

  func assertSafariVcIs(
    expected: Bool,
    forFeatureName name: String,
    withFeatureValue featureValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    sharingValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    defaultValue: Bool? // swiftlint:disable:this discouraged_optional_boolean
  ) {
    setupConfigWithDialogFlowKey(
      flowKey: "use_safari_vc",
      forFeatureName: name,
      withFeatureValue: featureValue,
      sharingValue: sharingValue,
      defaultValue: defaultValue
    )

    XCTAssertEqual(
      configuration.useSafariViewController(forDialogName: name),
      expected,
      """
      Use safari view controller for dialog name: \(name),
        should return true when the feature value is: \(String(describing: featureValue)),
        the sharing value is: \(String(describing: sharingValue)),
        and the default value is: \(String(describing: defaultValue))
      """
    )
  }

  func assertNativeDialogIs(
    expected: Bool,
    forFeatureName name: String,
    withFeatureValue featureValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    sharingValue: Bool?, // swiftlint:disable:this discouraged_optional_boolean
    defaultValue: Bool? // swiftlint:disable:this discouraged_optional_boolean
  ) {
    setupConfigWithDialogFlowKey(
      flowKey: "use_native_flow",
      forFeatureName: name,
      withFeatureValue: featureValue,
      sharingValue: sharingValue,
      defaultValue: defaultValue
    )

    XCTAssertEqual(
      configuration.useNativeDialog(forDialogName: name),
      expected,
      """
      Use native dialog for dialog name: \(name),
        should return true when the feature value is: \(String(describing: featureValue)),
        the sharing value is: \(String(describing: sharingValue)),
        and the default value is: \(String(describing: defaultValue))
      """
    )
  }

  // This helper is to work around: Protocol 'Any' as a type cannot conform to 'Equatable'
  func XCTAssertEqualDicts(
    _ lhs: [String: Any]?,
    _ rhs: [String: Any]?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if let lhs = lhs,
       let rhs = rhs {
      let dict1 = NSDictionary(dictionary: lhs)
      let dict2 = NSDictionary(dictionary: rhs)
      XCTAssertEqual(dict1, dict2, message(), file: file, line: line)
    } else if lhs == nil && rhs != nil {
      XCTFail("LHS Dict is nil", file: file, line: line)
    } else if lhs != nil && rhs == nil {
      XCTFail("RHS Dict is nil", file: file, line: line)
    }
  }
}

// MARK: - Assumptions

// swiftformat:disable:next extensionaccesscontrol
fileprivate extension String {
  static let isCodable = "FBSDKServerConfiguration should be encodable and decodable"
}
