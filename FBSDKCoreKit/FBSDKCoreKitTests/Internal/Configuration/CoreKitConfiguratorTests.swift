/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit
@testable import FBSDKCoreKit

import XCTest

final class CoreKitConfiguratorTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var components: CoreKitComponents!
  var configurator: CoreKitConfigurator!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    Self.resetTargets()

    components = TestCoreKitComponents.makeComponents()
    configurator = CoreKitConfigurator(components: components)
  }

  override func tearDown() {
    components = nil
    configurator = nil

    super.tearDown()
  }

  override class func tearDown() {
    resetTargets()
    super.tearDown()
  }

  private class func resetTargets() {
    AccessToken.resetClassDependencies()
    AppEvents.shared.reset()
    _AppEventsConfigurationManager.shared.resetDependencies()
    _AppEventsDeviceInfo.shared.resetDependencies()
    _AppEventsState.eventProcessors = nil
    _AppEventsUtility.shared.reset()
    AuthenticationToken.resetTokenCache()
    FBButton.resetClassDependencies()
    _GateKeeperManager.reset()
    GraphRequest.resetClassDependencies()
    GraphRequestConnection.resetClassDependencies()
    GraphRequestConnection.resetCanMakeRequests()
    ImpressionLoggingButton.resetClassDependencies()
    _InstrumentManager.reset()
    InternalUtility.reset()
    _ServerConfigurationManager.shared.reset()
    Settings.shared.reset()
    AEMReporter.reset()
    AppLinkNavigation.resetDependencies()
    AppLinkURL.reset()
    AppLinkUtility.reset()
    _AuthenticationStatusUtility.resetClassDependencies()
    _BridgeAPIRequest.resetClassDependencies()
    _CodelessIndexer.reset()
    _CrashShield.reset()
    FBWebDialogView.resetClassDependencies()
    _FeatureExtractor.reset()
    _ModelManager.reset()
    Profile.resetDependencies()
  }

  func testConfiguringAccessToken() {
    XCTAssertNil(
      AccessToken.tokenCache,
      "AccessToken should not have a token cache by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestConnectionFactory,
      "AccessToken should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestPiggybackManager,
      "AccessToken should not have a graph request piggyback manager by default"
    )
    XCTAssertNil(
      AccessToken.errorFactory,
      "AccessToken should not have an error factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AccessToken.tokenCache === components.tokenCache,
      "Should be configured with the token cache"
    )
    XCTAssertTrue(
      AccessToken.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "Should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      AccessToken.graphRequestPiggybackManager === components.piggybackManager,
      "Should be configured with the graph request piggyback manager"
    )
    XCTAssertIdentical(
      AccessToken.errorFactory,
      components.errorFactory,
      "Should be configured with the error factory"
    )
  }

  func testConfiguringAppEvents() {
    XCTAssertNil(
      AppEvents.shared.gateKeeperManager,
      "AppEvents should not have a gate keeper manager by default"
    )
    XCTAssertNil(
      AppEvents.shared.appEventsConfigurationProvider,
      "AppEvents should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      AppEvents.shared.serverConfigurationProvider,
      "AppEvents should not have a server configuration provider by default"
    )
    XCTAssertNil(
      AppEvents.shared.graphRequestFactory,
      "AppEvents should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppEvents.shared.featureChecker,
      "AppEvents should not have a feature checker by default"
    )
    XCTAssertNil(
      AppEvents.shared.primaryDataStore,
      "AppEvents should not have a primary data store by default"
    )
    XCTAssertNil(
      AppEvents.shared.logger,
      "AppEvents should not have a logger by default"
    )
    XCTAssertNil(
      AppEvents.shared.settings,
      "AppEvents should not have settings by default"
    )
    XCTAssertNil(
      AppEvents.shared.paymentObserver,
      "AppEvents should not have a payment observer by default"
    )
    XCTAssertNil(
      AppEvents.shared.timeSpentRecorder,
      "AppEvents should not have a time spent recorder by default"
    )
    XCTAssertNil(
      AppEvents.shared.appEventsStateStore,
      "AppEvents should not have an app events state store by default"
    )
    XCTAssertNil(
      AppEvents.shared.eventDeactivationParameterProcessor,
      "AppEvents should not have an event deactivation parameter processor by default"
    )
    XCTAssertNil(
      AppEvents.shared.restrictiveDataFilterParameterProcessor,
      "AppEvents should not have a restrictive data filter parameter processor by default"
    )
    XCTAssertNil(
      AppEvents.shared.atePublisherFactory,
      "AppEvents should not have an ATE publisher factory by default"
    )
    XCTAssertNil(
      AppEvents.shared.appEventsStateProvider,
      "AppEvents should not have an app events state provider by default"
    )
    XCTAssertNil(
      AppEvents.shared.advertiserIDProvider,
      "AppEvents should not have an advertiser ID provider by default"
    )
    XCTAssertNil(
      AppEvents.shared.userDataStore,
      "AppEvents should not have a user data store by default"
    )
    XCTAssertNil(
      AppEvents.shared.appEventsUtility,
      "AppEvents should not have an app events utility by default"
    )
    XCTAssertNil(
      AppEvents.shared.internalUtility,
      "AppEvents should not have an internal utility by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppEvents.shared.gateKeeperManager === components.gateKeeperManager,
      "AppEvents should be configured with the gate keeper manager"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsConfigurationProvider === components.appEventsConfigurationProvider,
      "AppEvents should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      AppEvents.shared.serverConfigurationProvider === components.serverConfigurationProvider,
      "AppEvents should be configured with the server configuration provider"
    )
    XCTAssertTrue(
      AppEvents.shared.graphRequestFactory === components.graphRequestFactory,
      "AppEvents should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppEvents.shared.featureChecker === components.featureChecker,
      "AppEvents should be configured with the feature checker"
    )
    XCTAssertTrue(
      AppEvents.shared.primaryDataStore === components.defaultDataStore,
      "AppEvents should be configured with the primary data store"
    )
    XCTAssertTrue(
      AppEvents.shared.logger === components.logger,
      "AppEvents should be configured with the logger"
    )
    XCTAssertTrue(
      AppEvents.shared.settings === components.settings,
      "AppEvents should be configured with the"
    )
    XCTAssertTrue(
      AppEvents.shared.paymentObserver === components.paymentObserver,
      "AppEvents should be configured with the payment observer"
    )
    XCTAssertTrue(
      AppEvents.shared.timeSpentRecorder === components.timeSpentRecorder,
      "AppEvents should be configured with the time spent recorder"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsStateStore === components.appEventsStateStore,
      "AppEvents should be configured with the app events state store"
    )
    XCTAssertTrue(
      AppEvents.shared.eventDeactivationParameterProcessor === components.eventDeactivationManager,
      "AppEvents should be configured with the event deactivation parameter processor"
    )
    XCTAssertTrue(
      AppEvents.shared.restrictiveDataFilterParameterProcessor === components.restrictiveDataFilterManager,
      "AppEvents should be configured with the restrictive data filter parameter processor"
    )
    XCTAssertTrue(
      AppEvents.shared.atePublisherFactory === components.atePublisherFactory,
      "AppEvents should be configured with the ATE publisher factory"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsStateProvider === components.appEventsStateProvider,
      "AppEvents should be configured with the app events state provider"
    )
    XCTAssertTrue(
      AppEvents.shared.advertiserIDProvider === components.advertiserIDProvider,
      "AppEvents should be configured with the advertiser ID provider"
    )
    XCTAssertTrue(
      AppEvents.shared.userDataStore === components.userDataStore,
      "AppEvents should be configured with the user data store"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsUtility === components.appEventsUtility,
      "AppEvents should be configured with the app events utility"
    )
    XCTAssertTrue(
      AppEvents.shared.internalUtility === components.internalUtility,
      "AppEvents should be configured with the internal utility"
    )
  }

  func testConfiguringNonTVAppEvents() {
    XCTAssertNil(
      AppEvents.shared.onDeviceMLModelManager,
      "AppEvents should not have an on-device ML model manager by default"
    )
    XCTAssertNil(
      AppEvents.shared.metadataIndexer,
      "AppEvents should not have a metadata indexer by default"
    )
    XCTAssertNil(
      AppEvents.shared.skAdNetworkReporter,
      "AppEvents should not have a StoreKit ad network reporter by default"
    )
    XCTAssertNil(
      AppEvents.shared.codelessIndexer,
      "AppEvents should not have a codeless indexer by default"
    )
    XCTAssertNil(
      AppEvents.shared.swizzler,
      "AppEvents should not have a swizzler by default"
    )
    XCTAssertNil(
      AppEvents.shared.aemReporter,
      "AppEvents should not have an AEM reporter by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppEvents.shared.onDeviceMLModelManager === components.modelManager,
      "AppEvents should be configured with the on-device ML model manager"
    )
    XCTAssertTrue(
      AppEvents.shared.metadataIndexer === components.metadataIndexer,
      "AppEvents should be configured with the metadata indexer"
    )
    XCTAssertTrue(
      AppEvents.shared.skAdNetworkReporter === components.skAdNetworkReporter,
      "AppEvents should be configured with StoreKit ad network reporter"
    )
    XCTAssertTrue(
      AppEvents.shared.codelessIndexer === components.codelessIndexer,
      "AppEvents should be configured with the codeless indexer"
    )
    XCTAssertTrue(
      AppEvents.shared.swizzler === components.swizzler,
      "AppEvents should be configured with the swizzler"
    )
    XCTAssertTrue(
      AppEvents.shared.aemReporter === components.aemReporter,
      "AppEvents should be configured with the AEM reporter"
    )
  }

  func testConfiguringAppEventsConfigurationManager() {
    XCTAssertNil(
      _AppEventsConfigurationManager.shared.store,
      "_AppEventsConfigurationManager should not have a default data store by default"
    )
    XCTAssertNil(
      _AppEventsConfigurationManager.shared.settings,
      "_AppEventsConfigurationManager should not have settings by default"
    )
    XCTAssertNil(
      _AppEventsConfigurationManager.shared.graphRequestFactory,
      "_AppEventsConfigurationManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      _AppEventsConfigurationManager.shared.graphRequestConnectionFactory,
      "_AppEventsConfigurationManager should not have a graph request connection factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _AppEventsConfigurationManager.shared.store === components.defaultDataStore,
      "_AppEventsConfigurationManager should be configured with the default data store"
    )
    XCTAssertTrue(
      _AppEventsConfigurationManager.shared.settings === components.settings,
      "_AppEventsConfigurationManager should be configured with the settings"
    )
    XCTAssertTrue(
      _AppEventsConfigurationManager.shared.graphRequestFactory === components.graphRequestFactory,
      "_AppEventsConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      _AppEventsConfigurationManager.shared.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "_AppEventsConfigurationManager should be configured with the graph request connection factory"
    )
  }

  func testConfiguringAppEventsDeviceInfo() throws {
    XCTAssertNil(
      _AppEventsDeviceInfo.shared.settings,
      "_AppEventsDeviceInfo should not have settings by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _AppEventsDeviceInfo.shared.settings === components.settings,
      "_AppEventsDeviceInfo should be configured with the settings"
    )
  }

  func testConfiguringAppEventsState() throws {
    XCTAssertNil(
      _AppEventsState.eventProcessors,
      "_AppEventsState should not have event processors by default"
    )

    configurator.performConfiguration()

    let processors = try XCTUnwrap(
      _AppEventsState.eventProcessors,
      "_AppEventsState's event processors should be configured"
    )
    XCTAssertEqual(processors.count, 2, "_AppEventsState should have two event processors")
    XCTAssertTrue(
      processors.first === components.eventDeactivationManager,
      "_AppEventsState's event processors should be configured with the event deactivation manager"
    )
    XCTAssertTrue(
      processors.last === components.restrictiveDataFilterManager,
      "_AppEventsState's event processors should be configured with the restrictive data filter manager"
    )
  }

  func testConfiguringAppEventsUtility() {
    XCTAssertNil(
      _AppEventsUtility.shared.appEventsConfigurationProvider,
      "_AppEventsUtility should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      _AppEventsUtility.shared.deviceInformationProvider,
      "_AppEventsUtility should not have a device information provider by default"
    )
    XCTAssertNil(
      _AppEventsUtility.shared.settings,
      "_AppEventsUtility should not have settings by default"
    )
    XCTAssertNil(
      _AppEventsUtility.shared.internalUtility,
      "_AppEventsUtility should not have an internal utility by default"
    )
    XCTAssertNil(
      _AppEventsUtility.shared.errorFactory,
      "_AppEventsUtility should not have an error factory by default"
    )
    XCTAssertNil(
      _AppEventsUtility.shared.dataStore,
      "_AppEventsUtility should not have an data store by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _AppEventsUtility.shared.appEventsConfigurationProvider === components.appEventsConfigurationProvider,
      "_AppEventsUtility should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      _AppEventsUtility.shared.deviceInformationProvider === components.deviceInformationProvider,
      "_AppEventsUtility should be configured with the device information provider"
    )
    XCTAssertTrue(
      _AppEventsUtility.shared.settings === components.settings,
      "_AppEventsUtility should be configured with the settings"
    )
    XCTAssertTrue(
      _AppEventsUtility.shared.internalUtility === components.internalUtility,
      "_AppEventsUtility should be configured with the internal utility"
    )
    XCTAssertIdentical(
      _AppEventsUtility.shared.errorFactory,
      components.errorFactory,
      "_AppEventsUtility should be configured with the error factory"
    )
    XCTAssertTrue(
      _AppEventsUtility.shared.dataStore === components.defaultDataStore,
      "_AppEventsUtility should be configured with the data store"
    )
  }

  func testConfiguringAuthenticationToken() {
    XCTAssertNil(
      AuthenticationToken.tokenCache,
      "AuthenticationToken should not have a token cache by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AuthenticationToken.tokenCache === components.tokenCache,
      "AuthenticationToken should be configured with the token cache"
    )
  }

  func testConfiguringButton() {
    XCTAssertNil(
      FBButton.applicationActivationNotifier,
      "Button should not have an application activation notifier by default"
    )
    XCTAssertNil(
      FBButton.eventLogger,
      "Button should not have an event logger by default"
    )
    XCTAssertNil(
      FBButton.accessTokenProvider,
      "Button should not have an access token provider by default"
    )

    configurator.performConfiguration()

    XCTAssertIdentical(
      FBButton.applicationActivationNotifier as AnyObject,
      components.getApplicationActivationNotifier() as AnyObject,
      "Button should be configured with the application activation notifier"
    )
    XCTAssertTrue(
      FBButton.eventLogger === components.eventLogger,
      "Button should be configured with the expected concrete app events"
    )
    XCTAssertTrue(
      FBButton.accessTokenProvider === components.accessTokenWallet,
      "Button should be configured with the expected concrete access token provider"
    )
  }

  func testConfiguringGateKeeperManager() {
    XCTAssertNil(
      _GateKeeperManager.settings,
      "_GateKeeperManager should not have settings by default"
    )
    XCTAssertNil(
      _GateKeeperManager.graphRequestFactory,
      "_GateKeeperManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      _GateKeeperManager.graphRequestConnectionFactory,
      "_GateKeeperManager should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      _GateKeeperManager.store,
      "_GateKeeperManager should not have a data store by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _GateKeeperManager.settings === components.settings,
      "_GateKeeperManager should be configured with the settings"
    )
    XCTAssertTrue(
      _GateKeeperManager.graphRequestFactory === components.graphRequestFactory,
      "_GateKeeperManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      _GateKeeperManager.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "_GateKeeperManager should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      _GateKeeperManager.store === components.defaultDataStore,
      "_GateKeeperManager should be configured with the data store"
    )
  }

  func testConfiguringGraphRequest() {
    XCTAssertNil(
      GraphRequest.settings,
      "GraphRequest should not have settings by default"
    )
    XCTAssertNil(
      GraphRequest.accessTokenProvider,
      "GraphRequest should not have an access token provider by default"
    )
    XCTAssertNil(
      GraphRequest.graphRequestConnectionFactory,
      "GraphRequest should not have a connection factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      GraphRequest.settings === components.settings,
      "GraphRequest should be configured with the settings"
    )
    XCTAssertTrue(
      GraphRequest.accessTokenProvider === components.accessTokenWallet,
      "GraphRequest should be configured with the access token wallet"
    )
    XCTAssertTrue(
      GraphRequest.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "GraphRequest should be configured with the connection factory"
    )
  }

  func testConfiguringGraphRequestConnection() {
    XCTAssertNil(
      GraphRequestConnection.sessionProxyFactory,
      "GraphRequestConnection should not have a session provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.errorConfigurationProvider,
      "GraphRequestConnection should not have an error configuration provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.piggybackManager,
      "GraphRequestConnection should not have a piggyback manager by default"
    )
    XCTAssertNil(
      GraphRequestConnection.settings,
      "GraphRequestConnection should not have settings type by default"
    )
    XCTAssertNil(
      GraphRequestConnection.graphRequestConnectionFactory,
      "GraphRequestConnection should not have a connection factory by default"
    )
    XCTAssertNil(
      GraphRequestConnection.eventLogger,
      "GraphRequestConnection should not have an event logger by default"
    )
    XCTAssertNil(
      GraphRequestConnection.operatingSystemVersionComparer,
      "GraphRequestConnection should not have an operating system version comparer by default"
    )
    XCTAssertNil(
      GraphRequestConnection.macCatalystDeterminator,
      "GraphRequestConnection should not have a Mac Catalyst determinator by default"
    )
    XCTAssertNil(
      GraphRequestConnection.accessTokenProvider,
      "GraphRequestConnection should not have an access token provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.errorFactory,
      "GraphRequestConnection should not have an error factory by default"
    )
    XCTAssertNil(
      GraphRequestConnection.authenticationTokenProvider,
      "GraphRequestConnection should not have an authentication token provider by default"
    )

    XCTAssertFalse(
      GraphRequestConnection.canMakeRequests,
      "GraphRequestConnection should not be able to make requests by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      GraphRequestConnection.sessionProxyFactory === components.urlSessionProxyFactory,
      "GraphRequestConnection should be configured with the concrete session provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorConfigurationProvider === components.errorConfigurationProvider,
      "GraphRequestConnection should be configured with the error configuration provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.piggybackManager === components.piggybackManager,
      "GraphRequestConnection should be configured with the piggyback manager provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.settings === components.settings,
      "GraphRequestConnection should be configured with the settings type"
    )
    XCTAssertTrue(
      GraphRequestConnection.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "GraphRequestConnection should be configured with the connection factory"
    )
    XCTAssertTrue(
      GraphRequestConnection.eventLogger === components.eventLogger,
      "GraphRequestConnection should be configured with the event logger"
    )
    XCTAssertTrue(
      GraphRequestConnection.operatingSystemVersionComparer === components.operatingSystemVersionComparer,
      "GraphRequestConnection should be configured with the operating system version comparer"
    )
    XCTAssertTrue(
      GraphRequestConnection.macCatalystDeterminator === components.macCatalystDeterminator,
      "GraphRequestConnection should be configured with the Mac Catalyst determinator"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenProvider === components.accessTokenWallet,
      "GraphRequestConnection should be configured with the access token provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorFactory === components.errorFactory,
      "GraphRequestConnection should be configured with the error factory"
    )
    XCTAssertTrue(
      GraphRequestConnection.authenticationTokenProvider === components.authenticationTokenWallet,
      "GraphRequestConnection should be configured with the authentication token provider"
    )

    XCTAssertTrue(
      GraphRequestConnection.canMakeRequests,
      "GraphRequestConnection should be configured to be able to make requests"
    )
  }

  func testConfiguringImpressionLoggingButton() throws {
    XCTAssertNil(
      ImpressionLoggingButton.impressionLoggerFactory,
      "ImpressionLoggingButton should not have an impression logger factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      ImpressionLoggingButton.impressionLoggerFactory === components.impressionLoggerFactory,
      "ImpressionLoggingButton should be configured with the impression logger factory"
    )
  }

  func testConfiguringInstrumentManager() {
    XCTAssertNil(
      _InstrumentManager.shared.crashObserver,
      "_InstrumentManager should not have a crash observer by default"
    )
    XCTAssertNil(
      _InstrumentManager.shared.featureChecker,
      "_InstrumentManager should not have a feature checker by default"
    )
    XCTAssertNil(
      _InstrumentManager.shared.settings,
      "_InstrumentManager should not have settings by default"
    )
    XCTAssertNil(
      _InstrumentManager.shared.errorReporter,
      "_InstrumentManager should not have an error reporter by default"
    )
    XCTAssertNil(
      _InstrumentManager.shared.crashHandler,
      "_InstrumentManager should not have a crash handler by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _InstrumentManager.shared.crashObserver === components.crashObserver,
      "_InstrumentManager should be configured with the crash observer"
    )
    XCTAssertTrue(
      _InstrumentManager.shared.featureChecker === components.featureChecker,
      "_InstrumentManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      _InstrumentManager.shared.settings === components.settings,
      "_InstrumentManager should be configured with the settings"
    )
    XCTAssertTrue(
      _InstrumentManager.shared.errorReporter === components.errorReporter,
      "_InstrumentManager should be configured with the error reporter"
    )
    XCTAssertTrue(
      _InstrumentManager.shared.crashHandler === components.crashHandler,
      "_InstrumentManager should be configured with the crash handler"
    )
  }

  func testConfiguringInternalUtility() {
    XCTAssertNil(
      InternalUtility.shared.infoDictionaryProvider,
      "InternalUtility should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      InternalUtility.shared.loggerFactory,
      "InternalUtility should not have a logger factory by default"
    )
    XCTAssertNil(
      InternalUtility.shared.settings,
      "InternalUtility should not have settings by default"
    )
    XCTAssertNil(
      InternalUtility.shared.errorFactory,
      "InternalUtility should not have an error factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === components.infoDictionaryProvider,
      "InternalUtility should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      InternalUtility.shared.loggerFactory === components.loggerFactory,
      "InternalUtility should be configured with the logger factory"
    )
    XCTAssertTrue(
      InternalUtility.shared.settings === components.settings,
      "InternalUtility should be configured with the settings"
    )
    XCTAssertIdentical(
      InternalUtility.shared.errorFactory,
      components.errorFactory,
      "InternalUtility should be configured with the error factory"
    )
  }

  func testConfiguringServerConfigurationManager() {
    XCTAssertNil(
      _ServerConfigurationManager.shared.graphRequestFactory,
      "_ServerConfigurationManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      _ServerConfigurationManager.shared.graphRequestConnectionFactory,
      "_ServerConfigurationManager should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      _ServerConfigurationManager.shared.dialogConfigurationMapBuilder,
      "_ServerConfigurationManager should not have a dialog configuration map builder by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _ServerConfigurationManager.shared.graphRequestFactory === components.graphRequestFactory,
      "_ServerConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      _ServerConfigurationManager.shared.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "_ServerConfigurationManager should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      _ServerConfigurationManager.shared.dialogConfigurationMapBuilder === components.dialogConfigurationMapBuilder,
      "_ServerConfigurationManager should be configured with the dialog configuration map builder"
    )
  }

  func testConfiguringSettings() throws {
    configurator.performConfiguration()

    let dependencies = try Settings.shared.getDependencies()

    XCTAssertIdentical(
      dependencies.dataStore,
      components.defaultDataStore,
      "Settings should be configured with the data store"
    )
    XCTAssertIdentical(
      dependencies.appEventsConfigurationProvider,
      components.appEventsConfigurationProvider,
      "Settings should be configured with the app events configuration provider"
    )
    XCTAssertIdentical(
      dependencies.infoDictionaryProvider,
      components.infoDictionaryProvider,
      "Settings should be configured with the info dictionary provider"
    )
    XCTAssertIdentical(
      dependencies.eventLogger,
      components.eventLogger,
      "Settings should be configured with the event logger"
    )
  }

  @available(iOS 14.0, *)
  func testConfiguringAEMReporter() {
    XCTAssertNil(
      AEMReporter.networker,
      "AEMReporter should not have an AEM networker by default"
    )
    XCTAssertNil(
      AEMReporter.appID,
      "AEMReporter should not have an app ID by default"
    )
    XCTAssertNil(
      AEMReporter.reporter,
      "AEMReporter should not have an SKAdNetwork reporter by default"
    )

    components.settings.appID = "sample"
    configurator.performConfiguration()

    XCTAssertTrue(
      AEMReporter.networker === components.aemNetworker,
      "AEMReporter should be configured with the AEM networker"
    )
    XCTAssertEqual(
      AEMReporter.appID,
      components.settings.appID,
      "AEMReporter should be configured with the settings' app ID"
    )
    XCTAssertTrue(
      AEMReporter.reporter === components.skAdNetworkReporter,
      "AEMReporter should be configured with the SKAdNetwork reporter"
    )
  }

  func testConfiguringAppLinkNavigation() {

    configurator.performConfiguration()

    XCTAssertTrue(
      AppLinkNavigation.settings === components.settings,
      "AppLinkNavigation should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkNavigation.urlOpener === components.internalURLOpener,
      "AppLinkNavigation should be configured with the internal URL opener"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkEventPoster === components.appLinkEventPoster,
      "AppLinkNavigation should be configured with the app link event poster"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkResolver === components.appLinkResolver,
      "AppLinkNavigation should be configured with the app link resolver"
    )
  }

  func testConfiguringAppLinkURL() {
    XCTAssertNil(
      AppLinkURL.settings,
      "AppLinkURL should not have settings by default"
    )
    XCTAssertNil(
      AppLinkURL.appLinkFactory,
      "AppLinkURL should not have an app link factory by default"
    )
    XCTAssertNil(
      AppLinkURL.appLinkTargetFactory,
      "AppLinkURL should not have an app link target factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppLinkURL.settings === components.settings,
      "AppLinkURL should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkFactory === components.appLinkFactory,
      "AppLinkURL should be configured with the app link factory"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkTargetFactory === components.appLinkTargetFactory,
      "AppLinkURL should be configured with the app link target factory"
    )
  }

  func testConfiguringAppLinkUtility() {
    XCTAssertNil(
      AppLinkUtility.graphRequestFactory,
      "AppLinkUtility should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppLinkUtility.infoDictionaryProvider,
      "AppLinkUtility should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.settings,
      "AppLinkUtility should not have settings by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventsConfigurationProvider,
      "AppLinkUtility should not have an app events configuration manager by default"
    )
    XCTAssertNil(
      AppLinkUtility.advertiserIDProvider,
      "AppLinkUtility should not have an advertiser ID provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventsDropDeterminer,
      "AppLinkUtility should not have an app events drop determiner by default"
    )
    XCTAssertNil(
      AppLinkUtility.appEventParametersExtractor,
      "AppLinkUtility should not have an app events parameter extractor by default"
    )
    XCTAssertNil(
      AppLinkUtility.appLinkURLFactory,
      "AppLinkUtility should not have an app link URL factory by default"
    )
    XCTAssertNil(
      AppLinkUtility.userIDProvider,
      "AppLinkUtility should not have a user ID provider by default"
    )
    XCTAssertNil(
      AppLinkUtility.userDataStore,
      "AppLinkUtility should not have a user data store by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppLinkUtility.graphRequestFactory === components.graphRequestFactory,
      "AppLinkUtility should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppLinkUtility.infoDictionaryProvider === components.infoDictionaryProvider,
      "AppLinkUtility should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      AppLinkUtility.settings === components.settings,
      "AppLinkUtility should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsConfigurationProvider === components.appEventsConfigurationProvider,
      "AppLinkUtility should be configured with the app events configuration manager"
    )
    XCTAssertTrue(
      AppLinkUtility.advertiserIDProvider === components.advertiserIDProvider,
      "AppLinkUtility should be configured with the advertiser ID provider"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsDropDeterminer === components.appEventsDropDeterminer,
      "AppLinkUtility should be configured with the app events drop determiner"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventParametersExtractor === components.appEventParametersExtractor,
      "AppLinkUtility should be configured with the app events parameter extractor"
    )
    XCTAssertTrue(
      AppLinkUtility.appLinkURLFactory === components.appLinkURLFactory,
      "AppLinkUtility should be configured with the app link URL factory"
    )
    XCTAssertTrue(
      AppLinkUtility.userIDProvider === components.userIDProvider,
      "AppLinkUtility should be configured with the user ID provider"
    )
    XCTAssertTrue(
      AppLinkUtility.userDataStore === components.userDataStore,
      "AppLinkUtility should be configured with the user data store"
    )
  }

  func testConfiguringAuthenticationStatusUtility() {
    XCTAssertNil(
      _AuthenticationStatusUtility.profileSetter,
      "_AuthenticationStatusUtility should not have a profile setter by default"
    )
    XCTAssertNil(
      _AuthenticationStatusUtility.sessionDataTaskProvider,
      "_AuthenticationStatusUtility should not have a session data task provider by default"
    )
    XCTAssertNil(
      _AuthenticationStatusUtility.accessTokenWallet,
      "_AuthenticationStatusUtility should not have an access token by default"
    )
    XCTAssertNil(
      _AuthenticationStatusUtility.authenticationTokenWallet,
      "_AuthenticationStatusUtility should not have an authentication token by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _AuthenticationStatusUtility.profileSetter === components.profileSetter,
      "_AuthenticationStatusUtility should be configured with the profile setter"
    )
    XCTAssertTrue(
      _AuthenticationStatusUtility.sessionDataTaskProvider === components.sessionDataTaskProvider,
      "_AuthenticationStatusUtility should be configured with the session data task provider"
    )
    XCTAssertTrue(
      _AuthenticationStatusUtility.accessTokenWallet === components.accessTokenWallet,
      "_AuthenticationStatusUtility should be configured with the access token"
    )
    XCTAssertTrue(
      _AuthenticationStatusUtility.authenticationTokenWallet === components.authenticationTokenWallet,
      "_AuthenticationStatusUtility should be configured with the authentication token"
    )
  }

  func testConfiguringBridgeAPIRequest() {
    XCTAssertNil(
      _BridgeAPIRequest.internalURLOpener,
      "_BridgeAPIRequest should not have an internal URL openenr by default"
    )
    XCTAssertNil(
      _BridgeAPIRequest.internalUtility,
      "_BridgeAPIRequest should not have an internal utility by default"
    )
    XCTAssertNil(
      _BridgeAPIRequest.settings,
      "_BridgeAPIRequest should not have settings by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _BridgeAPIRequest.internalURLOpener === components.internalURLOpener,
      "_BridgeAPIRequest should be configured with the internal URL opener"
    )
    XCTAssertTrue(
      _BridgeAPIRequest.internalUtility === components.internalUtility,
      "_BridgeAPIRequest should be configured with the internal utility"
    )
    XCTAssertTrue(
      _BridgeAPIRequest.settings === components.settings,
      "_BridgeAPIRequest should be configured with the settings"
    )
  }

  func testConfiguringCodelessIndexer() {
    XCTAssertNil(
      _CodelessIndexer.graphRequestFactory,
      "_CodelessIndexer should not have a graph request factory by default"
    )
    XCTAssertNil(
      _CodelessIndexer.serverConfigurationProvider,
      "_CodelessIndexer should not have a server configuration provider by default"
    )
    XCTAssertNil(
      _CodelessIndexer.dataStore,
      "_CodelessIndexer should be not have a data store by default"
    )
    XCTAssertNil(
      _CodelessIndexer.graphRequestConnectionFactory,
      "_CodelessIndexer should not have a graph request connection provider by default"
    )
    XCTAssertNil(
      _CodelessIndexer.swizzler,
      "_CodelessIndexer should not have a swizzler by default"
    )
    XCTAssertNil(
      _CodelessIndexer.settings,
      "_CodelessIndexer should not have settings by default"
    )
    XCTAssertNil(
      _CodelessIndexer.advertiserIDProvider,
      "_CodelessIndexer should not have an advertiser ID provider by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _CodelessIndexer.graphRequestFactory === components.graphRequestFactory,
      "_CodelessIndexer should be configured with the graph request factory"
    )
    XCTAssertTrue(
      _CodelessIndexer.serverConfigurationProvider === components.serverConfigurationProvider,
      "_CodelessIndexer should be configured with the server configuration provider"
    )
    XCTAssertTrue(
      _CodelessIndexer.dataStore === components.defaultDataStore,
      "Should be configured with the default data store"
    )
    XCTAssertTrue(
      _CodelessIndexer.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "_CodelessIndexer should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      _CodelessIndexer.swizzler === components.swizzler,
      "_CodelessIndexer should be configured with the swizzler"
    )
    XCTAssertTrue(
      _CodelessIndexer.settings === components.settings,
      "_CodelessIndexer should be configured with the settings"
    )
    XCTAssertTrue(
      _CodelessIndexer.advertiserIDProvider === components.advertiserIDProvider,
      "_CodelessIndexer should be configured with the advertiser ID provider"
    )
  }

  func testConfiguringCrashShield() {
    XCTAssertNil(
      _CrashShield.settings,
      "_CrashShield should not have settings by default"
    )
    XCTAssertNil(
      _CrashShield.graphRequestFactory,
      "_CrashShield should not have a graph request factory by default"
    )
    XCTAssertNil(
      _CrashShield.featureChecking,
      "_CrashShield should not have a feature checker by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _CrashShield.settings === components.settings,
      "_CrashShield should be configured with the settings"
    )
    XCTAssertTrue(
      _CrashShield.graphRequestFactory === components.graphRequestFactory,
      "_CrashShield should be configured with the graph request factory"
    )
    XCTAssertTrue(
      _CrashShield.featureChecking === components.featureChecker,
      "_CrashShield should be configured with the feature checker"
    )
  }

  func testConfiguringFeatureExtractor() {
    XCTAssertNil(
      _FeatureExtractor.rulesFromKeyProvider,
      "_FeatureExtractor should not have a web view provider by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      _FeatureExtractor.rulesFromKeyProvider === components.rulesFromKeyProvider,
      "_FeatureExtractor should be configured with the web view provider"
    )
  }

  func testConfiguringModelManager() throws {
    XCTAssertNil(
      _ModelManager.shared.featureChecker,
      "_ModelManager should not have a feature checker by default"
    )
    XCTAssertNil(
      _ModelManager.shared.graphRequestFactory,
      "_ModelManager should not have a request factory by default"
    )
    XCTAssertNil(
      _ModelManager.shared.fileManager,
      "_ModelManager should not have a file manager by default"
    )
    XCTAssertNil(
      _ModelManager.shared.store,
      "_ModelManager should not have a data store by default"
    )
    XCTAssertNil(
      _ModelManager.shared.getAppID,
      "_ModelManager should not have an app ID computer by default"
    )
    XCTAssertNil(
      _ModelManager.shared.dataExtractor,
      "_ModelManager should not have a data extractor by default"
    )
    XCTAssertNil(
      _ModelManager.shared.gateKeeperManager,
      "_ModelManager should not have a gate keeper manager by default"
    )
    XCTAssertNil(
      _ModelManager.shared.suggestedEventsIndexer,
      "_ModelManager should not have a suggested events indexer by default"
    )
    XCTAssertNil(
      _ModelManager.shared.featureExtractor,
      "_ModelManager should not have a feature extractor by default"
    )

    let testSettings = try XCTUnwrap(components.settings as? TestSettings)
    testSettings.appID = "test-app-id"

    configurator.performConfiguration()

    XCTAssertTrue(
      _ModelManager.shared.featureChecker === components.featureChecker,
      "_ModelManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      _ModelManager.shared.graphRequestFactory === components.graphRequestFactory,
      "_ModelManager should be configured with the request factory"
    )
    XCTAssertTrue(
      _ModelManager.shared.fileManager === components.fileManager,
      "_ModelManager should be configured with the file manager"
    )
    XCTAssertTrue(
      _ModelManager.shared.store === components.defaultDataStore,
      "_ModelManager should be configured with the default data store"
    )
    XCTAssertEqual(
      _ModelManager.shared.getAppID?(),
      "test-app-id",
      "_ModelManager should be configured with an app ID computer"
    )
    XCTAssertTrue(
      _ModelManager.shared.dataExtractor === components.dataExtractor,
      "_ModelManager should be configured with the data extractor"
    )
    XCTAssertTrue(
      _ModelManager.shared.gateKeeperManager === components.gateKeeperManager,
      "_ModelManager should be configured with the gate keeper manager"
    )
    XCTAssertTrue(
      _ModelManager.shared.featureExtractor === components.featureExtractor,
      "_ModelManager should be configured with the feature extractor"
    )
  }

  func testConfiguringProfile() throws {
    configurator.performConfiguration()
    let dependencies = try Profile.getDependencies()

    XCTAssertIdentical(
      dependencies.accessTokenProvider as AnyObject,
      components.accessTokenWallet,
      "Profile should be configured with the access token wallet"
    )
    XCTAssertIdentical(
      dependencies.dataStore as AnyObject,
      components.defaultDataStore,
      "Profile should be configured with the default data store"
    )
    XCTAssertIdentical(
      dependencies.graphRequestFactory as AnyObject,
      components.graphRequestFactory,
      "Profile should be configured with the graph request factory"
    )
    XCTAssertIdentical(
      dependencies.notificationCenter as AnyObject,
      components.notificationCenter,
      "Profile should be configured with the notification center"
    )
    XCTAssertIdentical(
      dependencies.settings as AnyObject,
      components.settings,
      "Profile should be configured with the settings"
    )
    XCTAssertIdentical(
      dependencies.urlHoster as AnyObject,
      components.urlHoster,
      "Profile should be configured with the URL hoster"
    )
  }

  func testConfiguringWebDialogView() {
    XCTAssertNil(
      FBWebDialogView.webViewProvider,
      "FBWebDialogView should not have a web view factory by default"
    )
    XCTAssertNil(
      FBWebDialogView.urlOpener,
      "FBWebDialogView should not have an internal URL opener by default"
    )
    XCTAssertNil(
      FBWebDialogView.errorFactory,
      "FBWebDialogView should not have an error factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      FBWebDialogView.webViewProvider === components.webViewProvider,
      "FBWebDialogView should be configured with the web view factory"
    )
    XCTAssertTrue(
      FBWebDialogView.urlOpener === components.internalURLOpener,
      "FBWebDialogView should be configured with the internal URL opener"
    )
    XCTAssertIdentical(
      FBWebDialogView.errorFactory,
      components.errorFactory,
      "FBWebDialogView should be configured with the error factory"
    )
  }
}
