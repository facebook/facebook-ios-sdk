/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit

final class CoreKitComponents {
  let accessTokenExpirer: _AccessTokenExpiring
  let accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type
  let advertiserIDProvider: _AdvertiserIDProviding
  let aemNetworker: AEMNetworking?
  let aemReporter: _AEMReporterProtocol.Type
  let appEventParametersExtractor: _AppEventParametersExtracting
  let appEvents: _SourceApplicationTracking & _AppEventsConfiguring & _ApplicationLifecycleObserving
    & _ApplicationActivating & _ApplicationStateSetting & EventLogging
  let appEventsConfigurationProvider: _AppEventsConfigurationProviding
  let appEventsDropDeterminer: _AppEventDropDetermining
  let appEventsStateProvider: _AppEventsStateProviding
  let appEventsStateStore: _AppEventsStatePersisting
  let appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting
    & _AppEventsUtilityProtocol & _LoggingNotifying
  let appLinkEventPoster: _AppLinkEventPosting
  let appLinkFactory: _AppLinkCreating
  let appLinkResolver: AppLinkResolving
  let appLinkTargetFactory: _AppLinkTargetCreating
  let appLinkURLFactory: _AppLinkURLCreating
  let atePublisherFactory: _ATEPublisherCreating
  let authenticationTokenWallet: _AuthenticationTokenProviding.Type
  let backgroundEventLogger: BackgroundEventLogging
  let capiReporter: CAPIReporter
  let codelessIndexer: _CodelessIndexing.Type
  let crashHandler: CrashHandlerProtocol
  let crashObserver: CrashObserving
  let dataExtractor: _FileDataExtracting.Type
  let defaultDataStore: DataPersisting
  let deviceInformationProvider: _DeviceInformationProviding
  let dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding
  let errorConfigurationProvider: _ErrorConfigurationProviding
  let errorFactory: ErrorCreating
  let errorReporter: ErrorReporting
  let eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing
  let eventLogger: EventLogging
  let featureChecker: FeatureChecking & _FeatureDisabling
  let featureExtractor: _FeatureExtracting.Type
  let fileManager: _FileManaging
  let gateKeeperManager: _GateKeeperManaging.Type
  let getApplicationActivationNotifier: () -> Any
  let graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol
  let graphRequestFactory: GraphRequestFactoryProtocol
  let impressionLoggerFactory: _ImpressionLoggerFactoryProtocol
  let infoDictionaryProvider: InfoDictionaryProviding
  let internalURLOpener: _InternalURLOpener
  let internalUtility: InternalUtilityProtocol
  let logger: Logging.Type
  let loggerFactory: _LoggerCreating
  let macCatalystDeterminator: _MacCatalystDetermining
  let metadataIndexer: _MetadataIndexing
  let modelManager: _EventProcessing & _IntegrityParametersProcessorProvider
  let notificationCenter: _NotificationPosting & NotificationDelivering
  let operatingSystemVersionComparer: _OperatingSystemVersionComparing
  let paymentObserver: _PaymentObserving
  let piggybackManager: _GraphRequestPiggybackManaging
  let profileSetter: ProfileProviding.Type
  let restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing
  let rulesFromKeyProvider: _RulesFromKeyProvider
  let serverConfigurationProvider: _ServerConfigurationProviding
  let sessionDataTaskProvider: URLSessionProviding
  let settings: SettingsProtocol & SettingsLogging
  let skAdNetworkReporter: (_AppEventsReporter & SKAdNetworkReporting)?
  let suggestedEventsIndexer: _SuggestedEventsIndexerProtocol
  let swizzler: _Swizzling.Type
  let timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording
  let tokenCache: TokenCaching
  let urlHoster: URLHosting
  let urlSessionProxyFactory: _URLSessionProxyProviding
  let userDataStore: _UserDataPersisting
  let userIDProvider: _UserIDProviding
  let webViewProvider: _WebViewProviding

  // MARK: - Initializers

  init(
    accessTokenExpirer: _AccessTokenExpiring,
    accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type,
    advertiserIDProvider: _AdvertiserIDProviding,
    aemNetworker: AEMNetworking?,
    aemReporter: _AEMReporterProtocol.Type,
    appEventParametersExtractor: _AppEventParametersExtracting,
    appEvents: EventLogging & _AppEventsConfiguring & _ApplicationActivating & _ApplicationLifecycleObserving & _ApplicationStateSetting & _SourceApplicationTracking, // swiftlint:disable:this line_length
    appEventsConfigurationProvider: _AppEventsConfigurationProviding,
    appEventsDropDeterminer: _AppEventDropDetermining,
    appEventsStateProvider: _AppEventsStateProviding,
    appEventsStateStore: _AppEventsStatePersisting,
    appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtilityProtocol & _LoggingNotifying, // swiftlint:disable:this line_length
    appLinkEventPoster: _AppLinkEventPosting,
    appLinkFactory: _AppLinkCreating,
    appLinkResolver: AppLinkResolving,
    appLinkTargetFactory: _AppLinkTargetCreating,
    appLinkURLFactory: _AppLinkURLCreating,
    atePublisherFactory: _ATEPublisherCreating,
    authenticationTokenWallet: _AuthenticationTokenProviding.Type,
    backgroundEventLogger: BackgroundEventLogging,
    capiReporter: CAPIReporter,
    codelessIndexer: _CodelessIndexing.Type,
    crashHandler: CrashHandlerProtocol,
    crashObserver: CrashObserving,
    dataExtractor: _FileDataExtracting.Type,
    defaultDataStore: DataPersisting,
    deviceInformationProvider: _DeviceInformationProviding,
    dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding,
    errorConfigurationProvider: _ErrorConfigurationProviding,
    errorFactory: ErrorCreating,
    errorReporter: ErrorReporting,
    eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing,
    eventLogger: EventLogging,
    featureChecker: FeatureChecking & _FeatureDisabling,
    featureExtractor: _FeatureExtracting.Type,
    fileManager: _FileManaging,
    gateKeeperManager: _GateKeeperManaging.Type,
    getApplicationActivationNotifier: @escaping () -> Any,
    graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol,
    graphRequestFactory: GraphRequestFactoryProtocol,
    impressionLoggerFactory: _ImpressionLoggerFactoryProtocol,
    infoDictionaryProvider: InfoDictionaryProviding,
    internalURLOpener: _InternalURLOpener,
    internalUtility: InternalUtilityProtocol,
    logger: Logging.Type,
    loggerFactory: _LoggerCreating,
    macCatalystDeterminator: _MacCatalystDetermining,
    metadataIndexer: _MetadataIndexing,
    modelManager: _EventProcessing & _IntegrityParametersProcessorProvider,
    notificationCenter: _NotificationPosting & NotificationDelivering,
    operatingSystemVersionComparer: _OperatingSystemVersionComparing,
    paymentObserver: _PaymentObserving,
    piggybackManager: _GraphRequestPiggybackManaging,
    profileSetter: ProfileProviding.Type,
    restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing,
    rulesFromKeyProvider: _RulesFromKeyProvider,
    serverConfigurationProvider: _ServerConfigurationProviding,
    sessionDataTaskProvider: URLSessionProviding,
    settings: SettingsLogging & SettingsProtocol,
    skAdNetworkReporter: (SKAdNetworkReporting & _AppEventsReporter)?,
    suggestedEventsIndexer: _SuggestedEventsIndexerProtocol,
    swizzler: _Swizzling.Type,
    timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording,
    tokenCache: TokenCaching,
    urlHoster: URLHosting,
    urlSessionProxyFactory: _URLSessionProxyProviding,
    userDataStore: _UserDataPersisting,
    userIDProvider: _UserIDProviding,
    webViewProvider: _WebViewProviding
  ) {
    self.accessTokenExpirer = accessTokenExpirer
    self.accessTokenWallet = accessTokenWallet
    self.advertiserIDProvider = advertiserIDProvider
    self.aemNetworker = aemNetworker
    self.aemReporter = aemReporter
    self.appEventParametersExtractor = appEventParametersExtractor
    self.appEvents = appEvents
    self.appEventsConfigurationProvider = appEventsConfigurationProvider
    self.appEventsDropDeterminer = appEventsDropDeterminer
    self.appEventsStateProvider = appEventsStateProvider
    self.appEventsStateStore = appEventsStateStore
    self.appEventsUtility = appEventsUtility
    self.appLinkEventPoster = appLinkEventPoster
    self.appLinkFactory = appLinkFactory
    self.appLinkResolver = appLinkResolver
    self.appLinkTargetFactory = appLinkTargetFactory
    self.appLinkURLFactory = appLinkURLFactory
    self.atePublisherFactory = atePublisherFactory
    self.authenticationTokenWallet = authenticationTokenWallet
    self.backgroundEventLogger = backgroundEventLogger
    self.capiReporter = capiReporter
    self.codelessIndexer = codelessIndexer
    self.crashHandler = crashHandler
    self.crashObserver = crashObserver
    self.dataExtractor = dataExtractor
    self.defaultDataStore = defaultDataStore
    self.deviceInformationProvider = deviceInformationProvider
    self.dialogConfigurationMapBuilder = dialogConfigurationMapBuilder
    self.errorConfigurationProvider = errorConfigurationProvider
    self.errorFactory = errorFactory
    self.errorReporter = errorReporter
    self.eventDeactivationManager = eventDeactivationManager
    self.eventLogger = eventLogger
    self.featureChecker = featureChecker
    self.featureExtractor = featureExtractor
    self.fileManager = fileManager
    self.gateKeeperManager = gateKeeperManager
    self.getApplicationActivationNotifier = getApplicationActivationNotifier
    self.graphRequestConnectionFactory = graphRequestConnectionFactory
    self.graphRequestFactory = graphRequestFactory
    self.impressionLoggerFactory = impressionLoggerFactory
    self.infoDictionaryProvider = infoDictionaryProvider
    self.internalURLOpener = internalURLOpener
    self.internalUtility = internalUtility
    self.logger = logger
    self.loggerFactory = loggerFactory
    self.macCatalystDeterminator = macCatalystDeterminator
    self.metadataIndexer = metadataIndexer
    self.modelManager = modelManager
    self.notificationCenter = notificationCenter
    self.operatingSystemVersionComparer = operatingSystemVersionComparer
    self.paymentObserver = paymentObserver
    self.piggybackManager = piggybackManager
    self.profileSetter = profileSetter
    self.restrictiveDataFilterManager = restrictiveDataFilterManager
    self.rulesFromKeyProvider = rulesFromKeyProvider
    self.serverConfigurationProvider = serverConfigurationProvider
    self.sessionDataTaskProvider = sessionDataTaskProvider
    self.settings = settings
    self.skAdNetworkReporter = skAdNetworkReporter
    self.suggestedEventsIndexer = suggestedEventsIndexer
    self.swizzler = swizzler
    self.timeSpentRecorder = timeSpentRecorder
    self.tokenCache = tokenCache
    self.urlHoster = urlHoster
    self.urlSessionProxyFactory = urlSessionProxyFactory
    self.userDataStore = userDataStore
    self.userIDProvider = userIDProvider
    self.webViewProvider = webViewProvider
  }

  // MARK: - Default components

  static let `default`: CoreKitComponents = {
    let graphRequestFactory: GraphRequestFactoryProtocol = GraphRequestFactory()
    let atePublisherFactory: _ATEPublisherCreating = _ATEPublisherFactory(
      dataStore: UserDefaults.standard,
      graphRequestFactory: graphRequestFactory,
      settings: Settings.shared,
      deviceInformationProvider: _AppEventsDeviceInfo.shared
    )
    let crashObserver: CrashObserving = _CrashObserver(
      featureChecker: _FeatureManager.shared,
      graphRequestFactory: graphRequestFactory,
      settings: Settings.shared,
      crashHandler: CrashHandler.shared
    )
    let impressionLoggerFactory: _ImpressionLoggerFactoryProtocol = _ImpressionLoggerFactory(
      graphRequestFactory: graphRequestFactory,
      eventLogger: AppEvents.shared,
      notificationCenter: NotificationCenter.default,
      accessTokenWallet: AccessToken.self
    )
    let loggerFactory: _LoggerCreating = _LoggerFactory()

    _PaymentProductRequestorFactory.setDependencies(
      .init(
        settings: Settings.shared,
        eventLogger: AppEvents.shared,
        gateKeeperManager: _GateKeeperManager.self,
        store: UserDefaults.standard,
        loggerFactory: loggerFactory,
        productsRequestFactory: _ProductRequestFactory(),
        appStoreReceiptProvider: Bundle(for: ApplicationDelegate.self)
      )
    )

    let paymentProductRequestorFactory: _PaymentProductRequestorCreating = _PaymentProductRequestorFactory()

    let paymentObserver: _PaymentObserving = _PaymentObserver(
      paymentQueue: SKPaymentQueue.default(),
      paymentProductRequestorFactory: paymentProductRequestorFactory
    )
    let piggybackManager: _GraphRequestPiggybackManaging = GraphRequestPiggybackManager()
    let timeSpentRecorder: (_SourceApplicationTracking & _TimeSpentRecording) = _TimeSpentData(
      eventLogger: AppEvents.shared,
      serverConfigurationProvider: _ServerConfigurationManager.shared
    )

    let keychainStoreFactory: KeychainStoreProviding = KeychainStoreFactory()
    let keychainService = "\(DefaultKeychainServicePrefix).\(Bundle.main.bundleIdentifier ?? "nil")"
    let keychainStore: KeychainStoreProtocol = keychainStoreFactory.createKeychainStore(
      service: keychainService,
      accessGroup: nil
    )
    var tokenCache = TokenCache()
    tokenCache.setDependencies(
      .init(
        settings: Settings.shared,
        keychainStore: keychainStore,
        dataStore: UserDefaults.standard
      )
    )

    let userDataStore: _UserDataPersisting = _UserDataStore()
    let capiReporter: CAPIReporter = AppEventsCAPIManager.shared

    let accessTokenExpirer: _AccessTokenExpiring = _AccessTokenExpirer(notificationCenter: NotificationCenter.default)
    let accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type = AccessToken.self
    let advertiserIDProvider: _AdvertiserIDProviding = _AppEventsUtility.shared
    let appEvents: _SourceApplicationTracking & _AppEventsConfiguring & _ApplicationLifecycleObserving
      & _ApplicationActivating & _ApplicationStateSetting & EventLogging = AppEvents.shared
    let appEventsConfigurationProvider: _AppEventsConfigurationProviding = _AppEventsConfigurationManager.shared
    let appEventsStateProvider: _AppEventsStateProviding = AppEventsStateFactory()
    let appEventsStateStore: _AppEventsStatePersisting = _AppEventsStateManager.shared
    let appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtility
      & _LoggingNotifying = _AppEventsUtility.shared
    let authenticationTokenWallet: _AuthenticationTokenProviding.Type = AuthenticationToken.self
    let crashHandler: CrashHandlerProtocol = CrashHandler.shared
    let defaultDataStore: DataPersisting = UserDefaults.standard
    let deviceInformationProvider: _DeviceInformationProviding = _AppEventsDeviceInfo.shared
    let dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding = _DialogConfigurationMapBuilder()
    let errorConfigurationProvider: _ErrorConfigurationProviding = _ErrorConfigurationProvider()
    let errorFactory: ErrorCreating = _ErrorFactory()
    let errorReporter: ErrorReporting = ErrorReporter.shared
    let eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing = EventDeactivationManager()
    let eventLogger: EventLogging = AppEvents.shared
    let featureChecker: FeatureChecking & _FeatureDisabling = _FeatureManager.shared
    let gateKeeperManager: _GateKeeperManaging.Type = _GateKeeperManager.self
    let getApplicationActivationNotifier: () -> Any = { ApplicationDelegate.shared }
    let graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol = GraphRequestConnectionFactory()
    let infoDictionaryProvider: InfoDictionaryProviding = Bundle.main
    let internalUtility: InternalUtilityProtocol = InternalUtility.shared
    let logger: Logging.Type = _Logger.self
    let macCatalystDeterminator: _MacCatalystDetermining = ProcessInfo.processInfo
    let notificationCenter: _NotificationPosting & NotificationDelivering = NotificationCenter.default
    let operatingSystemVersionComparer: _OperatingSystemVersionComparing = ProcessInfo.processInfo
    let restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing =
      _RestrictiveDataFilterManager(serverConfigurationProvider: _ServerConfigurationManager.shared)
    let serverConfigurationProvider: _ServerConfigurationProviding = _ServerConfigurationManager.shared
    let settings: SettingsProtocol & SettingsLogging = Settings.shared
    let urlSessionProxyFactory: _URLSessionProxyProviding = _URLSessionProxyFactory()

    var aemNetworker: AEMNetworking?
    if #available(iOS 14, *) {
      aemNetworker = AEMNetworker()
    }

    var skAdNetworkReporter: (_AppEventsReporter & SKAdNetworkReporting)?
    skAdNetworkReporter = _SKAdNetworkReporter(
      graphRequestFactory: graphRequestFactory,
      dataStore: UserDefaults.standard,
      conversionValueUpdater: SKAdNetwork.self
    )

    let metaIndexer: _MetadataIndexing = _MetadataIndexer(userDataStore: userDataStore, swizzler: _Swizzler.self)
    let suggestedEventsIndexer: _SuggestedEventsIndexerProtocol = _SuggestedEventsIndexer(
      graphRequestFactory: graphRequestFactory,
      serverConfigurationProvider: _ServerConfigurationManager.shared,
      swizzler: _Swizzler.self,
      settings: Settings.shared,
      eventLogger: AppEvents.shared,
      featureExtractor: _FeatureExtractor.self,
      eventProcessor: _ModelManager.shared
    )
    let backgroundEventLogger: BackgroundEventLogging = BackgroundEventLogger()

    return CoreKitComponents(
      accessTokenExpirer: accessTokenExpirer,
      accessTokenWallet: accessTokenWallet,
      advertiserIDProvider: advertiserIDProvider,
      aemNetworker: aemNetworker,
      aemReporter: AEMReporter.self,
      appEventParametersExtractor: _AppEventsUtility.shared,
      appEvents: appEvents,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      appEventsDropDeterminer: _AppEventsUtility.shared,
      appEventsStateProvider: appEventsStateProvider,
      appEventsStateStore: appEventsStateStore,
      appEventsUtility: appEventsUtility,
      appLinkEventPoster: _MeasurementEvent(),
      appLinkFactory: AppLinkFactory(),
      appLinkResolver: WebViewAppLinkResolver.shared,
      appLinkTargetFactory: AppLinkTargetFactory(),
      appLinkURLFactory: AppLinkURLFactory(),
      atePublisherFactory: atePublisherFactory,
      authenticationTokenWallet: authenticationTokenWallet,
      backgroundEventLogger: backgroundEventLogger,
      capiReporter: capiReporter,
      codelessIndexer: _CodelessIndexer.self,
      crashHandler: crashHandler,
      crashObserver: crashObserver,
      dataExtractor: NSData.self,
      defaultDataStore: defaultDataStore,
      deviceInformationProvider: deviceInformationProvider,
      dialogConfigurationMapBuilder: dialogConfigurationMapBuilder,
      errorConfigurationProvider: errorConfigurationProvider,
      errorFactory: errorFactory,
      errorReporter: errorReporter,
      eventDeactivationManager: eventDeactivationManager,
      eventLogger: eventLogger,
      featureChecker: featureChecker,
      featureExtractor: _FeatureExtractor.self,
      fileManager: FileManager.default,
      gateKeeperManager: gateKeeperManager,
      getApplicationActivationNotifier: getApplicationActivationNotifier,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      graphRequestFactory: graphRequestFactory,
      impressionLoggerFactory: impressionLoggerFactory,
      infoDictionaryProvider: infoDictionaryProvider,
      internalURLOpener: CoreUIApplication.shared,
      internalUtility: internalUtility,
      logger: logger,
      loggerFactory: loggerFactory,
      macCatalystDeterminator: macCatalystDeterminator,
      metadataIndexer: metaIndexer,
      modelManager: _ModelManager.shared,
      notificationCenter: notificationCenter,
      operatingSystemVersionComparer: operatingSystemVersionComparer,
      paymentObserver: paymentObserver,
      piggybackManager: piggybackManager,
      profileSetter: Profile.self,
      restrictiveDataFilterManager: restrictiveDataFilterManager,
      rulesFromKeyProvider: _ModelManager.shared,
      serverConfigurationProvider: serverConfigurationProvider,
      sessionDataTaskProvider: URLSession.shared,
      settings: settings,
      skAdNetworkReporter: skAdNetworkReporter,
      suggestedEventsIndexer: suggestedEventsIndexer,
      swizzler: _Swizzler.self,
      timeSpentRecorder: timeSpentRecorder,
      tokenCache: tokenCache,
      urlHoster: InternalUtility.shared,
      urlSessionProxyFactory: urlSessionProxyFactory,
      userDataStore: userDataStore,
      userIDProvider: AppEvents.shared,
      webViewProvider: _WebViewFactory()
    )
  }()
}
