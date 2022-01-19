/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
    AppEventsConfigurationManager.shared.resetDependencies()
    AppEventsDeviceInfo.shared.resetDependencies()
    AppEventsState.eventProcessors = nil
    AppEventsUtility.shared.reset()
    AuthenticationToken.resetTokenCache()
    FBButton.resetClassDependencies()
    ErrorFactory.resetClassDependencies()
    FeatureManager.shared.resetDependencies()
    GateKeeperManager.reset()
    GraphRequest.resetClassDependencies()
    GraphRequestConnection.resetClassDependencies()
    GraphRequestConnection.resetCanMakeRequests()
    ImpressionLoggingButton.resetClassDependencies()
    InstrumentManager.reset()
    InternalUtility.reset()
    ServerConfigurationManager.shared.reset()
    Settings.shared.reset()

    // Non-tvOS
    AEMReporter.reset()
    AppLinkNavigation.reset()
    AppLinkURL.reset()
    AppLinkUtility.reset()
    AuthenticationStatusUtility.resetClassDependencies()
    BridgeAPIRequest.resetClassDependencies()
    CodelessIndexer.reset()
    CrashShield.reset()
    FBWebDialogView.resetClassDependencies()
    FeatureExtractor.reset()
    ModelManager.reset()
    Profile.reset()
  }

  // MARK: - All Platforms

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
      AppEventsConfigurationManager.shared.store,
      "AppEventsConfigurationManager should not have a default data store by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.settings,
      "AppEventsConfigurationManager should not have settings by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.graphRequestFactory,
      "AppEventsConfigurationManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory,
      "AppEventsConfigurationManager should not have a graph request connection factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppEventsConfigurationManager.shared.store === components.defaultDataStore,
      "AppEventsConfigurationManager should be configured with the default data store"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.settings === components.settings,
      "AppEventsConfigurationManager should be configured with the settings"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestFactory === components.graphRequestFactory,
      "AppEventsConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "AppEventsConfigurationManager should be configured with the graph request connection factory"
    )
  }

  func testConfiguringAppEventsDeviceInfo() throws {
    XCTAssertNil(
      AppEventsDeviceInfo.shared.settings,
      "AppEventsDeviceInfo should not have settings by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppEventsDeviceInfo.shared.settings === components.settings,
      "AppEventsDeviceInfo should be configured with the settings"
    )
  }

  func testConfiguringAppEventsState() throws {
    XCTAssertNil(
      AppEventsState.eventProcessors,
      "AppEventsState should not have event processors by default"
    )

    configurator.performConfiguration()

    let processors = try XCTUnwrap(
      AppEventsState.eventProcessors,
      "AppEventsState's event processors should be configured"
    )
    XCTAssertEqual(processors.count, 2, "AppEventsState should have two event processors")
    XCTAssertTrue(
      processors.first === components.eventDeactivationManager,
      "AppEventsState's event processors should be configured with the event deactivation manager"
    )
    XCTAssertTrue(
      processors.last === components.restrictiveDataFilterManager,
      "AppEventsState's event processors should be configured with the restrictive data filter manager"
    )
  }

  func testConfiguringAppEventsUtility() {
    XCTAssertNil(
      AppEventsUtility.shared.appEventsConfigurationProvider,
      "AppEventsUtility should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      AppEventsUtility.shared.deviceInformationProvider,
      "AppEventsUtility should not have a device information provider by default"
    )
    XCTAssertNil(
      AppEventsUtility.shared.settings,
      "AppEventsUtility should not have settings by default"
    )
    XCTAssertNil(
      AppEventsUtility.shared.internalUtility,
      "AppEventsUtility should not have an internal utility by default"
    )
    XCTAssertNil(
      AppEventsUtility.shared.errorFactory,
      "AppEventsUtility should not have an error factory by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AppEventsUtility.shared.appEventsConfigurationProvider === components.appEventsConfigurationProvider,
      "AppEventsUtility should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      AppEventsUtility.shared.deviceInformationProvider === components.deviceInformationProvider,
      "AppEventsUtility should be configured with the device information provider"
    )
    XCTAssertTrue(
      AppEventsUtility.shared.settings === components.settings,
      "AppEventsUtility should be configured with the settings"
    )
    XCTAssertTrue(
      AppEventsUtility.shared.internalUtility === components.internalUtility,
      "AppEventsUtility should be configured with the internal utility"
    )
    XCTAssertIdentical(
      AppEventsUtility.shared.errorFactory,
      components.errorFactory,
      "AppEventsUtility should be configured with the error factory"
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

  func testConfiguringErrorFactory() {
    XCTAssertNil(
      ErrorFactory.defaultReporter,
      "ErrorFactory should not have a default reporter by default"
    )

    configurator.performConfiguration()

    XCTAssertIdentical(
      ErrorFactory.defaultReporter,
      components.errorReporter,
      "FeatureManager should be configured with the error reporter"
    )
  }

  func testConfiguringFeatureManager() {
    XCTAssertNil(
      FeatureManager.shared.gateKeeperManager,
      "FeatureManager should not have a gatekeeper manager by default"
    )
    XCTAssertNil(
      FeatureManager.shared.settings,
      "FeatureManager should not have settings by default"
    )
    XCTAssertNil(
      FeatureManager.shared.store,
      "FeatureManager should not have a data store by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      FeatureManager.shared.gateKeeperManager === components.gateKeeperManager,
      "FeatureManager should be configured with the gatekeeper manager"
    )
    XCTAssertTrue(
      FeatureManager.shared.settings === components.settings,
      "FeatureManager should be configured with the settings"
    )
    XCTAssertTrue(
      FeatureManager.shared.store === components.defaultDataStore,
      "FeatureManager should be configured with the default data store"
    )
  }

  func testConfiguringGateKeeperManager() {
    XCTAssertNil(
      GateKeeperManager.settings,
      "GateKeeperManager should not have settings by default"
    )
    XCTAssertNil(
      GateKeeperManager.graphRequestFactory,
      "GateKeeperManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      GateKeeperManager.graphRequestConnectionFactory,
      "GateKeeperManager should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      GateKeeperManager.store,
      "GateKeeperManager should not have a data store by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      GateKeeperManager.settings === components.settings,
      "GateKeeperManager should be configured with the settings"
    )
    XCTAssertTrue(
      GateKeeperManager.graphRequestFactory === components.graphRequestFactory,
      "GateKeeperManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      GateKeeperManager.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "GateKeeperManager should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      GateKeeperManager.store === components.defaultDataStore,
      "GateKeeperManager should be configured with the data store"
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
      GraphRequestConnection.accessTokenSetter,
      "GraphRequestConnection should not have an access token setter by default"
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
      GraphRequestConnection.accessTokenSetter === components.accessTokenWallet,
      "GraphRequestConnection should be configured with the access token setter by default"
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
      InstrumentManager.shared.crashObserver,
      "InstrumentManager should not have a crash observer by default"
    )
    XCTAssertNil(
      InstrumentManager.shared.featureChecker,
      "InstrumentManager should not have a feature checker by default"
    )
    XCTAssertNil(
      InstrumentManager.shared.settings,
      "InstrumentManager should not have settings by default"
    )
    XCTAssertNil(
      InstrumentManager.shared.errorReporter,
      "InstrumentManager should not have an error reporter by default"
    )
    XCTAssertNil(
      InstrumentManager.shared.crashHandler,
      "InstrumentManager should not have a crash handler by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      InstrumentManager.shared.crashObserver === components.crashObserver,
      "InstrumentManager should be configured with the crash observer"
    )
    XCTAssertTrue(
      InstrumentManager.shared.featureChecker === components.featureChecker,
      "InstrumentManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      InstrumentManager.shared.settings === components.settings,
      "InstrumentManager should be configured with the settings"
    )
    XCTAssertTrue(
      InstrumentManager.shared.errorReporter === components.errorReporter,
      "InstrumentManager should be configured with the error reporter"
    )
    XCTAssertTrue(
      InstrumentManager.shared.crashHandler === components.crashHandler,
      "InstrumentManager should be configured with the crash handler"
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
      ServerConfigurationManager.shared.graphRequestFactory,
      "ServerConfigurationManager should not have a graph request factory by default"
    )
    XCTAssertNil(
      ServerConfigurationManager.shared.graphRequestConnectionFactory,
      "ServerConfigurationManager should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      ServerConfigurationManager.shared.dialogConfigurationMapBuilder,
      "ServerConfigurationManager should not have a dialog configuration map builder by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestFactory === components.graphRequestFactory,
      "ServerConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "ServerConfigurationManager should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      ServerConfigurationManager.shared.dialogConfigurationMapBuilder === components.dialogConfigurationMapBuilder,
      "ServerConfigurationManager should be configured with the dialog configuration map builder"
    )
  }

  func testConfiguringSettings() {
    XCTAssertNil(
      Settings.shared.store,
      "Settings should not have a data store by default"
    )
    XCTAssertNil(
      Settings.shared.appEventsConfigurationProvider,
      "Settings should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      Settings.shared.infoDictionaryProvider,
      "Settings should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      Settings.shared.eventLogger,
      "Settings should not have an event logger by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      Settings.shared.store === components.defaultDataStore,
      "Settings should be configured with the data store"
    )
    XCTAssertTrue(
      Settings.shared.appEventsConfigurationProvider === components.appEventsConfigurationProvider,
      "Settings should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      Settings.shared.infoDictionaryProvider === components.infoDictionaryProvider,
      "Settings should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      Settings.shared.eventLogger === components.eventLogger,
      "Settings should be configured with the event logger"
    )
  }

  // MARK: - Non-tvOS

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
    XCTAssertNil(
      AppLinkNavigation.settings,
      "AppLinkNavigation should not have settings by default"
    )
    XCTAssertNil(
      AppLinkNavigation.urlOpener,
      "AppLinkNavigation should not have an internal URL opener by default"
    )
    XCTAssertNil(
      AppLinkNavigation.appLinkEventPoster,
      "AppLinkNavigation should not have an app link event poster by default"
    )
    XCTAssertNil(
      AppLinkNavigation.appLinkResolver,
      "AppLinkNavigation should not have an app link resolver by default"
    )

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
      AuthenticationStatusUtility.profileSetter,
      "AuthenticationStatusUtility should not have a profile setter by default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.sessionDataTaskProvider,
      "AuthenticationStatusUtility should not have a session data task provider by default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.accessTokenWallet,
      "AuthenticationStatusUtility should not have an access token by default"
    )
    XCTAssertNil(
      AuthenticationStatusUtility.authenticationTokenWallet,
      "AuthenticationStatusUtility should not have an authentication token by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      AuthenticationStatusUtility.profileSetter === components.profileSetter,
      "AuthenticationStatusUtility should be configured with the profile setter"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.sessionDataTaskProvider === components.sessionDataTaskProvider,
      "AuthenticationStatusUtility should be configured with the session data task provider"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.accessTokenWallet === components.accessTokenWallet,
      "AuthenticationStatusUtility should be configured with the access token"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.authenticationTokenWallet === components.authenticationTokenWallet,
      "AuthenticationStatusUtility should be configured with the authentication token"
    )
  }

  func testConfiguringBridgeAPIRequest() {
    XCTAssertNil(
      BridgeAPIRequest.internalURLOpener,
      "BridgeAPIRequest should not have an internal URL openenr by default"
    )
    XCTAssertNil(
      BridgeAPIRequest.internalUtility,
      "BridgeAPIRequest should not have an internal utility by default"
    )
    XCTAssertNil(
      BridgeAPIRequest.settings,
      "BridgeAPIRequest should not have settings by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      BridgeAPIRequest.internalURLOpener === components.internalURLOpener,
      "BridgeAPIRequest should be configured with the internal URL opener"
    )
    XCTAssertTrue(
      BridgeAPIRequest.internalUtility === components.internalUtility,
      "BridgeAPIRequest should be configured with the internal utility"
    )
    XCTAssertTrue(
      BridgeAPIRequest.settings === components.settings,
      "BridgeAPIRequest should be configured with the settings"
    )
  }

  func testConfiguringCodelessIndexer() {
    XCTAssertNil(
      CodelessIndexer.graphRequestFactory,
      "CodelessIndexer should not have a graph request factory by default"
    )
    XCTAssertNil(
      CodelessIndexer.serverConfigurationProvider,
      "CodelessIndexer should not have a server configuration provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.dataStore,
      "CodelessIndexer should be not have a data store by default"
    )
    XCTAssertNil(
      CodelessIndexer.graphRequestConnectionFactory,
      "CodelessIndexer should not have a graph request connection provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.swizzler,
      "CodelessIndexer should not have a swizzler by default"
    )
    XCTAssertNil(
      CodelessIndexer.settings,
      "CodelessIndexer should not have settings by default"
    )
    XCTAssertNil(
      CodelessIndexer.advertiserIDProvider,
      "CodelessIndexer should not have an advertiser ID provider by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      CodelessIndexer.graphRequestFactory === components.graphRequestFactory,
      "CodelessIndexer should be configured with the graph request factory"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider === components.serverConfigurationProvider,
      "CodelessIndexer should be configured with the server configuration provider"
    )
    XCTAssertTrue(
      CodelessIndexer.dataStore === components.defaultDataStore,
      "Should be configured with the default data store"
    )
    XCTAssertTrue(
      CodelessIndexer.graphRequestConnectionFactory === components.graphRequestConnectionFactory,
      "CodelessIndexer should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      CodelessIndexer.swizzler === components.swizzler,
      "CodelessIndexer should be configured with the swizzler"
    )
    XCTAssertTrue(
      CodelessIndexer.settings === components.settings,
      "CodelessIndexer should be configured with the settings"
    )
    XCTAssertTrue(
      CodelessIndexer.advertiserIDProvider === components.advertiserIDProvider,
      "CodelessIndexer should be configured with the advertiser ID provider"
    )
  }

  func testConfiguringCrashShield() {
    XCTAssertNil(
      CrashShield.settings,
      "CrashShield should not have settings by default"
    )
    XCTAssertNil(
      CrashShield.graphRequestFactory,
      "CrashShield should not have a graph request factory by default"
    )
    XCTAssertNil(
      CrashShield.featureChecking,
      "CrashShield should not have a feature checker by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      CrashShield.settings === components.settings,
      "CrashShield should be configured with the settings"
    )
    XCTAssertTrue(
      CrashShield.graphRequestFactory === components.graphRequestFactory,
      "CrashShield should be configured with the graph request factory"
    )
    XCTAssertTrue(
      CrashShield.featureChecking === components.featureChecker,
      "CrashShield should be configured with the feature checker"
    )
  }

  func testConfiguringFeatureExtractor() {
    XCTAssertNil(
      FeatureExtractor.rulesFromKeyProvider,
      "FeatureExtractor should not have a web view provider by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      FeatureExtractor.rulesFromKeyProvider === components.rulesFromKeyProvider,
      "FeatureExtractor should be configured with the web view provider"
    )
  }

  func testConfiguringModelManager() {
    XCTAssertNil(
      ModelManager.shared.featureChecker,
      "ModelManager should not have a feature checker by default"
    )
    XCTAssertNil(
      ModelManager.shared.graphRequestFactory,
      "ModelManager should not have a request factory by default"
    )
    XCTAssertNil(
      ModelManager.shared.fileManager,
      "ModelManager should not have a file manager by default"
    )
    XCTAssertNil(
      ModelManager.shared.store,
      "ModelManager should not have a data store by default"
    )
    XCTAssertNil(
      ModelManager.shared.settings,
      "ModelManager should not have a settings by default"
    )
    XCTAssertNil(
      ModelManager.shared.dataExtractor,
      "ModelManager should not have a data extractor by default"
    )
    XCTAssertNil(
      ModelManager.shared.gateKeeperManager,
      "ModelManager should not have a gate keeper manager by default"
    )
    XCTAssertNil(
      ModelManager.shared.suggestedEventsIndexer,
      "ModelManager should not have a suggested events indexer by default"
    )
    XCTAssertNil(
      ModelManager.shared.featureExtractor,
      "ModelManager should not have a feature extractor by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      ModelManager.shared.featureChecker === components.featureChecker,
      "ModelManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      ModelManager.shared.graphRequestFactory === components.graphRequestFactory,
      "ModelManager should be configured with the request factory"
    )
    XCTAssertTrue(
      ModelManager.shared.fileManager === components.fileManager,
      "ModelManager should be configured with the file manager"
    )
    XCTAssertTrue(
      ModelManager.shared.store === components.defaultDataStore,
      "ModelManager should be configured with the default data store"
    )
    XCTAssertTrue(
      ModelManager.shared.settings === components.settings,
      "ModelManager should be configured with the settings"
    )
    XCTAssertTrue(
      ModelManager.shared.dataExtractor === components.dataExtractor,
      "ModelManager should be configured with the data extractor"
    )
    XCTAssertTrue(
      ModelManager.shared.gateKeeperManager === components.gateKeeperManager,
      "ModelManager should be configured with the gate keeper manager"
    )
    XCTAssertTrue(
      ModelManager.shared.featureExtractor === components.featureExtractor,
      "ModelManager should be configured with the feature extractor"
    )
  }

  func testConfiguringProfile() {
    XCTAssertNil(
      Profile.dataStore,
      "Profile should not have a data store by default"
    )
    XCTAssertNil(
      Profile.accessTokenProvider,
      "Profile should not have an access token provider by default"
    )
    XCTAssertNil(
      Profile.notificationCenter,
      "Profile should not have a notification center by default"
    )
    XCTAssertNil(
      Profile.settings,
      "Profile should not have settings by default"
    )
    XCTAssertNil(
      Profile.urlHoster,
      "Profile should not have a URL hoster by default"
    )

    configurator.performConfiguration()

    XCTAssertTrue(
      Profile.dataStore === components.defaultDataStore,
      "Profile should be configured with the default data store"
    )
    XCTAssertTrue(
      Profile.accessTokenProvider === components.accessTokenWallet,
      "Profile should be configured with the access token wallet"
    )
    XCTAssertTrue(
      Profile.notificationCenter === components.notificationCenter,
      "Profile should be configured with the notification center"
    )
    XCTAssertTrue(
      Profile.settings === components.settings,
      "Profile should be configured with the settings"
    )
    XCTAssertTrue(
      Profile.urlHoster === components.urlHoster,
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
