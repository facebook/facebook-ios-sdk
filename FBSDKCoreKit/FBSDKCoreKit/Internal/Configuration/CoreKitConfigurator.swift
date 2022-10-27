/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

final class CoreKitConfigurator: CoreKitConfiguring {

  let components: CoreKitComponents

  init(components: CoreKitComponents) {
    self.components = components
  }

  func performConfiguration() {
    configureSettings()
    configureAccessToken()
    configureAppEvents()
    configureAppEventsConfigurationManager()
    configureAppEventsDeviceInfo()
    configureAppEventsState()
    configureAppEventsUtility()
    configureAuthenticationToken()
    configureButton()
    configureGatekeeperManager()
    configureGraphRequest()
    configureGraphRequestConnection()
    configureImpressionLoggingButton()
    configureInstrumentManager()
    configureInternalUtility()
    configureServerConfigurationManager()
    configureCloudBridge()
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
  }
}

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

  func configureAEMReporter() {
    if #available(iOS 14, *) {
      AEMReporter.configure(
        networker: components.aemNetworker,
        appID: components.settings.appID,
        reporter: components.skAdNetworkReporter
      )
    }
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
      errorFactory: components.errorFactory,
      dataStore: components.defaultDataStore
    )
  }

  func configureAppLinkNavigation() {
    AppLinkNavigation.setDependencies(
      .init(
        settings: components.settings,
        urlOpener: components.internalURLOpener,
        appLinkEventPoster: components.appLinkEventPoster,
        appLinkResolver: components.appLinkResolver
      )
    )
  }

  func configureAppLinkURL() {
    AppLinkURL.configure(
      settings: components.settings,
      appLinkFactory: components.appLinkFactory,
      appLinkTargetFactory: components.appLinkTargetFactory,
      appLinkEventPoster: components.appLinkEventPoster
    )
  }

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

  func configureAuthenticationStatusUtility() {
    _AuthenticationStatusUtility.configure(
      profileSetter: components.profileSetter,
      sessionDataTaskProvider: components.sessionDataTaskProvider,
      accessTokenWallet: components.accessTokenWallet,
      authenticationTokenWallet: components.authenticationTokenWallet
    )
  }

  func configureAuthenticationToken() {
    AuthenticationToken.tokenCache = components.tokenCache
  }

  func configureBridgeAPIRequest() {
    _BridgeAPIRequest.configure(
      internalURLOpener: components.internalURLOpener,
      internalUtility: components.internalUtility,
      settings: components.settings
    )
  }

  func configureButton() {
    FBButton.configure(
      applicationActivationNotifier: components.getApplicationActivationNotifier(),
      eventLogger: components.eventLogger,
      accessTokenProvider: components.accessTokenWallet
    )
  }

  func configureCloudBridge() {
    FBSDKAppEventsCAPIManager.shared.configure(
      factory: components.graphRequestFactory,
      settings: components.settings
    )
  }

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

  func configureCrashShield() {
    _CrashShield.configure(
      settings: components.settings,
      graphRequestFactory: components.graphRequestFactory,
      featureChecking: components.featureChecker
    )
  }

  func configureFeatureExtractor() {
    _FeatureExtractor.configure(rulesFromKeyProvider: components.rulesFromKeyProvider)
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

  func configureModelManager() {
    let settings = components.settings
    _ModelManager.shared.configure(
      featureChecker: components.featureChecker,
      graphRequestFactory: components.graphRequestFactory,
      fileManager: components.fileManager,
      store: components.defaultDataStore,
      getAppID: { [settings] in settings.appID ?? "" },
      dataExtractor: components.dataExtractor,
      gateKeeperManager: components.gateKeeperManager,
      suggestedEventsIndexer: components.suggestedEventsIndexer,
      featureExtractor: components.featureExtractor
    )
  }

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

  func configureServerConfigurationManager() {
    _ServerConfigurationManager.shared.configure(
      graphRequestFactory: components.graphRequestFactory,
      graphRequestConnectionFactory: components.graphRequestConnectionFactory,
      dialogConfigurationMapBuilder: components.dialogConfigurationMapBuilder
    )
  }

  func configureSettings() {
    Settings.shared.setDependencies(
      .init(
        appEventsConfigurationProvider: components.appEventsConfigurationProvider,
        dataStore: components.defaultDataStore,
        eventLogger: components.eventLogger,
        infoDictionaryProvider: components.infoDictionaryProvider
      )
    )
  }

  func configureProfile() {
    Profile.setDependencies(
      .init(
        accessTokenProvider: components.accessTokenWallet,
        dataStore: components.defaultDataStore,
        graphRequestFactory: components.graphRequestFactory,
        notificationCenter: components.notificationCenter,
        settings: components.settings,
        urlHoster: components.urlHoster
      )
    )
  }

  func configureWebDialogView() {
    FBWebDialogView.configure(
      webViewProvider: components.webViewProvider,
      urlOpener: components.internalURLOpener,
      errorFactory: components.errorFactory
    )
  }
}
