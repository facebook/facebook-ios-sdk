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

final class CoreKitComponents {

  // MARK: - All Platforms

  let accessTokenExpirer: _AccessTokenExpiring
  let accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type
  let advertiserIDProvider: _AdvertiserIDProviding
  let appEvents: _SourceApplicationTracking & _AppEventsConfiguring & _ApplicationLifecycleObserving
    & _ApplicationActivating & _ApplicationStateSetting & EventLogging
  let appEventsConfigurationProvider: _AppEventsConfigurationProviding
  let appEventsStateProvider: _AppEventsStateProviding
  let appEventsStateStore: _AppEventsStatePersisting
  let appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting
    & _AppEventsUtilityProtocol & _LoggingNotifying
  let atePublisherFactory: _ATEPublisherCreating
  let authenticationTokenWallet: _AuthenticationTokenProviding.Type
  let capiReporter: CAPIReporter
  let crashHandler: CrashHandlerProtocol
  let crashObserver: CrashObserving
  let defaultDataStore: DataPersisting
  let deviceInformationProvider: _DeviceInformationProviding
  let dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding
  let errorConfigurationProvider: _ErrorConfigurationProviding
  let errorFactory: ErrorCreating
  let errorReporter: ErrorReporting
  let eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing
  let eventLogger: EventLogging
  let featureChecker: FeatureChecking & _FeatureDisabling
  let gateKeeperManager: _GateKeeperManaging.Type
  let getApplicationActivationNotifier: () -> Any
  let graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol
  let graphRequestFactory: GraphRequestFactoryProtocol
  let impressionLoggerFactory: _ImpressionLoggerFactoryProtocol
  let infoDictionaryProvider: InfoDictionaryProviding
  let internalUtility: InternalUtilityProtocol
  let logger: Logging.Type
  let loggerFactory: _LoggerCreating
  let macCatalystDeterminator: _MacCatalystDetermining
  let notificationCenter: _NotificationPosting & NotificationDelivering
  let operatingSystemVersionComparer: _OperatingSystemVersionComparing
  let paymentObserver: _PaymentObserving
  let piggybackManager: _GraphRequestPiggybackManaging
  let restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing
  let serverConfigurationProvider: _ServerConfigurationProviding
  let settings: SettingsProtocol & SettingsLogging
  let timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording
  let tokenCache: TokenCaching
  let urlSessionProxyFactory: _URLSessionProxyProviding
  let userDataStore: _UserDataPersisting

  // MARK: - Non-tvOS

  #if !os(tvOS)

  @available(tvOS, unavailable)
  let aemNetworker: AEMNetworking?

  @available(tvOS, unavailable)
  let aemReporter: _AEMReporterProtocol.Type

  @available(tvOS, unavailable)
  let appEventParametersExtractor: _AppEventParametersExtracting

  @available(tvOS, unavailable)
  let appEventsDropDeterminer: _AppEventDropDetermining

  @available(tvOS, unavailable)
  let appLinkEventPoster: _AppLinkEventPosting

  @available(tvOS, unavailable)
  let appLinkFactory: _AppLinkCreating

  @available(tvOS, unavailable)
  let appLinkResolver: AppLinkResolving

  @available(tvOS, unavailable)
  let appLinkTargetFactory: _AppLinkTargetCreating

  @available(tvOS, unavailable)
  let appLinkURLFactory: _AppLinkURLCreating

  @available(tvOS, unavailable)
  let backgroundEventLogger: _BackgroundEventLogging

  @available(tvOS, unavailable)
  let codelessIndexer: _CodelessIndexing.Type

  @available(tvOS, unavailable)
  let dataExtractor: _FileDataExtracting.Type

  @available(tvOS, unavailable)
  let featureExtractor: _FeatureExtracting.Type

  @available(tvOS, unavailable)
  let fileManager: _FileManaging

  @available(tvOS, unavailable)
  let internalURLOpener: _InternalURLOpener

  @available(tvOS, unavailable)
  let metadataIndexer: _MetadataIndexing

  @available(tvOS, unavailable)
  let modelManager: _EventProcessing & _IntegrityParametersProcessorProvider

  @available(tvOS, unavailable)
  let profileSetter: ProfileProviding.Type

  @available(tvOS, unavailable)
  let rulesFromKeyProvider: _RulesFromKeyProvider

  @available(tvOS, unavailable)
  let sessionDataTaskProvider: URLSessionProviding

  @available(tvOS, unavailable)
  let skAdNetworkReporter: (_AppEventsReporter & SKAdNetworkReporting)?

  @available(tvOS, unavailable)
  let suggestedEventsIndexer: _SuggestedEventsIndexerProtocol

  @available(tvOS, unavailable)
  let swizzler: _Swizzling.Type

  @available(tvOS, unavailable)
  let urlHoster: URLHosting

  @available(tvOS, unavailable)
  let userIDProvider: _UserIDProviding

  @available(tvOS, unavailable)
  let webViewProvider: _WebViewProviding

  #endif

  // MARK: - Initializers

  #if !os(tvOS)

  @available(tvOS, unavailable)
  init(
    accessTokenExpirer: _AccessTokenExpiring,
    accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type,
    advertiserIDProvider: _AdvertiserIDProviding,
    appEvents: EventLogging & _AppEventsConfiguring & _ApplicationActivating & _ApplicationLifecycleObserving
      & _ApplicationStateSetting & _SourceApplicationTracking,
    appEventsConfigurationProvider: _AppEventsConfigurationProviding,
    appEventsStateProvider: _AppEventsStateProviding,
    appEventsStateStore: _AppEventsStatePersisting,
    appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtilityProtocol
      & _LoggingNotifying,
    atePublisherFactory: _ATEPublisherCreating,
    authenticationTokenWallet: _AuthenticationTokenProviding.Type,
    capiReporter: CAPIReporter,
    crashHandler: CrashHandlerProtocol,
    crashObserver: CrashObserving,
    defaultDataStore: DataPersisting,
    deviceInformationProvider: _DeviceInformationProviding,
    dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding,
    errorConfigurationProvider: _ErrorConfigurationProviding,
    errorFactory: ErrorCreating,
    errorReporter: ErrorReporting,
    eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing,
    eventLogger: EventLogging,
    featureChecker: FeatureChecking & _FeatureDisabling,
    gateKeeperManager: _GateKeeperManaging.Type,
    getApplicationActivationNotifier: @escaping () -> Any,
    graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol,
    graphRequestFactory: GraphRequestFactoryProtocol,
    impressionLoggerFactory: _ImpressionLoggerFactoryProtocol,
    infoDictionaryProvider: InfoDictionaryProviding,
    internalUtility: InternalUtilityProtocol,
    logger: Logging.Type,
    loggerFactory: _LoggerCreating,
    macCatalystDeterminator: _MacCatalystDetermining,
    notificationCenter: _NotificationPosting & NotificationDelivering,
    operatingSystemVersionComparer: _OperatingSystemVersionComparing,
    paymentObserver: _PaymentObserving,
    piggybackManager: _GraphRequestPiggybackManaging,
    restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing,
    serverConfigurationProvider: _ServerConfigurationProviding,
    settings: SettingsLogging & SettingsProtocol,
    timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording,
    tokenCache: TokenCaching,
    urlSessionProxyFactory: _URLSessionProxyProviding,
    userDataStore: _UserDataPersisting,
    aemNetworker: AEMNetworking?,
    aemReporter: _AEMReporterProtocol.Type,
    appEventParametersExtractor: _AppEventParametersExtracting,
    appEventsDropDeterminer: _AppEventDropDetermining,
    appLinkEventPoster: _AppLinkEventPosting,
    appLinkFactory: _AppLinkCreating,
    appLinkResolver: AppLinkResolving,
    appLinkTargetFactory: _AppLinkTargetCreating,
    appLinkURLFactory: _AppLinkURLCreating,
    backgroundEventLogger: _BackgroundEventLogging,
    codelessIndexer: _CodelessIndexing.Type,
    dataExtractor: _FileDataExtracting.Type,
    featureExtractor: _FeatureExtracting.Type,
    fileManager: _FileManaging,
    internalURLOpener: _InternalURLOpener,
    metadataIndexer: _MetadataIndexing,
    modelManager: _EventProcessing & _IntegrityParametersProcessorProvider,
    profileSetter: ProfileProviding.Type,
    rulesFromKeyProvider: _RulesFromKeyProvider,
    sessionDataTaskProvider: URLSessionProviding,
    skAdNetworkReporter: (SKAdNetworkReporting & _AppEventsReporter)?,
    suggestedEventsIndexer: _SuggestedEventsIndexerProtocol,
    swizzler: _Swizzling.Type,
    urlHoster: URLHosting,
    userIDProvider: _UserIDProviding,
    webViewProvider: _WebViewProviding
  ) {
    self.accessTokenExpirer = accessTokenExpirer
    self.accessTokenWallet = accessTokenWallet
    self.advertiserIDProvider = advertiserIDProvider
    self.appEvents = appEvents
    self.appEventsConfigurationProvider = appEventsConfigurationProvider
    self.appEventsStateProvider = appEventsStateProvider
    self.appEventsStateStore = appEventsStateStore
    self.appEventsUtility = appEventsUtility
    self.atePublisherFactory = atePublisherFactory
    self.authenticationTokenWallet = authenticationTokenWallet
    self.capiReporter = capiReporter
    self.crashHandler = crashHandler
    self.crashObserver = crashObserver
    self.defaultDataStore = defaultDataStore
    self.deviceInformationProvider = deviceInformationProvider
    self.dialogConfigurationMapBuilder = dialogConfigurationMapBuilder
    self.errorConfigurationProvider = errorConfigurationProvider
    self.errorFactory = errorFactory
    self.errorReporter = errorReporter
    self.eventDeactivationManager = eventDeactivationManager
    self.eventLogger = eventLogger
    self.featureChecker = featureChecker
    self.gateKeeperManager = gateKeeperManager
    self.getApplicationActivationNotifier = getApplicationActivationNotifier
    self.graphRequestConnectionFactory = graphRequestConnectionFactory
    self.graphRequestFactory = graphRequestFactory
    self.impressionLoggerFactory = impressionLoggerFactory
    self.infoDictionaryProvider = infoDictionaryProvider
    self.internalUtility = internalUtility
    self.logger = logger
    self.loggerFactory = loggerFactory
    self.macCatalystDeterminator = macCatalystDeterminator
    self.notificationCenter = notificationCenter
    self.operatingSystemVersionComparer = operatingSystemVersionComparer
    self.paymentObserver = paymentObserver
    self.piggybackManager = piggybackManager
    self.restrictiveDataFilterManager = restrictiveDataFilterManager
    self.serverConfigurationProvider = serverConfigurationProvider
    self.settings = settings
    self.timeSpentRecorder = timeSpentRecorder
    self.tokenCache = tokenCache
    self.urlSessionProxyFactory = urlSessionProxyFactory
    self.userDataStore = userDataStore
    self.aemNetworker = aemNetworker
    self.aemReporter = aemReporter
    self.appEventParametersExtractor = appEventParametersExtractor
    self.appEventsDropDeterminer = appEventsDropDeterminer
    self.appLinkEventPoster = appLinkEventPoster
    self.appLinkFactory = appLinkFactory
    self.appLinkResolver = appLinkResolver
    self.appLinkTargetFactory = appLinkTargetFactory
    self.appLinkURLFactory = appLinkURLFactory
    self.backgroundEventLogger = backgroundEventLogger
    self.codelessIndexer = codelessIndexer
    self.dataExtractor = dataExtractor
    self.featureExtractor = featureExtractor
    self.fileManager = fileManager
    self.internalURLOpener = internalURLOpener
    self.metadataIndexer = metadataIndexer
    self.modelManager = modelManager
    self.profileSetter = profileSetter
    self.rulesFromKeyProvider = rulesFromKeyProvider
    self.sessionDataTaskProvider = sessionDataTaskProvider
    self.skAdNetworkReporter = skAdNetworkReporter
    self.suggestedEventsIndexer = suggestedEventsIndexer
    self.swizzler = swizzler
    self.urlHoster = urlHoster
    self.userIDProvider = userIDProvider
    self.webViewProvider = webViewProvider
  }

  #else

  init(
    accessTokenExpirer: _AccessTokenExpiring,
    accessTokenWallet: (_AccessTokenProviding & _TokenStringProviding).Type,
    advertiserIDProvider: _AdvertiserIDProviding,
    appEvents: EventLogging & _AppEventsConfiguring & _ApplicationActivating & _ApplicationLifecycleObserving
      & _ApplicationStateSetting & _SourceApplicationTracking,
    appEventsConfigurationProvider: _AppEventsConfigurationProviding,
    appEventsStateProvider: _AppEventsStateProviding,
    appEventsStateStore: _AppEventsStatePersisting,
    appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtilityProtocol
      & _LoggingNotifying,
    atePublisherFactory: _ATEPublisherCreating,
    authenticationTokenWallet: _AuthenticationTokenProviding.Type,
    capiReporter: CAPIReporter,
    crashHandler: CrashHandlerProtocol,
    crashObserver: CrashObserving,
    defaultDataStore: DataPersisting,
    deviceInformationProvider: _DeviceInformationProviding,
    dialogConfigurationMapBuilder: _DialogConfigurationMapBuilding,
    errorConfigurationProvider: _ErrorConfigurationProviding,
    errorFactory: ErrorCreating,
    errorReporter: ErrorReporting,
    eventDeactivationManager: _AppEventsParameterProcessing & _EventsProcessing,
    eventLogger: EventLogging,
    featureChecker: FeatureChecking & _FeatureDisabling,
    gateKeeperManager: _GateKeeperManaging.Type,
    getApplicationActivationNotifier: @escaping () -> Any,
    graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol,
    graphRequestFactory: GraphRequestFactoryProtocol,
    impressionLoggerFactory: _ImpressionLoggerFactoryProtocol,
    infoDictionaryProvider: InfoDictionaryProviding,
    internalUtility: InternalUtilityProtocol,
    logger: Logging.Type,
    loggerFactory: _LoggerCreating,
    macCatalystDeterminator: _MacCatalystDetermining,
    notificationCenter: _NotificationPosting & NotificationDelivering,
    operatingSystemVersionComparer: _OperatingSystemVersionComparing,
    paymentObserver: _PaymentObserving,
    piggybackManager: _GraphRequestPiggybackManaging,
    restrictiveDataFilterManager: _AppEventsParameterProcessing & _EventsProcessing,
    serverConfigurationProvider: _ServerConfigurationProviding,
    settings: SettingsLogging & SettingsProtocol,
    timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording,
    tokenCache: TokenCaching,
    urlSessionProxyFactory: _URLSessionProxyProviding,
    userDataStore: _UserDataPersisting
  ) {
    self.accessTokenExpirer = accessTokenExpirer
    self.accessTokenWallet = accessTokenWallet
    self.advertiserIDProvider = advertiserIDProvider
    self.appEvents = appEvents
    self.appEventsConfigurationProvider = appEventsConfigurationProvider
    self.appEventsStateProvider = appEventsStateProvider
    self.appEventsStateStore = appEventsStateStore
    self.appEventsUtility = appEventsUtility
    self.atePublisherFactory = atePublisherFactory
    self.authenticationTokenWallet = authenticationTokenWallet
    self.capiReporter = capiReporter
    self.crashHandler = crashHandler
    self.crashObserver = crashObserver
    self.defaultDataStore = defaultDataStore
    self.deviceInformationProvider = deviceInformationProvider
    self.dialogConfigurationMapBuilder = dialogConfigurationMapBuilder
    self.errorConfigurationProvider = errorConfigurationProvider
    self.errorFactory = errorFactory
    self.errorReporter = errorReporter
    self.eventDeactivationManager = eventDeactivationManager
    self.eventLogger = eventLogger
    self.featureChecker = featureChecker
    self.gateKeeperManager = gateKeeperManager
    self.getApplicationActivationNotifier = getApplicationActivationNotifier
    self.graphRequestConnectionFactory = graphRequestConnectionFactory
    self.graphRequestFactory = graphRequestFactory
    self.impressionLoggerFactory = impressionLoggerFactory
    self.infoDictionaryProvider = infoDictionaryProvider
    self.internalUtility = internalUtility
    self.logger = logger
    self.loggerFactory = loggerFactory
    self.macCatalystDeterminator = macCatalystDeterminator
    self.notificationCenter = notificationCenter
    self.operatingSystemVersionComparer = operatingSystemVersionComparer
    self.paymentObserver = paymentObserver
    self.piggybackManager = piggybackManager
    self.restrictiveDataFilterManager = restrictiveDataFilterManager
    self.serverConfigurationProvider = serverConfigurationProvider
    self.settings = settings
    self.timeSpentRecorder = timeSpentRecorder
    self.tokenCache = tokenCache
    self.urlSessionProxyFactory = urlSessionProxyFactory
    self.userDataStore = userDataStore
  }
  #endif

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
    let piggybackManager: _GraphRequestPiggybackManaging = _GraphRequestPiggybackManager(
      tokenWallet: AccessToken.self,
      settings: Settings.shared,
      serverConfigurationProvider: _ServerConfigurationManager.shared,
      graphRequestFactory: graphRequestFactory
    )
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
    let tokenCache: TokenCaching = _TokenCache(settings: Settings.shared, keychainStore: keychainStore)
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
    let errorFactory: ErrorCreating = ErrorFactory(reporter: ErrorReporter.shared)
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

    #if !os(tvOS)
    var aemNetworker: AEMNetworking?
    if #available(iOS 14, *) {
      aemNetworker = __AEMNetworker()
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
    let backgroundEventLogger: _BackgroundEventLogging = _BackgroundEventLogger(
      infoDictionaryProvider: Bundle.main,
      eventLogger: AppEvents.shared
    )
    #endif

    #if os(tvOS)
    return CoreKitComponents(
      accessTokenExpirer: accessTokenExpirer,
      accessTokenWallet: accessTokenWallet,
      advertiserIDProvider: advertiserIDProvider,
      appEvents: appEvents,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      appEventsStateProvider: appEventsStateProvider,
      appEventsStateStore: appEventsStateStore,
      appEventsUtility: appEventsUtility,
      atePublisherFactory: atePublisherFactory,
      authenticationTokenWallet: authenticationTokenWallet,
      capiReporter: capiReporter,
      crashHandler: crashHandler,
      crashObserver: crashObserver,
      defaultDataStore: defaultDataStore,
      deviceInformationProvider: deviceInformationProvider,
      dialogConfigurationMapBuilder: dialogConfigurationMapBuilder,
      errorConfigurationProvider: errorConfigurationProvider,
      errorFactory: errorFactory,
      errorReporter: errorReporter,
      eventDeactivationManager: eventDeactivationManager,
      eventLogger: eventLogger,
      featureChecker: featureChecker,
      gateKeeperManager: gateKeeperManager,
      getApplicationActivationNotifier: getApplicationActivationNotifier,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      graphRequestFactory: graphRequestFactory,
      impressionLoggerFactory: impressionLoggerFactory,
      infoDictionaryProvider: infoDictionaryProvider,
      internalUtility: internalUtility,
      logger: logger,
      loggerFactory: loggerFactory,
      macCatalystDeterminator: macCatalystDeterminator,
      notificationCenter: notificationCenter,
      operatingSystemVersionComparer: operatingSystemVersionComparer,
      paymentObserver: paymentObserver,
      piggybackManager: piggybackManager,
      restrictiveDataFilterManager: restrictiveDataFilterManager,
      serverConfigurationProvider: serverConfigurationProvider,
      settings: settings,
      timeSpentRecorder: timeSpentRecorder,
      tokenCache: tokenCache,
      urlSessionProxyFactory: urlSessionProxyFactory,
      userDataStore: userDataStore
    )
    #else
    return CoreKitComponents(
      accessTokenExpirer: accessTokenExpirer,
      accessTokenWallet: accessTokenWallet,
      advertiserIDProvider: advertiserIDProvider,
      appEvents: appEvents,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      appEventsStateProvider: appEventsStateProvider,
      appEventsStateStore: appEventsStateStore,
      appEventsUtility: appEventsUtility,
      atePublisherFactory: atePublisherFactory,
      authenticationTokenWallet: authenticationTokenWallet,
      capiReporter: capiReporter,
      crashHandler: crashHandler,
      crashObserver: crashObserver,
      defaultDataStore: defaultDataStore,
      deviceInformationProvider: deviceInformationProvider,
      dialogConfigurationMapBuilder: dialogConfigurationMapBuilder,
      errorConfigurationProvider: errorConfigurationProvider,
      errorFactory: errorFactory,
      errorReporter: errorReporter,
      eventDeactivationManager: eventDeactivationManager,
      eventLogger: eventLogger,
      featureChecker: featureChecker,
      gateKeeperManager: gateKeeperManager,
      getApplicationActivationNotifier: getApplicationActivationNotifier,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      graphRequestFactory: graphRequestFactory,
      impressionLoggerFactory: impressionLoggerFactory,
      infoDictionaryProvider: infoDictionaryProvider,
      internalUtility: internalUtility,
      logger: logger,
      loggerFactory: loggerFactory,
      macCatalystDeterminator: macCatalystDeterminator,
      notificationCenter: notificationCenter,
      operatingSystemVersionComparer: operatingSystemVersionComparer,
      paymentObserver: paymentObserver,
      piggybackManager: piggybackManager,
      restrictiveDataFilterManager: restrictiveDataFilterManager,
      serverConfigurationProvider: serverConfigurationProvider,
      settings: settings,
      timeSpentRecorder: timeSpentRecorder,
      tokenCache: tokenCache,
      urlSessionProxyFactory: urlSessionProxyFactory,
      userDataStore: userDataStore,
      aemNetworker: aemNetworker,
      aemReporter: AEMReporter.self,
      appEventParametersExtractor: _AppEventsUtility.shared,
      appEventsDropDeterminer: _AppEventsUtility.shared,
      appLinkEventPoster: _MeasurementEvent(),
      appLinkFactory: _AppLinkFactory(),
      appLinkResolver: WebViewAppLinkResolver.shared,
      appLinkTargetFactory: AppLinkTargetFactory(),
      appLinkURLFactory: AppLinkURLFactory(),
      backgroundEventLogger: backgroundEventLogger,
      codelessIndexer: _CodelessIndexer.self,
      dataExtractor: NSData.self,
      featureExtractor: _FeatureExtractor.self,
      fileManager: FileManager.default,
      internalURLOpener: CoreUIApplication.shared,
      metadataIndexer: metaIndexer,
      modelManager: _ModelManager.shared,
      profileSetter: Profile.self,
      rulesFromKeyProvider: _ModelManager.shared,
      sessionDataTaskProvider: URLSession.shared,
      skAdNetworkReporter: skAdNetworkReporter,
      suggestedEventsIndexer: suggestedEventsIndexer,
      swizzler: _Swizzler.self,
      urlHoster: InternalUtility.shared,
      userIDProvider: AppEvents.shared,
      webViewProvider: _WebViewFactory()
    )
    #endif
  }()
}
