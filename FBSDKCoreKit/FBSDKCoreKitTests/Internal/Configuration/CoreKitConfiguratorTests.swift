/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// swiftlint:disable file_length type_body_length function_body_length

import XCTest

final class CoreKitConfiguratorTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var dependencies: SharedDependencies!
  var configurator: CoreKitConfigurator!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    Self.resetTargets()

    dependencies = TestSharedDependencies.makeDependencies()
    configurator = CoreKitConfigurator(dependencies: dependencies)
  }

  override func tearDown() {
    dependencies = nil
    configurator = nil

    super.tearDown()
  }

  override class func tearDown() {
    resetTargets()
    super.tearDown()
  }

  private class func resetTargets() {
    AccessToken.resetClassDependencies()
    AppEvents.reset()
    AppEventsConfigurationManager.reset()
    AppEventsState.eventProcessors = nil
    AppEventsUtility.reset()
    FBButton.resetClassDependencies()
    FeatureManager.reset()
    GateKeeperManager.reset()
    GraphRequest.resetClassDependencies()
    GraphRequestConnection.resetClassDependencies()
    GraphRequestPiggybackManager.reset()
    InstrumentManager.reset()
    InternalUtility.reset()
    SDKError.reset()
    ServerConfigurationManager.shared.reset()
    Settings.shared.reset()

    // Non-tvOS
    AppLinkNavigation.reset()
    AppLinkURL.reset()
    AppLinkUtility.reset()
    AuthenticationStatusUtility.resetClassDependencies()
    BridgeAPIRequest.resetClassDependencies()
    CodelessIndexer.reset()
    CrashShield.reset()
    FBWebDialogView.reset()
    FeatureExtractor.reset()
    ModelManager.reset()
    Profile.reset()
  }

  // MARK: - All Platforms

  func testConfiguringAccessToken() {
    XCTAssertNil(
      AccessToken.tokenCache,
      "AccessToken should be not have a token cache by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestConnectionFactory,
      "AccessToken should be not have a graph request connection factory by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestPiggybackManager,
      "AccessToken should be not have a graph request piggyback manager by default"
    )

    configurator.configureTargets()

    XCTAssertTrue(
      AccessToken.tokenCache === dependencies.tokenCache,
      "Should be configured with the token cache"
    )
    XCTAssertTrue(
      AccessToken.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "Should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      AccessToken.graphRequestPiggybackManager === dependencies.piggybackManager,
      "Should be configured with the graph request piggyback manager"
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppEvents.shared.gateKeeperManager === dependencies.gateKeeperManager,
      "AppEvents should be configured with the gate keeper manager"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsConfigurationProvider === dependencies.appEventsConfigurationProvider,
      "AppEvents should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      AppEvents.shared.serverConfigurationProvider === dependencies.serverConfigurationProvider,
      "AppEvents should be configured with the server configuration provider"
    )
    XCTAssertTrue(
      AppEvents.shared.graphRequestFactory === dependencies.graphRequestFactory,
      "AppEvents should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppEvents.shared.featureChecker === dependencies.featureChecker,
      "AppEvents should be configured with the feature checker"
    )
    XCTAssertTrue(
      AppEvents.shared.primaryDataStore === dependencies.defaultDataStore,
      "AppEvents should be configured with the primary data store"
    )
    XCTAssertTrue(
      AppEvents.shared.logger === dependencies.logger,
      "AppEvents should be configured with the logger"
    )
    XCTAssertTrue(
      AppEvents.shared.settings === dependencies.settings,
      "AppEvents should be configured with the"
    )
    XCTAssertTrue(
      AppEvents.shared.paymentObserver === dependencies.paymentObserver,
      "AppEvents should be configured with the payment observer"
    )
    XCTAssertTrue(
      AppEvents.shared.timeSpentRecorder === dependencies.timeSpentRecorder,
      "AppEvents should be configured with the time spent recorder"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsStateStore === dependencies.appEventsStateStore,
      "AppEvents should be configured with the app events state store"
    )
    XCTAssertTrue(
      AppEvents.shared.eventDeactivationParameterProcessor === dependencies.eventDeactivationManager,
      "AppEvents should be configured with the event deactivation parameter processor"
    )
    XCTAssertTrue(
      AppEvents.shared.restrictiveDataFilterParameterProcessor === dependencies.restrictiveDataFilterManager,
      "AppEvents should be configured with the restrictive data filter parameter processor"
    )
    XCTAssertTrue(
      AppEvents.shared.atePublisherFactory === dependencies.atePublisherFactory,
      "AppEvents should be configured with the ATE publisher factory"
    )
    XCTAssertTrue(
      AppEvents.shared.appEventsStateProvider === dependencies.appEventsStateProvider,
      "AppEvents should be configured with the app events state provider"
    )
    XCTAssertTrue(
      AppEvents.shared.advertiserIDProvider === dependencies.advertiserIDProvider,
      "AppEvents should be configured with the advertiser ID provider"
    )
    XCTAssertTrue(
      AppEvents.shared.userDataStore === dependencies.userDataStore,
      "AppEvents should be configured with the user data store"
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppEvents.shared.onDeviceMLModelManager === dependencies.modelManager,
      "AppEvents should be configured with the on-device ML model manager"
    )
    XCTAssertTrue(
      AppEvents.shared.metadataIndexer === dependencies.metadataIndexer,
      "AppEvents should be configured with the metadata indexer"
    )
    XCTAssertTrue(
      AppEvents.shared.skAdNetworkReporter === dependencies.skAdNetworkReporter,
      "AppEvents should be configured with StoreKit ad network reporter"
    )
    XCTAssertTrue(
      AppEvents.shared.codelessIndexer === dependencies.codelessIndexer,
      "AppEvents should be configured with the codeless indexer"
    )
    XCTAssertTrue(
      AppEvents.shared.swizzler === dependencies.swizzler,
      "AppEvents should be configured with the swizzler"
    )
    XCTAssertTrue(
      AppEvents.shared.aemReporter === dependencies.aemReporter,
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppEventsConfigurationManager.shared.store === dependencies.defaultDataStore,
      "AppEventsConfigurationManager should be configured with the default data store"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.settings === dependencies.settings,
      "AppEventsConfigurationManager should be configured with the settings"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestFactory === dependencies.graphRequestFactory,
      "AppEventsConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "AppEventsConfigurationManager should be configured with the graph request connection factory"
    )
  }

  func testConfiguringAppEventsState() throws {
    XCTAssertNil(
      AppEventsState.eventProcessors,
      "AppEventsState should not have event processors by default"
    )

    configurator.configureTargets()

    let processors = try XCTUnwrap(
      AppEventsState.eventProcessors,
      "AppEventsState's event processors should be configured"
    )
    XCTAssertEqual(processors.count, 2, "AppEventsState should have two event processors")
    XCTAssertTrue(
      processors.first === dependencies.eventDeactivationManager,
      "AppEventsState's event processors should be configured with the event deactivation manager"
    )
    XCTAssertTrue(
      processors.last === dependencies.restrictiveDataFilterManager,
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppEventsUtility.shared.appEventsConfigurationProvider === dependencies.appEventsConfigurationProvider,
      "AppEventsUtility should be configured with the app events configuration provider"
    )

    XCTAssertTrue(
      AppEventsUtility.shared.deviceInformationProvider === dependencies.deviceInformationProvider,
      "AppEventsUtility should be configured with the device information provider"
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

    configurator.configureTargets()

    XCTAssertTrue(
      FBButton.applicationActivationNotifier as AnyObject === dependencies.applicationActivationNotifier as AnyObject,
      "Button should be configured with the application activation notifier"
    )
    XCTAssertTrue(
      FBButton.eventLogger === dependencies.eventLogger,
      "Button should be configured with the expected concrete app events"
    )
    XCTAssertTrue(
      FBButton.accessTokenProvider === dependencies.accessTokenWallet,
      "Button should be configured with the expected concrete access token provider"
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

    configurator.configureTargets()

    XCTAssertTrue(
      FeatureManager.shared.gateKeeperManager === dependencies.gateKeeperManager,
      "FeatureManager should be configured with the gatekeeper manager"
    )
    XCTAssertTrue(
      FeatureManager.shared.settings === dependencies.settings,
      "FeatureManager should be configured with the settings"
    )
    XCTAssertTrue(
      FeatureManager.shared.store === dependencies.defaultDataStore,
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

    configurator.configureTargets()

    XCTAssertTrue(
      GateKeeperManager.settings === dependencies.settings,
      "GateKeeperManager should be configured with the settings"
    )
    XCTAssertTrue(
      GateKeeperManager.graphRequestFactory === dependencies.graphRequestFactory,
      "GateKeeperManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      GateKeeperManager.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "GateKeeperManager should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      GateKeeperManager.store === dependencies.defaultDataStore,
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

    configurator.configureTargets()

    XCTAssertTrue(
      GraphRequest.settings === dependencies.settings,
      "GraphRequest should be configured with the settings"
    )
    XCTAssertTrue(
      GraphRequest.accessTokenProvider === dependencies.accessTokenWallet,
      "GraphRequest should be configured with the access token wallet"
    )
    XCTAssertTrue(
      GraphRequest.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
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

    configurator.configureTargets()

    XCTAssertTrue(
      GraphRequestConnection.sessionProxyFactory === dependencies.urlSessionProxyFactory,
      "GraphRequestConnection should be configured with the concrete session provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorConfigurationProvider === dependencies.errorConfigurationProvider,
      "GraphRequestConnection should be configured with the error configuration provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.piggybackManager === dependencies.piggybackManager,
      "GraphRequestConnection should be configured with the piggyback manager provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.settings === dependencies.settings,
      "GraphRequestConnection should be configured with the settings type"
    )
    XCTAssertTrue(
      GraphRequestConnection.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "GraphRequestConnection should be configured with the connection factory"
    )
    XCTAssertTrue(
      GraphRequestConnection.eventLogger === dependencies.eventLogger,
      "GraphRequestConnection should be configured with the event logger"
    )
    XCTAssertTrue(
      GraphRequestConnection.operatingSystemVersionComparer === dependencies.operatingSystemVersionComparer,
      "GraphRequestConnection should be configured with the operating system version comparer"
    )
    XCTAssertTrue(
      GraphRequestConnection.macCatalystDeterminator === dependencies.macCatalystDeterminator,
      "GraphRequestConnection should be configured with the Mac Catalyst determinator"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenProvider === dependencies.accessTokenWallet,
      "GraphRequestConnection should be configured with the access token provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenSetter === dependencies.accessTokenWallet,
      "GraphRequestConnection should be configured with the access token setter by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorFactory === dependencies.errorFactory,
      "GraphRequestConnection should be configured with the error factory"
    )
    XCTAssertTrue(
      GraphRequestConnection.authenticationTokenProvider === dependencies.authenticationTokenWallet,
      "GraphRequestConnection should be configured with the authentication token provider"
    )
  }

  func testConfiguringGraphRequestPiggybackManager() {
    XCTAssertNil(
      GraphRequestPiggybackManager.tokenWallet,
      "GraphRequestPiggybackManager should not have an access token wallet by default"
    )
    XCTAssertNil(
      GraphRequestPiggybackManager.settings,
      "GraphRequestPiggybackManager should not have a settings by default"
    )
    XCTAssertNil(
      GraphRequestPiggybackManager.serverConfigurationProvider,
      "GraphRequestPiggybackManager should not have a server configuration by default"
    )
    XCTAssertNil(
      GraphRequestPiggybackManager.graphRequestFactory,
      "GraphRequestPiggybackManager should not have a graph request factory by default"
    )

    configurator.configureTargets()

    XCTAssertTrue(
      GraphRequestPiggybackManager.tokenWallet === dependencies.accessTokenWallet,
      "GraphRequestPiggybackManager should be configured with the access token wallet"
    )
    XCTAssertTrue(
      GraphRequestPiggybackManager.settings === dependencies.settings,
      "GraphRequestPiggybackManager should be configured with the settings"
    )
    XCTAssertTrue(
      GraphRequestPiggybackManager.serverConfigurationProvider === dependencies.serverConfigurationProvider,
      "GraphRequestPiggybackManager should be configured with the server configuration"
    )
    XCTAssertTrue(
      GraphRequestPiggybackManager.graphRequestFactory === dependencies.graphRequestFactory,
      "GraphRequestPiggybackManager should be configured with the graph request factory"
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

    configurator.configureTargets()

    XCTAssertTrue(
      InstrumentManager.shared.crashObserver === dependencies.crashObserver,
      "InstrumentManager should be configured with the crash observer"
    )
    XCTAssertTrue(
      InstrumentManager.shared.featureChecker === dependencies.featureChecker,
      "InstrumentManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      InstrumentManager.shared.settings === dependencies.settings,
      "InstrumentManager should be configured with the settings"
    )
    XCTAssertTrue(
      InstrumentManager.shared.errorReporter === dependencies.errorReporter,
      "InstrumentManager should be configured with the error reporter"
    )
    XCTAssertTrue(
      InstrumentManager.shared.crashHandler === dependencies.crashHandler,
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

    configurator.configureTargets()

    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === dependencies.infoDictionaryProvider,
      "InternalUtility should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      InternalUtility.shared.loggerFactory === dependencies.loggerFactory,
      "InternalUtility should be configured with the logger factory"
    )
  }

  func testConfiguringSDKError() {
    XCTAssertNil(
      SDKError.errorReporter,
      "SDKError should not have an error reporter by default"
    )

    configurator.configureTargets()

    XCTAssertTrue(
      SDKError.errorReporter === dependencies.errorReporter,
      "SDKError should be configured with the error reporter"
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

    configurator.configureTargets()

    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestFactory === dependencies.graphRequestFactory,
      "ServerConfigurationManager should be configured with the graph request factory"
    )
    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "ServerConfigurationManager should be configured with the graph request connection factory"
    )
  }

  func testConfiguringSettings() {
    XCTAssertNil(
      Settings.store,
      "Settings should not have a data store by default"
    )
    XCTAssertNil(
      Settings.shared.appEventsConfigurationProvider,
      "Settings should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      Settings.infoDictionaryProvider,
      "Settings should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      Settings.eventLogger,
      "Settings should not have an event logger by default"
    )

    configurator.configureTargets()

    XCTAssertTrue(
      Settings.store === dependencies.defaultDataStore,
      "Settings should be configured with the data store"
    )
    XCTAssertTrue(
      Settings.shared.appEventsConfigurationProvider === dependencies.appEventsConfigurationProvider,
      "Settings should be configured with the app events configuration provider"
    )
    XCTAssertTrue(
      Settings.infoDictionaryProvider === dependencies.infoDictionaryProvider,
      "Settings should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      Settings.eventLogger === dependencies.eventLogger,
      "Settings should be configured with the event logger"
    )
  }

  // MARK: - Non-tvOS

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

    configurator.configureTargets()

    XCTAssertTrue(
      AppLinkNavigation.settings === dependencies.settings,
      "AppLinkNavigation should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkNavigation.urlOpener === dependencies.internalURLOpener,
      "AppLinkNavigation should be configured with the internal URL opener"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkEventPoster === dependencies.appLinkEventPoster,
      "AppLinkNavigation should be configured with the app link event poster"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkResolver === dependencies.appLinkResolver,
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppLinkURL.settings === dependencies.settings,
      "AppLinkURL should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkFactory === dependencies.appLinkFactory,
      "AppLinkURL should be configured with the app link factory"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkTargetFactory === dependencies.appLinkTargetFactory,
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

    configurator.configureTargets()

    XCTAssertTrue(
      AppLinkUtility.graphRequestFactory === dependencies.graphRequestFactory,
      "AppLinkUtility should be configured with the graph request factory"
    )
    XCTAssertTrue(
      AppLinkUtility.infoDictionaryProvider === dependencies.infoDictionaryProvider,
      "AppLinkUtility should be configured with the info dictionary provider"
    )
    XCTAssertTrue(
      AppLinkUtility.settings === dependencies.settings,
      "AppLinkUtility should be configured with the settings"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsConfigurationProvider === dependencies.appEventsConfigurationProvider,
      "AppLinkUtility should be configured with the app events configuration manager"
    )
    XCTAssertTrue(
      AppLinkUtility.advertiserIDProvider === dependencies.advertiserIDProvider,
      "AppLinkUtility should be configured with the advertiser ID provider"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsDropDeterminer === dependencies.appEventsDropDeterminer,
      "AppLinkUtility should be configured with the app events drop determiner"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventParametersExtractor === dependencies.appEventParametersExtractor,
      "AppLinkUtility should be configured with the app events parameter extractor"
    )
    XCTAssertTrue(
      AppLinkUtility.appLinkURLFactory === dependencies.appLinkURLFactory,
      "AppLinkUtility should be configured with the app link URL factory"
    )
    XCTAssertTrue(
      AppLinkUtility.userIDProvider === dependencies.userIDProvider,
      "AppLinkUtility should be configured with the user ID provider"
    )
    XCTAssertTrue(
      AppLinkUtility.userDataStore === dependencies.userDataStore,
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

    configurator.configureTargets()

    XCTAssertTrue(
      AuthenticationStatusUtility.profileSetter === dependencies.profileSetter,
      "AuthenticationStatusUtility should be configured with the profile setter"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.sessionDataTaskProvider === dependencies.sessionDataTaskProvider,
      "AuthenticationStatusUtility should be configured with the session data task provider"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.accessTokenWallet === dependencies.accessTokenWallet,
      "AuthenticationStatusUtility should be configured with the access token"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.authenticationTokenWallet === dependencies.authenticationTokenWallet,
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

    configurator.configureTargets()

    XCTAssertTrue(
      BridgeAPIRequest.internalURLOpener === dependencies.internalURLOpener,
      "BridgeAPIRequest should be configured with the internal URL opener"
    )
    XCTAssertTrue(
      BridgeAPIRequest.internalUtility === dependencies.internalUtility,
      "BridgeAPIRequest should be configured with the internal utility"
    )
    XCTAssertTrue(
      BridgeAPIRequest.settings === dependencies.settings,
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

    configurator.configureTargets()

    XCTAssertTrue(
      CodelessIndexer.graphRequestFactory === dependencies.graphRequestFactory,
      "CodelessIndexer should be configured with the graph request factory"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider === dependencies.serverConfigurationProvider,
      "CodelessIndexer should be configured with the server configuration provider"
    )
    XCTAssertTrue(
      CodelessIndexer.dataStore === dependencies.defaultDataStore,
      "Should be configured with the default data store"
    )
    XCTAssertTrue(
      CodelessIndexer.graphRequestConnectionFactory === dependencies.graphRequestConnectionFactory,
      "CodelessIndexer should be configured with the graph request connection factory"
    )
    XCTAssertTrue(
      CodelessIndexer.swizzler === dependencies.swizzler,
      "CodelessIndexer should be configured with the swizzler"
    )
    XCTAssertTrue(
      CodelessIndexer.settings === dependencies.settings,
      "CodelessIndexer should be configured with the settings"
    )
    XCTAssertTrue(
      CodelessIndexer.advertiserIDProvider === dependencies.advertiserIDProvider,
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

    configurator.configureTargets()

    XCTAssertTrue(
      CrashShield.settings === dependencies.settings,
      "CrashShield should be configured with the settings"
    )
    XCTAssertTrue(
      CrashShield.graphRequestFactory === dependencies.graphRequestFactory,
      "CrashShield should be configured with the graph request factory"
    )
    XCTAssertTrue(
      CrashShield.featureChecking === dependencies.featureChecker,
      "CrashShield should be configured with the feature checker"
    )
  }

  func testConfiguringFeatureExtractor() {
    XCTAssertNil(
      FeatureExtractor.rulesFromKeyProvider,
      "FeatureExtractor should not have a web view provider by default"
    )

    configurator.configureTargets()

    XCTAssertTrue(
      FeatureExtractor.rulesFromKeyProvider === dependencies.rulesFromKeyProvider,
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

    configurator.configureTargets()

    XCTAssertTrue(
      ModelManager.shared.featureChecker === dependencies.featureChecker,
      "ModelManager should be configured with the feature checker"
    )
    XCTAssertTrue(
      ModelManager.shared.graphRequestFactory === dependencies.graphRequestFactory,
      "ModelManager should be configured with the request factory"
    )
    XCTAssertTrue(
      ModelManager.shared.fileManager === dependencies.fileManager,
      "ModelManager should be configured with the file manager"
    )
    XCTAssertTrue(
      ModelManager.shared.store === dependencies.defaultDataStore,
      "ModelManager should be configured with the default data store"
    )
    XCTAssertTrue(
      ModelManager.shared.settings === dependencies.settings,
      "ModelManager should be configured with the settings"
    )
    XCTAssertTrue(
      ModelManager.shared.dataExtractor === dependencies.dataExtractor,
      "ModelManager should be configured with the data extractor"
    )
    XCTAssertTrue(
      ModelManager.shared.gateKeeperManager === dependencies.gateKeeperManager,
      "ModelManager should be configured with the gate keeper manager"
    )
    XCTAssertTrue(
      ModelManager.shared.featureExtractor === dependencies.featureExtractor,
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

    configurator.configureTargets()

    XCTAssertTrue(
      Profile.dataStore === dependencies.defaultDataStore,
      "Profile should be configured with the default data store"
    )
    XCTAssertTrue(
      Profile.accessTokenProvider === dependencies.accessTokenWallet,
      "Profile should be configured with the access token wallet"
    )
    XCTAssertTrue(
      Profile.notificationCenter === dependencies.notificationCenter,
      "Profile should be configured with the notification center"
    )
    XCTAssertTrue(
      Profile.settings === dependencies.settings,
      "Profile should be configured with the settings"
    )
    XCTAssertTrue(
      Profile.urlHoster === dependencies.urlHoster,
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

    configurator.configureTargets()

    XCTAssertTrue(
      FBWebDialogView.webViewProvider === dependencies.webViewProvider,
      "FBWebDialogView should be configured with the web view factory"
    )
    XCTAssertTrue(
      FBWebDialogView.urlOpener === dependencies.internalURLOpener,
      "FBWebDialogView should be configured with the internal URL opener"
    )
  }
}
