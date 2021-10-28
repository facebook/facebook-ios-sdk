/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class ServerConfigurationTests: XCTestCase { // swiftlint:disable:this type_body_length

  var config = Fixtures.defaultConfig

  typealias Fixtures = ServerConfigurationFixtures

  let exampleURL = SampleURLs.valid

  override func setUp() {
    super.setUp()

    config = Fixtures.defaultConfig
  }

  func testUsingDefaults() {
    XCTAssertTrue(config.isDefaults, "Should assume defaults are being used unless otherwise expressed")

    config = Fixtures.config(withDictionary: ["defaults": false])
    XCTAssertFalse(config.isDefaults, "Should store whether or not defaults are being used")
  }

  func testCreatingWithEmptyAppID() {
    config = Fixtures.config(withDictionary: ["appID": ""])
    XCTAssertEqual(
      config.appID,
      "",
      "Should use the given app identifier regardless of value"
    )
  }

  func testCreatingWithDefaultAdvertisingIdEnabled() {
    XCTAssertFalse(
      config.isAdvertisingIDEnabled,
      "Advertising identifier enabled should default to false"
    )
  }

  func testCreatingWithKnownAdvertisingIdEnabled() {
    config = Fixtures.config(withDictionary: ["advertisingIDEnabled": true])
    XCTAssertTrue(
      config.isAdvertisingIDEnabled,
      "Advertising identifier enabled should be settable"
    )
  }

  func testCreatingWithDefaultImplicitPurchaseLoggingEnabled() {
    XCTAssertFalse(
      config.isImplicitPurchaseLoggingSupported,
      "Implicit purchase logging enabled should default to false"
    )
  }

  func testCreatingWithKnownImplicitPurchaseLoggingEnabled() {
    config = Fixtures.config(withDictionary: ["implicitPurchaseLoggingEnabled": true])
    XCTAssertTrue(
      config.isImplicitPurchaseLoggingSupported,
      "Implicit purchase logging enabled should be settable"
    )
  }

  func testCreatingWithDefaultImplicitLoggingEnabled() {
    XCTAssertFalse(
      config.isImplicitLoggingSupported,
      "Implicit logging enabled should default to false"
    )
  }

  func testCreatingWithKnownImplicitLoggingEnabled() {
    config = Fixtures.config(withDictionary: ["implicitLoggingEnabled": true])
    XCTAssertTrue(
      config.isImplicitLoggingSupported,
      "Implicit logging enabled should be settable"
    )
  }

  func testCreatingWithDefaultCodelessEventsEnabled() {
    XCTAssertFalse(
      config.isCodelessEventsEnabled,
      "Codeless events enabled should default to false"
    )
  }

  func testCreatingWithKnownCodelessEventsEnabled() {
    config = Fixtures.config(withDictionary: ["codelessEventsEnabled": true])
    XCTAssertTrue(
      config.isCodelessEventsEnabled,
      "Codeless events enabled should be settable"
    )
  }

  func testCreatingWithDefaultUninstallTrackingEnabled() {
    XCTAssertFalse(
      config.isUninstallTrackingEnabled,
      "Uninstall tracking enabled should default to false"
    )
  }

  func testCreatingWithKnownUninstallTrackingEnabled() {
    config = Fixtures.config(withDictionary: ["uninstallTrackingEnabled": true])
    XCTAssertTrue(
      config.isUninstallTrackingEnabled,
      "Uninstall tracking enabled should be settable"
    )
  }

  func testCreatingWithoutAppName() {
    XCTAssertNil(config.appName, "Should not use a default value for app name")
  }

  func testCreatingWithEmptyAppName() {
    config = Fixtures.config(withDictionary: ["appName": ""])
    XCTAssertEqual(
      config.appName,
      "",
      "Should use the given app name regardless of value"
    )
  }

  func testCreatingWithKnownAppName() {
    config = Fixtures.config(withDictionary: ["appName": "foo"])
    XCTAssertEqual(
      config.appName,
      "foo",
      "App name should be settable"
    )
  }

  func testCreatingWithoutDefaultShareMode() {
    XCTAssertNil(
      config.defaultShareMode,
      "Should not provide a default for the default share mode"
    )
  }

  func testCreatingWithKnownDefaultShareMode() {
    config = Fixtures.config(withDictionary: ["defaultShareMode": "native"])
    XCTAssertEqual(
      config.defaultShareMode,
      "native",
      "Default share mode should be settable"
    )
  }

  func testCreatingWithEmptyDefaultShareMode() {
    config = Fixtures.config(withDictionary: ["defaultShareMode": ""])
    XCTAssertEqual(
      config.defaultShareMode,
      "",
      "Should use the given share mode regardless of value"
    )
  }

  func testCreatingWithDefaultLoginTooltipEnabled() {
    XCTAssertFalse(
      config.isLoginTooltipEnabled,
      "Login tooltip enabled should default to false"
    )
  }

  func testCreatingWithKnownLoginTooltipEnabled() {
    config = Fixtures.config(withDictionary: ["loginTooltipEnabled": true])
    XCTAssertTrue(
      config.isLoginTooltipEnabled,
      "Login tooltip enabled should be settable"
    )
  }

  func testCreatingWithoutLoginTooltipText() {
    XCTAssertNil(config.loginTooltipText, "Should not use a default value for the login tooltip text")
  }

  func testCreatingWithEmptyLoginTooltipText() {
    config = Fixtures.config(withDictionary: ["loginTooltipText": ""])
    XCTAssertEqual(
      config.loginTooltipText,
      "",
      "Should use the given login tooltip text regardless of value"
    )
  }

  func testCreatingWithKnownLoginTooltipText() {
    config = Fixtures.config(withDictionary: ["loginTooltipText": "foo"])
    XCTAssertEqual(
      config.loginTooltipText,
      "foo",
      "Login tooltip text should be settable"
    )
  }

  func testCreatingWithoutTimestamp() {
    XCTAssertNil(config.timestamp, "Should not have a timestamp by default")
  }

  func testCreatingWithTimestamp() {
    let date = Date()
    config = Fixtures.config(withDictionary: ["timestamp": date])
    XCTAssertEqual(
      config.timestamp,
      date,
      "Should use the timestamp given during creation"
    )
  }

  func testCreatingWithDefaultSessionTimeoutInterval() {
    XCTAssertEqual(
      config.sessionTimoutInterval,
      60,
      "Should set the correct default timeout interval"
    )
  }

  func testCreatingWithSessionTimeoutInterval() {
    config = Fixtures.config(withDictionary: ["sessionTimeoutInterval": 200])
    XCTAssertEqual(
      config.sessionTimoutInterval,
      200,
      "Should set the session timeout interval from the remote"
    )
  }

  func testCreatingWithoutLoggingToken() {
    XCTAssertNil(
      config.loggingToken,
      "Should not provide a default for the logging token"
    )
  }

  func testCreatingWithEmptyLoggingToken() {
    config = Fixtures.config(withDictionary: ["loggingToken": ""])
    XCTAssertEqual(
      config.loggingToken,
      "",
      "Should use the logging token given during creation"
    )
  }

  func testCreatingWithKnownLoggingToken() {
    config = Fixtures.config(withDictionary: ["loggingToken": "foo"])
    XCTAssertEqual(
      config.loggingToken,
      "foo",
      "Should use the logging token given during creation"
    )
  }

  func testCreatingWithoutSmartLoginBookmarkUrl() {
    XCTAssertNil(
      config.smartLoginBookmarkIconURL,
      "Should not provide a default url for the smart login bookmark icon"
    )
  }

  func testCreatingWithInvalidSmartLoginBookmarkUrl() {
    config = Fixtures.config(withDictionary: ["smartLoginBookmarkIconURL": exampleURL])
    XCTAssertEqual(
      config.smartLoginBookmarkIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithValidSmartBookmarkUrl() {
    config = Fixtures.config(withDictionary: ["smartLoginBookmarkIconURL": exampleURL])
    XCTAssertEqual(
      config.smartLoginBookmarkIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithSmartLoginOptionsDefault() {
    XCTAssertEqual(
      config.smartLoginOptions,
      [],
      "Should default smart login options to unknown"
    )
  }

  func testCreatingWithSmartLoginOptionsEnabled() {
    config = Fixtures.config(
      withDictionary: ["smartLoginOptions": FBSDKServerConfigurationSmartLoginOptions.enabled.rawValue]
    )
    XCTAssertEqual(
      config.smartLoginOptions,
      FBSDKServerConfigurationSmartLoginOptions.enabled,
      "Should use the smartLoginOptions given during creation"
    )
  }

  func testCreatingWithoutErrorConfiguration() {
    XCTAssertNil(config.errorConfiguration, "Should not have an error configuration by default")
  }

  func testCreatingWithErrorConfiguration() {
    let errorConfig = ErrorConfiguration(dictionary: nil)
    config = Fixtures.config(withDictionary: ["errorConfiguration": errorConfig])

    XCTAssertEqual(
      config.errorConfiguration,
      errorConfig,
      "Error configuration should be settable"
    )
  }

  func testCreatingWithoutSmartLoginMenuUrl() {
    XCTAssertNil(
      config.smartLoginMenuIconURL,
      "Should not provide a default url for the smart login menu icon"
    )
  }

  func testCreatingWithInvalidSmartLoginMenuUrl() {
    config = Fixtures.config(withDictionary: ["smartLoginMenuIconURL": exampleURL])
    XCTAssertEqual(
      config.smartLoginMenuIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithValidSmartLoginMenuUrl() {
    config = Fixtures.config(withDictionary: ["smartLoginMenuIconURL": exampleURL])
    XCTAssertEqual(
      config.smartLoginMenuIconURL,
      exampleURL,
      "Should use the url given during creation"
    )
  }

  func testCreatingWithoutUpdateMessage() {
    XCTAssertNil(
      config.updateMessage,
      "Should not provide a default for the update message"
    )
  }

  func testCreatingWithEmptyUpdateMessage() {
    config = Fixtures.config(withDictionary: ["updateMessage": ""])
    XCTAssertEqual(
      config.updateMessage,
      "",
      "Should use the update message given during creation"
    )
  }

  func testCreatingWithKnownUpdateMessage() {
    config = Fixtures.config(withDictionary: ["updateMessage": "foo"])
    XCTAssertEqual(
      config.updateMessage,
      "foo",
      "Should use the update message given during creation"
    )
  }

  func testCreatingWithoutEventBindings() {
    XCTAssertNil(
      config.eventBindings,
      "Should not provide default event bindings"
    )
  }

  func testCreatingWithEmptyEventBindings() {
    config = Fixtures.config(withDictionary: ["eventBindings": []])
    XCTAssertNotNil(config.eventBindings, "Should use the empty list of event bindings it was created with")
    XCTAssertEqual(
      config.eventBindings?.isEmpty,
      true,
      "Should use the empty list of event bindings it was created with"
    )
  }

  func testCreatingWithEventBindings() {
    let bindings = [SampleEventBinding.createValid(withName: name)]
    config = Fixtures.config(withDictionary: ["eventBindings": bindings])

    XCTAssertEqual(
      config.eventBindings as? [EventBinding],
      bindings,
      "Event binding should be settable"
    )
  }

  func testCreatingWithoutDialogConfigurations() {
    XCTAssertNil(
      config.dialogConfigurations(),
      "Should not have dialog configurations by default"
    )
  }

  func testCreatingWithDialogConfigurations() {
    let dialogConfigurations = [
      "dialog": "Hello",
      "dialog2": "World"
    ]

    config = Fixtures.config(withDictionary: ["dialogConfigurations": dialogConfigurations])
    XCTAssertEqual(
      config.dialogConfigurations() as? [String: String],
      dialogConfigurations,
      "Should set the exact dialog configurations it was created with"
    )
  }

  func testCreatingWithoutDialogFlows() {
    // Need to recreate with a new appID to invalidate cache of default configuration
    config = ServerConfiguration.defaultServerConfiguration(forAppID: name)

    let expectedDefaultDialogFlows = [
      FBSDKDialogConfigurationNameDefault: [
        FBSDKDialogConfigurationFeatureUseNativeFlow: false,
        FBSDKDialogConfigurationFeatureUseSafariViewController: true
      ],
      FBSDKDialogConfigurationNameMessage: [
        FBSDKDialogConfigurationFeatureUseNativeFlow: true
      ]
    ]

    XCTAssertEqual(
      config.dialogFlows() as? [String: [String: Bool]],
      expectedDefaultDialogFlows,
      "Should use the expected default dialog flow"
    )
  }

  func testCreatingWithDialogFlows() {
    let dialogFlows = [
      "foo": [
        FBSDKDialogConfigurationFeatureUseNativeFlow: true,
        FBSDKDialogConfigurationFeatureUseSafariViewController: true
      ],
      "bar": [
        FBSDKDialogConfigurationFeatureUseNativeFlow: false
      ]
    ]

    config = Fixtures.config(withDictionary: ["dialogFlows": dialogFlows])

    XCTAssertEqual(
      config.dialogFlows() as? [String: [String: Bool]],
      dialogFlows,
      "Should set the exact dialog flows it was created with"
    )
  }

  func testCreatingWithoutAAMRules() {
    XCTAssertNil(
      config.aamRules,
      "Should not have aam rules by default"
    )
  }

  func testCreatingWithAAMRules() {
    let rules = ["foo": "bar"]

    config = Fixtures.config(withDictionary: ["aamRules": rules])

    XCTAssertEqual(
      config.aamRules as? [String: String],
      rules,
      "Should set the exact aam rules it was created with"
    )
  }

  func testCreatingWithoutRestrictiveParams() {
    XCTAssertNil(
      config.restrictiveParams,
      "Should not have restrictive params by default"
    )
  }

  func testCreatingWithRestrictiveParams() {
    let params = ["foo": "bar"]

    config = Fixtures.config(withDictionary: ["restrictiveParams": params])

    XCTAssertEqual(
      config.restrictiveParams as? [String: String],
      params,
      "Should set the exact restrictive params it was created with"
    )
  }

  func testCreatingWithoutSuggestedEventSetting() {
    XCTAssertNil(
      config.suggestedEventsSetting,
      "Should not have a suggested events setting by default"
    )
  }

  func testCreatingWithSuggestedEventSetting() {
    let setting = ["foo": "bar"]
    config = Fixtures.config(withDictionary: ["suggestedEventsSetting": setting])

    XCTAssertEqual(
      config.suggestedEventsSetting as? [String: String],
      setting,
      "Should set the exact suggested events setting it was created with"
    )
  }

  func testEncoding() { // swiftlint:disable:this function_body_length
    let coder = TestCoder()
    let errorConfig = ErrorConfiguration(dictionary: nil)

    config = Fixtures.config(withDictionary: [
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
      "errorConfiguration": errorConfig,
      "sessionTimeoutInterval": 100,
      "defaults": false,
      "loggingToken": "loggingToken",
      "smartLoginOptions": FBSDKServerConfigurationSmartLoginOptions.enabled.rawValue,
      "smartLoginBookmarkIconURL": exampleURL,
      "smartLoginMenuIconURL": exampleURL,
      "updateMessage": "updateMessage",
      "eventBindings": ["foo": "bar"],
      "restrictiveParams": ["restrictiveParams": "foo"],
      "AAMRules": ["AAMRules": "foo"],
      "suggestedEventsSetting": ["suggestedEventsSetting": "foo"],
    ])

    config.encode(with: coder)

    XCTAssertEqual(coder.encodedObject["appID"] as? String, config.appID)
    XCTAssertEqual(coder.encodedObject["appName"] as? String, config.appName)
    XCTAssertEqual(coder.encodedObject["loginTooltipEnabled"] as? Bool, config.isLoginTooltipEnabled)
    XCTAssertEqual(coder.encodedObject["loginTooltipText"] as? String, config.loginTooltipText)
    XCTAssertEqual(coder.encodedObject["defaultShareMode"] as? String, config.defaultShareMode)
    XCTAssertEqual(coder.encodedObject["advertisingIDEnabled"] as? Bool, config.isAdvertisingIDEnabled)
    XCTAssertEqual(coder.encodedObject["implicitLoggingEnabled"] as? Bool, config.isImplicitLoggingSupported)
    XCTAssertEqual(
      coder.encodedObject["implicitPurchaseLoggingEnabled"] as? Bool,
      config.isImplicitPurchaseLoggingSupported
    )
    XCTAssertEqual(coder.encodedObject["codelessEventsEnabled"] as? Bool, config.isCodelessEventsEnabled)
    XCTAssertEqual(coder.encodedObject["trackAppUninstallEnabled"] as? Bool, config.isUninstallTrackingEnabled)
    XCTAssertEqualDicts(coder.encodedObject["dialogFlows"] as? [String: Any], config.dialogFlows())
    XCTAssertEqual(coder.encodedObject["timestamp"] as? Date, config.timestamp)
    XCTAssertEqual(coder.encodedObject["errorConfigs"] as? ErrorConfiguration, config.errorConfiguration)
    XCTAssertEqual(coder.encodedObject["sessionTimeoutInterval"] as? TimeInterval, config.sessionTimoutInterval)
    XCTAssertNil(
      coder.encodedObject["defaults"],
      "Should not encode whether default values were used to create server configuration"
    )
    XCTAssertEqual(coder.encodedObject["loggingToken"] as? String, config.loggingToken)
    XCTAssertEqual(coder.encodedObject["smartLoginEnabled"] as? UInt, config.smartLoginOptions.rawValue)
    XCTAssertEqual(coder.encodedObject["smarstLoginBookmarkIconURL"] as? URL, config.smartLoginBookmarkIconURL)
    XCTAssertEqual(coder.encodedObject["smarstLoginBookmarkMenuURL"] as? URL, config.smartLoginMenuIconURL)
    XCTAssertEqual(coder.encodedObject["SDKUpdateMessage"] as? String, config.updateMessage)
    XCTAssertEqual(coder.encodedObject["eventBindings"] as? [EventBinding], config.eventBindings as? [EventBinding])
    XCTAssertEqualDicts(coder.encodedObject["restrictiveParams"] as? [String: Any], config.restrictiveParams)
    XCTAssertEqualDicts(coder.encodedObject["AAMRules"] as? [String: Any], config.aamRules)
    XCTAssertEqualDicts(coder.encodedObject["suggestedEventsSetting"] as? [String: Any], config.suggestedEventsSetting)
  }

  func testDecoding() throws { // swiftlint:disable:this function_body_length
    let decoder = TestCoder()
    config = try XCTUnwrap(ServerConfiguration(coder: decoder))

    let dialogFlowsClasses = NSSet(array: [
      NSDictionary.self,
      NSNumber.self,
      NSString.self,
    ])

    let dictionaryClasses = NSSet(array: [
      NSArray.self,
      NSData.self,
      NSDictionary.self,
      NSNumber.self,
      NSString.self,
    ])

    XCTAssertTrue(decoder.decodedObject["appID"] is NSString.Type)
    XCTAssertTrue(decoder.decodedObject["appName"] is NSString.Type)
    XCTAssertEqual(
      decoder.decodedObject["loginTooltipEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode loginTooltipEnabled as a Bool"
    )
    XCTAssertTrue(decoder.decodedObject["loginTooltipText"] is NSString.Type)
    XCTAssertTrue(decoder.decodedObject["defaultShareMode"] is NSString.Type)
    XCTAssertEqual(
      decoder.decodedObject["advertisingIDEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode advertisingIDEnabled as a Bool"
    )
    XCTAssertEqual(
      decoder.decodedObject["implicitLoggingEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode implicitLoggingEnabled as a Bool"
    )
    XCTAssertEqual(
      decoder.decodedObject["implicitPurchaseLoggingEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode implicitPurchaseLoggingEnabled as a Bool"
    )
    XCTAssertEqual(
      decoder.decodedObject["codelessEventsEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode codelessEventsEnabled as a Bool"
    )
    XCTAssertEqual(
      decoder.decodedObject["trackAppUninstallEnabled"] as? String,
      "decodeBoolForKey",
      "Should decode trackAppUninstallEnabled as a Bool"
    )
    XCTAssertEqual(decoder.decodedObject["dialogFlows"] as? NSSet, dialogFlowsClasses)
    XCTAssertTrue(decoder.decodedObject["timestamp"] is NSDate.Type)
    XCTAssertTrue(decoder.decodedObject["errorConfigs"] is ErrorConfiguration.Type)
    XCTAssertEqual(
      decoder.decodedObject["sessionTimeoutInterval"] as? String,
      "decodeDoubleForKey",
      "Should decode implicitLoggingEnabled as a Double"
    )
    XCTAssertNil(
      decoder.decodedObject["defaults"],
      "Should not encode whether default values were used to create server configuration"
    )
    XCTAssertTrue(decoder.decodedObject["loggingToken"] is NSString.Type)
    XCTAssertEqual(
      decoder.decodedObject["smartLoginEnabled"] as? String,
      "decodeIntegerForKey",
      "Should decode smartLoginEnabled as an integer"
    )
    XCTAssertTrue(decoder.decodedObject["smarstLoginBookmarkIconURL"] is NSURL.Type)
    XCTAssertTrue(decoder.decodedObject["smarstLoginBookmarkMenuURL"] is NSURL.Type)
    XCTAssertTrue(decoder.decodedObject["SDKUpdateMessage"] is NSString.Type)
    XCTAssertTrue(decoder.decodedObject["eventBindings"] is NSArray.Type)
    XCTAssertEqual(decoder.decodedObject["restrictiveParams"] as? NSSet, dictionaryClasses)
    XCTAssertEqual(decoder.decodedObject["AAMRules"] as? NSSet, dictionaryClasses)
    XCTAssertEqual(decoder.decodedObject["suggestedEventsSetting"] as? NSSet, dictionaryClasses)
  }

  func testRetrievingInvalidDialogConfigurationForDialogName() {
    config = Fixtures.config(withDictionary: [
      "dialogConfigurations": [
        "foo": "bar"
      ]
    ])

    XCTAssertEqual(
      config.dialogConfigurations()?["foo"] as? String,
      "bar",
      "Should be able to retrieve an invalid dialog configuration by name"
    )
  }

  func testRetrievingValidDialogConfigurationForDialogName() {
    let fooConfig = DialogConfiguration(
      name: "foo",
      url: exampleURL,
      appVersions: ["1", "2"]
    )

    config = Fixtures.config(withDictionary: [
      "dialogConfigurations": [
        "foo": fooConfig
      ]
    ])

    XCTAssertEqual(
      config.dialogConfiguration(forDialogName: "foo"),
      fooConfig,
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
        flowKey: featureValue
      ]
    }
    if sharingValue != nil {
      dialogFlows["sharing"] = [
        flowKey: sharingValue
      ]
    }
    if defaultValue != nil {
      dialogFlows["default"] = [
        flowKey: defaultValue
      ]
    }

    config = Fixtures.config(withDictionary: ["dialogFlows": dialogFlows ])
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
      config.useSafariViewController(forDialogName: name),
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
      config.useNativeDialog(forDialogName: name),
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
    if let lhs = lhs, let rhs = rhs {
      let dict1 = NSDictionary(dictionary: lhs)
      let dict2 = NSDictionary(dictionary: rhs)
      XCTAssertEqual(dict1, dict2, message(), file: file, line: line)
    } else if lhs == nil && rhs != nil {
      XCTFail("LHS Dict is nil", file: file, line: line)
    } else if lhs != nil && rhs == nil {
      XCTFail("RHS Dict is nil", file: file, line: line)
    }
  }
} // swiftlint:disable:this file_length
