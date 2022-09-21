/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)
import FBAEMKit
#endif

final class CoreKitConfigurator: CoreKitConfiguring {

  let components: CoreKitComponents

  init(components: CoreKitComponents) {
    self.components = components
  }

  func performConfiguration() {
    configureAccessToken()
    configureAppEvents()
    configureAppEventsConfigurationManager()
    configureAppEventsDeviceInfo()
    configureAppEventsState()
    configureAppEventsUtility()
    configureAuthenticationToken()
    configureButton()
    configureErrorFactory()
    configureGatekeeperManager()
    configureGraphRequest()
    configureGraphRequestConnection()
    configureImpressionLoggingButton()
    configureInstrumentManager()
    configureInternalUtility()
    configureServerConfigurationManager()
    configureSettings()
    configureCloudBridge()

    #if !os(tvOS)
    configureAEMReporter()
    configureNonTVOSAppEvents()
    configureAppLinkNavigation()
    configureAppLinkURL()
    configureAppLinkUtility()
    configureAuthenticationStatusUtility()
    configureBridgeAPIRequest()
    configureCodelessIndexer()
    configureCrashShield()
    configureFeatureExtractor()
    configureModelManager()
    configureProfile()
    configureWebDialogView()
    #endif
  }
}

// MARK: - All platforms

// swiftformat:disable:next extensionaccesscontrol
private extension CoreKitConfigurator {
  func configureAccessToken() {
    AccessToken.configure(
      tokenCache: components.tokenCache,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      graphRequestPiggybackManager: components.piggybackManager,
      errorFactory: components.errorFactory
    )
  }

  func configureAppEvents() {
    AppEvents.shared.configure(
      gateKeeperManager: components.gateKeeperManager,
      appEventsConfigurationProvider: components.appEventsConfigurationProvider,
      serverConfigurationProvider: components.serverConfigurationProvider,
      graphRequestFactory: components.graphRequestFactory,
      featureChecker: components.featureChecker,
      primaryDataStore: components.defaultDataStore,
      logger: components.logger,
      settings: components.settings,
      paymentObserver: components.paymentObserver,
      timeSpentRecorder: components.timeSpentRecorder,
      appEventsStateStore: components.appEventsStateStore,
      eventDeactivationParameterProcessor: components.eventDeactivationManager,
      restrictiveDataFilterParameterProcessor: components.restrictiveDataFilterManager,
      atePublisherFactory: components.atePublisherFactory,
      appEventsStateProvider: components.appEventsStateProvider,
      advertiserIDProvider: components.advertiserIDProvider,
      userDataStore: components.userDataStore,
      appEventsUtility: components.appEventsUtility,
      internalUtility: components.internalUtility,
      capiReporter: components.capiReporter
    )
  }

  func configureAppEventsConfigurationManager() {
    _AppEventsConfigurationManager.shared.configure(
      store: components.defaultDataStore,
      settings: components.settings,
      graphRequestFactory: components.graphRequestFactory,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory
    )
  }

  func configureAppEventsDeviceInfo() {
    _AppEventsDeviceInfo.shared.configure(settings: components.settings)
  }

  func configureAppEventsState() {
    _AppEventsState.eventProcessors = [
      components.eventDeactivationManager,
      components.restrictiveDataFilterManager,
    ]
  }

  func configureAppEventsUtility() {
    _AppEventsUtility.shared.configure(
      appEventsConfigurationProvider: components.appEventsConfigurationProvider,
      deviceInformationProvider: components.deviceInformationProvider,
      settings: components.settings,
      internalUtility: components.internalUtility,
      errorFactory: components.errorFactory
    )
  }

  func configureAuthenticationToken() {
    AuthenticationToken.tokenCache = components.tokenCache
  }

  func configureButton() {
    FBButton.configure(
      applicationActivationNotifier: components.getApplicationActivationNotifier(),
      eventLogger: components.eventLogger,
      accessTokenProvider: components.accessTokenWallet
    )
  }

  func configureErrorFactory() {
    ErrorFactory.configure(defaultReporter: components.errorReporter)
  }

  func configureGatekeeperManager() {
    _GateKeeperManager.configure(
      settings: components.settings,
      graphRequestFactory: components.graphRequestFactory,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      store: components.defaultDataStore
    )
  }

  func configureGraphRequest() {
    GraphRequest.configure(
      settings: components.settings,
      currentAccessTokenStringProvider: components.accessTokenWallet,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory
    )
  }

  func configureGraphRequestConnection() {
    GraphRequestConnection.configure(
      urlSessionProxyFactory: components.urlSessionProxyFactory,
      errorConfigurationProvider: components.errorConfigurationProvider,
      piggybackManager: components.piggybackManager,
      settings: components.settings,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      eventLogger: components.eventLogger,
      operatingSystemVersionComparer: components.operatingSystemVersionComparer,
      macCatalystDeterminator: components.macCatalystDeterminator,
      accessTokenProvider: components.accessTokenWallet,
      errorFactory: components.errorFactory,
      authenticationTokenProvider: components.authenticationTokenWallet
    )

    GraphRequestConnection.setCanMakeRequests()
  }

  func configureImpressionLoggingButton() {
    ImpressionLoggingButton.configure(impressionLoggerFactory: components.impressionLoggerFactory)
  }

  func configureInstrumentManager() {
    _InstrumentManager.shared.configure(
      featureChecker: components.featureChecker,
      settings: components.settings,
      crashObserver: components.crashObserver,
      errorReporter: components.errorReporter,
      crashHandler: components.crashHandler
    )
  }

  func configureInternalUtility() {
    InternalUtility.shared.configure(
      infoDictionaryProvider: components.infoDictionaryProvider,
      loggerFactory: components.loggerFactory,
      settings: components.settings,
      errorFactory: components.errorFactory
    )
  }

  func configureServerConfigurationManager() {
    _ServerConfigurationManager.shared.configure(
      graphRequestFactory: components.graphRequestFactory,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      dialogConfigurationMapBuilder: components.dialogConfigurationMapBuilder
    )
  }

  func configureSettings() {
    Settings.shared.configure(
      store: components.defaultDataStore,
      appEventsConfigurationProvider: components.appEventsConfigurationProvider,
      infoDictionaryProvider: components.infoDictionaryProvider,
      eventLogger: components.eventLogger
    )
  }

  func configureCloudBridge() {
    FBSDKAppEventsCAPIManager.shared.configure(
      factory: components.graphRequestFactory,
      settings: components.settings
    )
  }

  // MARK: - Non-tvOS

  #if !os(tvOS)

  @available(tvOS, unavailable)
  func configureAEMReporter() {
    if #available(iOS 14, *) {
      AEMReporter.configure(
        networker: components.aemNetworker,
        appID: components.settings.appID,
        reporter: components.skAdNetworkReporter
      )
    }
  }

  @available(tvOS, unavailable)
  func configureNonTVOSAppEvents() {
    AppEvents.shared.configureNonTVComponents(
      onDeviceMLModelManager: components.modelManager,
      metadataIndexer: components.metadataIndexer,
      skAdNetworkReporter: components.skAdNetworkReporter,
      codelessIndexer: components.codelessIndexer,
      swizzler: components.swizzler,
      aemReporter: components.aemReporter
    )
  }

  @available(tvOS, unavailable)
  func configureAppLinkNavigation() {
    AppLinkNavigation.configure(
      settings: components.settings,
      urlOpener: components.internalURLOpener,
      appLinkEventPoster: components.appLinkEventPoster,
      appLinkResolver: components.appLinkResolver
    )
  }

  @available(tvOS, unavailable)
  func configureAppLinkURL() {
    AppLinkURL.configure(
      settings: components.settings,
      appLinkFactory: components.appLinkFactory,
      appLinkTargetFactory: components.appLinkTargetFactory,
      appLinkEventPoster: components.appLinkEventPoster
    )
  }

  @available(tvOS, unavailable)
  func configureAppLinkUtility() {
    AppLinkUtility.configure(
      graphRequestFactory: components.graphRequestFactory,
      infoDictionaryProvider: components.infoDictionaryProvider,
      settings: components.settings,
      appEventsConfigurationProvider: components.appEventsConfigurationProvider,
      advertiserIDProvider: components.advertiserIDProvider,
      appEventsDropDeterminer: components.appEventsDropDeterminer,
      appEventParametersExtractor: components.appEventParametersExtractor,
      appLinkURLFactory: components.appLinkURLFactory,
      userIDProvider: components.userIDProvider,
      userDataStore: components.userDataStore
    )
  }

  @available(tvOS, unavailable)
  func configureAuthenticationStatusUtility() {
    _AuthenticationStatusUtility.configure(
      profileSetter: components.profileSetter,
      sessionDataTaskProvider: components.sessionDataTaskProvider,
      accessTokenWallet: components.accessTokenWallet,
      authenticationTokenWallet: components.authenticationTokenWallet
    )
  }

  @available(tvOS, unavailable)
  func configureBridgeAPIRequest() {
    _BridgeAPIRequest.configure(
      internalURLOpener: components.internalURLOpener,
      internalUtility: components.internalUtility,
      settings: components.settings
    )
  }

  @available(tvOS, unavailable)
  func configureCodelessIndexer() {
    _CodelessIndexer.configure(
      graphRequestFactory: components.graphRequestFactory,
      serverConfigurationProvider: components.serverConfigurationProvider,
      dataStore: components.defaultDataStore,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      swizzler: components.swizzler,
      settings: components.settings,
      advertiserIDProvider: components.advertiserIDProvider
    )
  }

  @available(tvOS, unavailable)
  func configureCrashShield() {
    _CrashShield.configure(
      settings: components.settings,
      graphRequestFactory: components.graphRequestFactory,
      featureChecking: components.featureChecker
    )
  }

  @available(tvOS, unavailable)
  func configureFeatureExtractor() {
    _FeatureExtractor.configure(rulesFromKeyProvider: components.rulesFromKeyProvider)
  }

  @available(tvOS, unavailable)
  func configureModelManager() {
    _ModelManager.shared.configure(
      featureChecker: components.featureChecker,
      graphRequestFactory: components.graphRequestFactory,
      fileManager: components.fileManager,
      store: components.defaultDataStore,
      settings: components.settings,
      dataExtractor: components.dataExtractor,
      gateKeeperManager: components.gateKeeperManager,
      suggestedEventsIndexer: components.suggestedEventsIndexer,
      featureExtractor: components.featureExtractor
    )
  }

  @available(tvOS, unavailable)
  func configureProfile() {
    Profile.configure(
      dataStore: components.defaultDataStore,
      accessTokenProvider: components.accessTokenWallet,
      notificationCenter: components.notificationCenter,
      settings: components.settings,
      urlHoster: components.urlHoster
    )
  }

  @available(tvOS, unavailable)
  func configureWebDialogView() {
    FBWebDialogView.configure(
      webViewProvider: components.webViewProvider,
      urlOpener: components.internalURLOpener,
      errorFactory: components.errorFactory
    )
  }

  #endif
}
