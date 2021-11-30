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

class ApplicationDelegateTests: XCTestCase { // swiftlint:disable:this type_body_length

  // swiftlint:disable implicitly_unwrapped_optional
  var notificationCenter: TestNotificationCenter!
  var featureChecker: TestFeatureManager!
  var appEvents: TestAppEvents!
  var userDataStore: UserDefaultsSpy!
  var observer: TestApplicationDelegateObserver!
  var settings: TestSettings!
  var backgroundEventLogger: TestBackgroundEventLogger!
  var serverConfigurationProvider: TestServerConfigurationProvider!
  let bitmaskKey = "com.facebook.sdk.kits.bitmask"
  var paymentObserver: TestPaymentObserver!
  var profile: Profile!
  var delegate: ApplicationDelegate! // swiftlint:disable:this weak_delegate
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    resetTestDependencies()

    notificationCenter = TestNotificationCenter()
    featureChecker = TestFeatureManager()
    appEvents = TestAppEvents()
    userDataStore = UserDefaultsSpy()
    observer = TestApplicationDelegateObserver()
    settings = TestSettings()
    backgroundEventLogger = TestBackgroundEventLogger(
      infoDictionaryProvider: TestBundle(),
      eventLogger: TestAppEvents()
    )
    serverConfigurationProvider = TestServerConfigurationProvider()
    paymentObserver = TestPaymentObserver()
    profile = Profile(
      userID: name,
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: nil,
      linkURL: nil,
      refreshDate: nil
    )
    delegate = ApplicationDelegate(
      notificationCenter: notificationCenter,
      tokenWallet: TestAccessTokenWallet.self,
      settings: settings,
      featureChecker: featureChecker,
      appEvents: appEvents,
      serverConfigurationProvider: serverConfigurationProvider,
      store: userDataStore,
      authenticationTokenWallet: TestAuthenticationTokenWallet.self,
      profileProvider: TestProfileProvider.self,
      backgroundEventLogger: backgroundEventLogger,
      paymentObserver: paymentObserver
    )

    delegate.resetApplicationObserverCache()
  }

  override func tearDown() {
    notificationCenter = nil
    featureChecker = nil
    appEvents = nil
    userDataStore = nil
    observer = nil
    settings = nil
    backgroundEventLogger = nil
    serverConfigurationProvider = nil
    paymentObserver = nil
    profile = nil
    delegate = nil

    resetTestDependencies()

    super.tearDown()
  }

  func resetTestDependencies() {
    ApplicationDelegate.reset()
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    TestGateKeeperManager.reset()
    TestProfileProvider.reset()
  }

  func testDefaultDependencies() {
    delegate = ApplicationDelegate.shared

    XCTAssertEqual(
      delegate.notificationObserver as? NotificationCenter,
      NotificationCenter.default,
      "Should use the default system notification center"
    )
    XCTAssertTrue(
      delegate.tokenWallet is AccessToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertEqual(
      delegate.featureChecker as? FeatureManager,
      FeatureManager.shared,
      "Should use the default feature checker"
    )
    XCTAssertEqual(
      delegate.appEvents as? AppEvents,
      AppEvents.shared,
      "Should use the expected default app events instance"
    )
    XCTAssertTrue(
      delegate.serverConfigurationProvider is ServerConfigurationManager,
      "Should use the expected default server configuration provider"
    )
    XCTAssertEqual(
      delegate.store as? UserDefaults,
      UserDefaults.standard,
      "Should use the expected default persistent store"
    )
    XCTAssertTrue(
      delegate.authenticationTokenWallet is AuthenticationToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertTrue(
      delegate.settings === Settings.shared,
      "Should use the expected default settings"
    )
    XCTAssertTrue(
      delegate.paymentObserver is PaymentObserver,
      "Should use the expected concrete payment observer"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      delegate.notificationObserver is TestNotificationCenter,
      "Should be able to create with a custom notification center"
    )
    XCTAssertTrue(
      delegate.tokenWallet is TestAccessTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
    XCTAssertEqual(
      delegate.featureChecker as? TestFeatureManager,
      featureChecker,
      "Should be able to create with a feature checker"
    )
    XCTAssertEqual(
      delegate.appEvents as? TestAppEvents,
      appEvents,
      "Should be able to create with an app events instance"
    )
    XCTAssertTrue(
      delegate.serverConfigurationProvider is TestServerConfigurationProvider,
      "Should be able to create with a server configuration provider"
    )
    XCTAssertEqual(
      delegate.store as? UserDefaultsSpy,
      userDataStore,
      "Should be able to create with a persistent store"
    )
    XCTAssertTrue(
      delegate.authenticationTokenWallet is TestAuthenticationTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
    XCTAssertEqual(
      delegate.settings as? TestSettings,
      settings,
      "Should be able to create with custom settings"
    )
    XCTAssertEqual(
      delegate.backgroundEventLogger as? TestBackgroundEventLogger,
      backgroundEventLogger,
      "Should be able to create with custom background event logger"
    )
  }

  func testCreatingSetsExpirer() throws {
    let delegateCenter = try XCTUnwrap(delegate.notificationObserver as? TestNotificationCenter)
    let expirerCenter = try XCTUnwrap(delegate.accessTokenExpirer.notificationCenter as? TestNotificationCenter)

    XCTAssertEqual(
      expirerCenter,
      delegateCenter,
      "Should create the token expirer using the delegate's notification center"
    )
  }

  func testCreatingConfiguresPaymentProductRequestorFactory() throws {
    let paymentObserver = try XCTUnwrap(ApplicationDelegate.shared.paymentObserver as? PaymentObserver)
    let factory = try XCTUnwrap(paymentObserver.requestorFactory as? PaymentProductRequestorFactory)

    XCTAssertTrue(
      factory.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertTrue(
      factory.eventLogger === AppEvents.shared,
      "Should be configured with the expected concrete event logger"
    )
    XCTAssertTrue(
      factory.gateKeeperManager is GateKeeperManager.Type,
      "Should be configured with the expected concrete gate keeper manager"
    )
    XCTAssertTrue(
      factory.store === UserDefaults.standard,
      "Should be configured with the expected persistent data store"
    )
    XCTAssertTrue(
      factory.loggerFactory is LoggerFactory,
      "Should be configured with the expected concrete logger factory"
    )
    XCTAssertTrue(
      factory.productsRequestFactory is ProductRequestFactory
    )
    XCTAssertTrue(
      factory.appStoreReceiptProvider is Bundle,
      "Should be configured with the expected concrete app store receipt provider"
    )
  }

  // MARK: - Initializing SDK

  func testInitializingSdkAddsBridgeApiObserver() {
    delegate.initializeSDK()

    XCTAssertTrue(
      delegate.applicationObservers.contains(BridgeAPI.shared),
      "Should add the shared bridge api instance to the application observers"
    )
  }

  func testInitializingSdkPerformsSettingsLogging() {
    delegate.initializeSDK()
    XCTAssertEqual(
      settings.logWarningsCallCount,
      1,
      "Should have settings log warnings upon initialization"
    )
    XCTAssertEqual(
      settings.logIfSDKSettingsChangedCallCount,
      1,
      "Should have settings log if there were changes upon initialization"
    )
    XCTAssertEqual(
      settings.recordInstallCallCount,
      1,
      "Should have settings record installations upon initialization"
    )
  }

  func testInitializingSdkPerformsBackgroundEventLogging() {
    delegate.initializeSDK()
    XCTAssertEqual(
      backgroundEventLogger.logBackgroundRefresStatusCallCount,
      1,
      "Should have background event logger log background refresh status upon initialization"
    )
  }

  func testInitializingSdkChecksInstrumentFeature() {
    delegate.initializeSDK()
    XCTAssert(
      featureChecker.capturedFeaturesContains(.instrument),
      "Should check if the instrument feature is enabled on initialization"
    )
  }

  func testDidFinishLaunchingLaunchedApp() {
    delegate.isAppLaunched = true

    XCTAssertFalse(
      delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil),
      "Should return false if the application is already launched"
    )
  }

  func testDidFinishLaunchingSetsCurrentAccessTokenWithCache() {
    let expected = SampleAccessTokens.validToken
    let cache = TestTokenCache(
      accessToken: expected,
      authenticationToken: nil
    )
    TestAccessTokenWallet.tokenCache = cache

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      TestAccessTokenWallet.currentAccessToken,
      expected,
      "Should set the current access token to the cached access token when it exists"
    )
  }

  func testDidFinishLaunchingSetsCurrentAccessTokenWithoutCache() {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    TestAccessTokenWallet.tokenCache = TestTokenCache(
      accessToken: nil,
      authenticationToken: nil
    )

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertNil(
      TestAccessTokenWallet.currentAccessToken,
      "Should set the current access token to nil access token when there isn't a cached token"
    )
  }

  func testDidFinishLaunchingSetsCurrentAuthenticationTokenWithCache() {
    let expected = SampleAuthenticationToken.validToken
    TestAuthenticationTokenWallet.tokenCache = TestTokenCache(
      accessToken: nil,
      authenticationToken: expected
    )
    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      TestAuthenticationTokenWallet.currentAuthenticationToken,
      expected,
      "Should set the current authentication token to the cached access token when it exists"
    )
  }

  func testDidFinishLaunchingSetsCurrentAuthenticationTokenWithoutCache() {
    TestAuthenticationTokenWallet.tokenCache = TestTokenCache(
      accessToken: nil,
      authenticationToken: nil
    )

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertNil(
      TestAuthenticationTokenWallet.currentAuthenticationToken,
      "Should set the current authentication token to nil access token when there isn't a cached token"
    )
  }

  func testDidFinishLaunchingWithAutoLogEnabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = true
    userDataStore.set(1, forKey: bitmaskKey)

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      appEvents.capturedEventName,
      .initializeSDK,
      "Should log initialization when auto log app events is enabled"
    )
  }

  func testDidFinishLaunchingWithAutoLogDisabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = false
    userDataStore.set(1, forKey: bitmaskKey)

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertNil(
      appEvents.capturedEventName,
      "Should not log initialization when auto log app events are disabled"
    )
  }

  func testDidFinishLaunchingWithObservers() {
    delegate.isAppLaunched = false

    let observer1 = TestApplicationDelegateObserver()
    let observer2 = TestApplicationDelegateObserver()

    delegate.addObserver(observer1)
    delegate.addObserver(observer2)

    let notifiedObservers = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      observer1.didFinishLaunchingCallCount,
      1,
      "Should invoke did finish launching on all observers"
    )
    XCTAssertEqual(
      observer2.didFinishLaunchingCallCount,
      1,
      "Should invoke did finish launching on all observers"
    )
    XCTAssertTrue(notifiedObservers, "Should indicate if observers were notified")
  }

  func testDidFinishLaunchingWithoutObservers() {
    let notifiedObservers = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertFalse(notifiedObservers, "Should indicate if no observers were notified")
  }

  func testAppEventsEnabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = true

    let notification = Notification(
      name: UIApplication.didBecomeActiveNotification,
      object: self,
      userInfo: nil
    )
    delegate.applicationDidBecomeActive(notification)

    XCTAssertTrue(
      appEvents.wasActivateAppCalled,
      "Should have app events activate the app when autolog app events is enabled"
    )
    XCTAssertEqual(
      appEvents.capturedApplicationState,
      .active,
      "Should set the application state to active when the notification is received"
    )
  }

  func testAppEventsDisabled() {
    settings.stubbedIsAutoLogAppEventsEnabled = false

    let notification = Notification(
      name: UIApplication.didBecomeActiveNotification,
      object: self,
      userInfo: nil
    )
    delegate.applicationDidBecomeActive(notification)

    XCTAssertFalse(
      appEvents.wasActivateAppCalled,
      "Should not have app events activate the app when autolog app events is enabled"
    )
    XCTAssertEqual(
      appEvents.capturedApplicationState,
      .active,
      "Should set the application state to active when the notification is received"
    )
  }

  func testSettingApplicationState() {
    delegate.setApplicationState(.background)
    XCTAssertEqual(
      appEvents.capturedApplicationState,
      .background,
      "The value of applicationState after calling setApplicationState should be UIApplicationStateBackground"
    )
  }

  func testInitializingSdkEnablesGraphRequests() {
    GraphRequestConnection.resetCanMakeRequests()
    delegate.initializeSDK()

    XCTAssertTrue(
      GraphRequestConnection.canMakeRequests,
      "Initializing the SDK should enable making graph requests"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresEventsProcessorsForAppEventsState() throws {
    AppEvents.reset()
    delegate.initializeSDK()

    XCTAssertEqual(AppEventsState.eventProcessors?.count, 2)
    XCTAssertTrue(
      AppEventsState.eventProcessors?.first === appEvents.capturedConfigureEventDeactivationParameterProcessor
    )
    XCTAssertTrue(
      AppEventsState.eventProcessors?.last === appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor
    )
  }

  func testInitializingSdkTriggersApplicationLifecycleNotificationsForAppEvents() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      appEvents.wasStartObservingApplicationLifecycleNotificationsCalled,
      "Should have app events start observing application lifecycle notifications upon initialization"
    )
  }

  func testInitializingSDKLogsAppEvent() {
    userDataStore.setValue(1, forKey: bitmaskKey)

    delegate._logSDKInitialize()

    XCTAssertEqual(
      appEvents.capturedEventName,
      .initializeSDK
    )
    XCTAssertFalse(appEvents.capturedIsImplicitlyLogged)
  }

  func testInitializingSdkObservesSystemNotifications() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      notificationCenter.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didEnterBackgroundNotification,
          selector: #selector(ApplicationDelegate.applicationDidEnterBackground(_:)),
          object: nil
        )
      ),
      "Should start observing application backgrounding upon initialization"
    )
    XCTAssertTrue(
      notificationCenter.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didBecomeActiveNotification,
          selector: #selector(ApplicationDelegate.applicationDidBecomeActive(_:)),
          object: nil
        )
      ),
      "Should start observing application foregrounding upon initialization"
    )
    XCTAssertTrue(
      notificationCenter.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.willResignActiveNotification,
          selector: #selector(ApplicationDelegate.applicationWillResignActive(_:)),
          object: nil
        )
      ),
      "Should start observing application resignation upon initializtion"
    )
  }

  func testInitializingSdkSetsSessionInformation() {
    delegate.initializeSDK(
      launchOptions: [
        UIApplication.LaunchOptionsKey.sourceApplication: name,
        .url: SampleURLs.valid
      ]
    )

    XCTAssertEqual(
      appEvents.capturedSetSourceApplication,
      name,
      "Should set the source application based on the launch options"
    )
    XCTAssertEqual(
      appEvents.capturedSetSourceApplicationURL,
      SampleURLs.valid,
      "Should set the source application url based on the launch options"
    )
  }

  func testInitializingSdkRegistersForSessionUpdates() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      appEvents.wasRegisterAutoResetSourceApplicationCalled,
      "Should have the analytics session register to auto reset the source application"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAppEventsConfigurationManager() {
    delegate.initializeSDK()

    XCTAssertTrue(
      AppEventsConfigurationManager.shared.store === UserDefaults.standard,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete request provider"
    )
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should be configured with the expected concrete connection provider"
    )
  }

  // MARK: - Configuring Dependencies

  // TEMP: added to configurator tests
  func testInitializingConfiguresError() {
    SDKError.reset()
    XCTAssertNil(
      SDKError.errorReporter,
      "Should not have an error reporter by default"
    )
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertEqual(
      SDKError.errorReporter as? ErrorReporter,
      ErrorReporter.shared
    )
  }

  func testInitializingConfiguresSuggestedEventsIndexer() throws {
    ModelManager.reset()
    delegate.initializeSDK(launchOptions: [:])

    let indexer = try XCTUnwrap(
      ModelManager.shared.suggestedEventsIndexer as? SuggestedEventsIndexer
    )

    XCTAssertTrue(
      indexer.graphRequestFactory is GraphRequestFactory,
      "Should configure with a request provider of the expected type"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is ServerConfigurationManager,
      "Should configure with a server configuration manager of the expected type"
    )
    XCTAssertTrue(
      indexer.swizzler is Swizzler.Type,
      "Should configure with a swizzler of the expected type"
    )
    XCTAssertTrue(
      indexer.settings is Settings,
      "Should configure with a settings of the expected type"
    )
    XCTAssertTrue(
      indexer.eventLogger === AppEvents.shared,
      "Should configure with the expected event logger"
    )
    XCTAssertTrue(
      indexer.eventProcessor is ModelManager,
      "Should have an event processor of the expected type"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresModelManager() {
    ModelManager.reset()
    XCTAssertNil(ModelManager.shared.featureChecker, "Should not have a feature checker by default")
    XCTAssertNil(ModelManager.shared.graphRequestFactory, "Should not have a request factory by default")
    XCTAssertNil(ModelManager.shared.fileManager, "Should not have a file manager by default")
    XCTAssertNil(ModelManager.shared.store, "Should not have a data store by default")
    XCTAssertNil(ModelManager.shared.settings, "Should not have a settings by default")
    XCTAssertNil(ModelManager.shared.dataExtractor, "Should not have a data extractor by default")
    XCTAssertNil(ModelManager.shared.gateKeeperManager, "Should not have a gate keeper manager by default")
    XCTAssertNil(ModelManager.shared.suggestedEventsIndexer, "Should not have a suggested events indexer by default")
    XCTAssertNil(ModelManager.shared.featureExtractor, "Should not have a feature extractor by default")

    delegate.initializeSDK(launchOptions: [:])

    XCTAssertEqual(
      ModelManager.shared.featureChecker as? FeatureManager,
      FeatureManager.shared,
      "Should configure with the expected concrete feature checker"
    )
    XCTAssertTrue(
      ModelManager.shared.graphRequestFactory is GraphRequestFactory,
      "Should configure with a request factory of the expected type"
    )
    XCTAssertEqual(
      ModelManager.shared.fileManager as? FileManager,
      FileManager.default,
      "Should configure with the expected concrete file manager"
    )
    XCTAssertEqual(
      ModelManager.shared.store as? UserDefaults,
      UserDefaults.standard,
      "Should configure with the expected concrete data store"
    )
    XCTAssertEqual(
      ModelManager.shared.settings as? Settings,
      Settings.shared,
      "Should configure with the expected concrete settings"
    )
    XCTAssertTrue(
      ModelManager.shared.dataExtractor is NSData.Type,
      "Should configure with the expected concrete data extractor"
    )
    XCTAssertTrue(
      ModelManager.shared.gateKeeperManager === GateKeeperManager.self,
      "Should configure with the expected concrete gatekeeper manager"
    )
    XCTAssertTrue(
      ModelManager.shared.featureExtractor === FeatureExtractor.self,
      "Should configure with the expected feature extractor"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresGraphRequest() {
    GraphRequest.resetClassDependencies()
    delegate.initializeSDK(launchOptions: [:])

    let request = GraphRequest(graphPath: name)
    XCTAssertTrue(
      request.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should configure the graph request with a connection provider to use in creating new instances"
    )
    XCTAssertTrue(
      GraphRequest.accessTokenProvider === AccessToken.self,
      "Should configure the graph request type with the expected concrete token string provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresFeatureManager() {
    FeatureManager.reset()
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      FeatureManager.shared.gateKeeperManager === GateKeeperManager.self,
      "Should configure with the expected concrete gatekeeper manager"
    )
    XCTAssertTrue(
      FeatureManager.shared.settings === Settings.shared,
      "Should configure with the expected concrete settings"
    )
    XCTAssertTrue(
      FeatureManager.shared.store === UserDefaults.standard,
      "Should configure with the expected concrete data store"
    )
  }

  // TEMP: added to configurator tests -- need to check same feature checker
  // and settings for crash observer
  func testInitializingConfiguresInstrumentManager() throws {
    InstrumentManager.reset()
    delegate.initializeSDK(launchOptions: [:])

    let crashObserver = try XCTUnwrap(
      InstrumentManager.shared.crashObserver as? CrashObserver,
      "Should configure with a crash observer"
    )

    XCTAssertTrue(
      crashObserver.featureChecker === InstrumentManager.shared.featureChecker,
      "Should use the same feature checker for the crash observer and the instrument manager"
    )
    XCTAssertTrue(
      crashObserver.settings === InstrumentManager.shared.settings,
      "Should use the same settings for the crash observer and the instrument manager"
    )
    XCTAssertTrue(
      InstrumentManager.shared.featureChecker is FeatureManager,
      "Should configure with the expected feature checker"
    )
    XCTAssertTrue(
      InstrumentManager.shared.settings === Settings.shared,
      "Should configure with the shared settings instance"
    )
    XCTAssertTrue(
      InstrumentManager.shared.errorReporter === ErrorReporter.shared,
      "Should configure with the shared error reporter instance"
    )
    XCTAssertTrue(
      InstrumentManager.shared.crashHandler === CrashHandler.shared,
      "Should configure with the shared Crash Handler instance"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresAppLinkUtility() {
    AppLinkUtility.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      AppLinkUtility.graphRequestFactory is GraphRequestFactory,
      "Should configure with the expected graph request factory"
    )
    XCTAssertTrue(
      AppLinkUtility.infoDictionaryProvider === Bundle.main,
      "Should configure with the expected info dictionary provider"
    )
    XCTAssertTrue(
      AppLinkUtility.settings === Settings.shared,
      "Should configure with the expected settings"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsConfigurationProvider === AppEventsConfigurationManager.shared,
      "Should configure with the expected app events configuration manager"
    )
    XCTAssertTrue(
      AppLinkUtility.advertiserIDProvider === AppEventsUtility.shared,
      "Should configure with the expected advertiser id provider"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventsDropDeterminer === AppEventsUtility.shared,
      "Should configure with the expected app events drop determiner"
    )
    XCTAssertTrue(
      AppLinkUtility.appEventParametersExtractor === AppEventsUtility.shared,
      "Should configure with the expected app events parameter extractor"
    )
    XCTAssertTrue(
      AppLinkUtility.appLinkURLFactory is AppLinkURLFactory,
      "Should configure with the expected app link URL factory"
    )
    XCTAssertTrue(
      AppLinkUtility.userIDProvider === AppEvents.shared,
      "Should configure with the expected user id provider"
    )
    XCTAssertTrue(
      AppLinkUtility.userDataStore is UserDataStore,
      "Should configure with the expected user data store"
    )
  }

  func testInitializingCreatesPaymentObserver() throws {
    let observer = try XCTUnwrap(
      ApplicationDelegate.shared.paymentObserver as? PaymentObserver
    )

    XCTAssertEqual(
      observer.paymentQueue,
      SKPaymentQueue.default(),
      "Should create the shared instance with the expected concrete payment queue"
    )
    XCTAssertTrue(
      observer.requestorFactory is PaymentProductRequestorFactory,
      "Should create the shared instance with the expected concrete payment product requestor factory"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresServerConfigurationManager() {
    let manager = ServerConfigurationManager.shared
    manager.reset()
    delegate.initializeSDK()

    XCTAssertTrue(manager.graphRequestFactory is GraphRequestFactory)
    XCTAssertTrue(manager.graphRequestConnectionFactory is GraphRequestConnectionFactory)
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresAppLinkURL() {
    AppLinkURL.reset()

    delegate.initializeSDK()

    XCTAssertTrue(
      AppLinkURL.settings === Settings.shared,
      "Should configure with the expected settings"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkFactory is AppLinkFactory,
      "Should configure with the expected app link factory"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkTargetFactory is AppLinkTargetFactory,
      "Should configure with the expected app link target factory"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkEventPoster is MeasurementEvent,
      "Should configure with the expected app link event poster"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresBridgeAPIRequest() {
    BridgeAPIRequest.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertTrue(
      BridgeAPIRequest.internalUtility === InternalUtility.shared,
      "Should configure with the expected internal utility"
    )
    XCTAssertTrue(
      BridgeAPIRequest.settings === Settings.shared,
      "Should configure with the expected settings"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresAppEventsUtility() {
    AppEventsUtility.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      AppEventsUtility.shared.appEventsConfigurationProvider === AppEventsConfigurationManager.shared,
      "Should configure with the expected app events configuration provider"
    )

    XCTAssertTrue(
      AppEventsUtility.shared.deviceInformationProvider is AppEventsDeviceInfo,
      "Should configure with the expected device information provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresGraphRequestConnection() {
    GraphRequestConnection.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertTrue(
      GraphRequestConnection.sessionProxyFactory is URLSessionProxyFactory,
      "A graph request connection should have the correct concrete session provider by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorConfigurationProvider is ErrorConfigurationProvider,
      "A graph request connection should have the correct error configuration provider by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.piggybackManager === GraphRequestPiggybackManager.self,
      "A graph request connection should have the correct piggyback manager provider by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.settings === Settings.shared,
      "A graph request connection should have the correct settings type by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "A graph request connection should have the correct connection factory by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.eventLogger === AppEvents.shared,
      "A graph request connection should have the correct events logger by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.operatingSystemVersionComparer === ProcessInfo.processInfo,
      "A graph request connection should have the correct operating system version comparer by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.macCatalystDeterminator === ProcessInfo.processInfo,
      "A graph request connection should have the correct Mac Catalyst determinator by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenProvider === AccessToken.self,
      "A graph request connection should have the correct access token provider by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenSetter === AccessToken.self,
      "A graph request connection should have the correct access token setter by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorFactory is ErrorFactory,
      "A graph request connection should have an error factory by default"
    )
    XCTAssertTrue(
      GraphRequestConnection.authenticationTokenProvider === AuthenticationToken.self,
      "A graph request connection should have the correct authentication token provider by default"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresAuthenticationStatusUtility() {
    AuthenticationStatusUtility.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertTrue(
      AuthenticationStatusUtility.profileSetter === Profile.self,
      "Should configure with the expected profile setter"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.sessionDataTaskProvider === URLSession.shared,
      "Should configure with the expected session data task provider"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.accessTokenWallet === AccessToken.self,
      "Should configure with the expected access token"
    )
    XCTAssertTrue(
      AuthenticationStatusUtility.authenticationTokenWallet === AuthenticationToken.self,
      "Should configure with the expected authentication token"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresInternalUtility() {
    InternalUtility.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === Bundle.main,
      "Should be configured with the expected concrete info dictionary provider"
    )
    XCTAssertTrue(
      InternalUtility.shared.loggerFactory is LoggerFactory,
      "Should be configured with the expected concrete logger factory"
    )
  }

  func testInitializingSdkConfiguresSharedAppEventsDeviceInfo() throws {
    AppEventsDeviceInfo.reset()

    delegate.initializeSDK()

    XCTAssertTrue(
      AppEventsDeviceInfo.shared.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAppLinkNavigation() {
    AppLinkNavigation.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      AppLinkNavigation.default === WebViewAppLinkResolver.shared,
      "Should be configured with the expected app link resolver"
    )
    XCTAssertTrue(
      AppLinkNavigation.settings === Settings.shared,
      "Should be configured with the expected settings"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkEventPoster is MeasurementEvent,
      "Should be configured with the expected app link event poster"
    )
    XCTAssertTrue(
      AppLinkNavigation.appLinkResolver is WebViewAppLinkResolver,
      "Should be configured with the expected app link resolver"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresButtonSuperclass() {
    ApplicationDelegate.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      FBButton.applicationActivationNotifier is ApplicationDelegate,
      "Should be configured with the expected concrete application activation notifier"
    )
    XCTAssertTrue(
      FBButton.eventLogger === AppEvents.shared,
      "Should be configured with the expected concrete app events"
    )
    XCTAssertTrue(
      FBButton.accessTokenProvider === AccessToken.self,
      "Should be configured with the expected concrete access token provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAppEvents() throws { // swiftlint:disable:this function_body_length
    AppEvents.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      appEvents.capturedConfigureGateKeeperManager === GateKeeperManager.self,
      "Initializing the SDK should set gate keeper manager for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureAppEventsConfigurationProvider === AppEventsConfigurationManager.shared,
      "Initializing the SDK should set AppEvents configuration provider for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureServerConfigurationProvider === ServerConfigurationManager.shared,
      "Initializing the SDK should set server configuration provider for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureGraphRequestFactory is GraphRequestFactory,
      "Initializing the SDK should set graph request factory for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureFeatureChecker === delegate.featureChecker,
      "Initializing the SDK should set feature checker for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigurePrimaryDataStore === UserDefaults.standard,
      "Should be configured with the expected concrete primary data store"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureLogger === Logger.self,
      "Initializing the SDK should set concrete logger for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureSettings === Settings.shared,
      "Initializing the SDK should set concrete settings for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigurePaymentObserver === delegate.paymentObserver,
      "Initializing the SDK should set concrete payment observer for event logging"
    )

    let recorder = try XCTUnwrap(
      appEvents.capturedConfigureTimeSpentRecorder as? TimeSpentData,
      "Initializing the SDK should set concrete time spent recorder for event logging"
    )
    XCTAssertTrue(
      recorder.eventLogger === appEvents,
      "The time spent recorder's event logger should be the shared app events"
    )
    XCTAssertTrue(
      recorder.serverConfigurationProvider === ServerConfigurationManager.shared,
      "The time spent recorder's server configuration provider should be the shared server configuration manager"
    )

    XCTAssertTrue(
      appEvents.capturedConfigureAppEventsStateStore === AppEventsStateManager.shared,
      "Initializing the SDK should set concrete state store for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureEventDeactivationParameterProcessor is EventDeactivationManager,
      "Initializing the SDK should set concrete event deactivation parameter processor for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor is RestrictiveDataFilterManager,
      "Initializing the SDK should set concrete restrictive data filter parameter processor for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureATEPublisherFactory is ATEPublisherFactory,
      "Initializing the SDK should set concrete ate publisher factory for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureAppEventsStateProvider is AppEventsStateFactory,
      "Initializing the SDK should set concrete AppEvents state provider for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedAdvertiserIDProvider === AppEventsUtility.shared,
      "Initializing the SDK should set concrete advertiser ID provider"
    )
    XCTAssertTrue(
      appEvents.capturedUserDataStore is UserDataStore,
      "Initializing the SDK should set the expected concrete user data store"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringNonTVAppEventsDependencies() throws {
    AppEvents.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      appEvents.capturedOnDeviceMLModelManager === ModelManager.shared,
      "Initializing the SDK should set concrete on device model manager for event logging"
    )

    let metadataIndexer = try XCTUnwrap(
      appEvents.capturedMetadataIndexer as? MetadataIndexer,
      "Initializing the SDK should set a concrete metadata indexer for event logging"
    )
    XCTAssertTrue(
      metadataIndexer.userDataStore is UserDataStore,
      "Should create the meta indexer with the expected user data store"
    )
    XCTAssertTrue(
      metadataIndexer.swizzler === Swizzler.self,
      "Should create the meta indexer with the expected swizzzler"
    )

    XCTAssertTrue(
      appEvents.capturedSKAdNetworkReporter === delegate.skAdNetworkReporter,
      "Initializing the SDK should set concrete SKAdNetworkReporter for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedConfigureSwizzler === Swizzler.self,
      "Initializing the SDK should set concrete swizzler for event logging"
    )
    XCTAssertTrue(
      appEvents.capturedCodelessIndexer === CodelessIndexer.self,
      "Initializing the SDK should set concrete codeless indexer"
    )
    XCTAssertTrue(
      appEvents.capturedAEMReporter === AEMReporter.self,
      "Initializing the SDK should set the concrete AEM reporter"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresGateKeeperManager() {
    GateKeeperManager.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      GateKeeperManager.canLoadGateKeepers,
      "Initializing the SDK should enable loading gatekeepers"
    )

    XCTAssertTrue(
      GateKeeperManager.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertTrue(
      GateKeeperManager.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should be configured with the expected concrete graph request connection provider"
    )
    XCTAssertTrue(
      GateKeeperManager.store === UserDefaults.standard,
      "Should be configured with the expected concrete data store"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringCodelessIndexer() {
    delegate.initializeSDK()

    XCTAssertTrue(
      CodelessIndexer.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider === ServerConfigurationManager.shared,
      "Should be configured with the expected concrete server configuration provider"
    )
    XCTAssertTrue(
      CodelessIndexer.dataStore === UserDefaults.standard,
      "Should be configured with the standard user defaults"
    )
    XCTAssertTrue(
      CodelessIndexer.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should be configured with the expected concrete graph request connection provider"
    )
    XCTAssertTrue(
      CodelessIndexer.swizzler === Swizzler.self,
      "Should be configured with the expected concrete swizzler"
    )
    XCTAssertTrue(
      CodelessIndexer.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertTrue(
      CodelessIndexer.advertiserIDProvider === AppEventsUtility.shared,
      "Should be configured with the expected concrete advertiser identifier provider"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringCrashShield() {
    delegate.initializeSDK()

    XCTAssertTrue(
      CrashShield.settings is Settings,
      "Should be configured with the expected settings"
    )
    XCTAssertTrue(
      CrashShield.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertTrue(
      CrashShield.featureChecking is FeatureManager,
      "Should be configured with the expected concrete Feature manager"
    )
  }

  func testConfiguringRestrictiveDataFilterManager() {
    delegate.initializeSDK()

    let restrictiveDataFilterManager = appEvents.capturedConfigureRestrictiveDataFilterParameterProcessor as? RestrictiveDataFilterManager // swiftlint:disable:this line_length
    XCTAssertTrue(
      restrictiveDataFilterManager?.serverConfigurationProvider === ServerConfigurationManager.shared,
      "Should be configured with the expected concrete server configuration provider"
    )
  }

  func testConfiguringFBSDKSKAdNetworkReporter() {
    delegate.initializeSDK()
    XCTAssertTrue(
      delegate.skAdNetworkReporter.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertTrue(
      delegate.skAdNetworkReporter.store === UserDefaults.standard,
      "Should be configured with the standard user defaults"
    )
    if #available(iOS 11.3, *) {
      XCTAssertTrue(
        delegate.skAdNetworkReporter.conversionValueUpdatable === SKAdNetwork.self,
        "Should be configured with the default Conversion Value Updating Class"
      )
    }
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenCache() {
    AccessToken.tokenCache = nil
    delegate.initializeSDK()

    XCTAssertTrue(
      AccessToken.tokenCache is TokenCache,
      "Should be configured with expected concrete token cache"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenGraphRequestPiggybackManager() {
    AccessToken.graphRequestPiggybackManager = nil
    delegate.initializeSDK()

    XCTAssertTrue(
      AccessToken.graphRequestPiggybackManager === GraphRequestPiggybackManager.self,
      "Should be configured with expected concrete graph request piggyback manager"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresProfile() {
    delegate.initializeSDK()

    XCTAssertTrue(
      Profile.dataStore === UserDefaults.standard,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertTrue(
      Profile.accessTokenProvider === AccessToken.self,
      "Should be configured with the expected concrete token provider"
    )
    XCTAssertTrue(
      Profile.notificationCenter === NotificationCenter.default,
      "Should be configured with the expected concrete notification center"
    )
    XCTAssertTrue(
      Profile.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertTrue(
      Profile.urlHoster === InternalUtility.shared,
      "Should be configured with the expected concrete URL hoster"
    )
  }

  func testInitializingSdkConfiguresAuthenticationTokenCache() {
    delegate.initializeSDK()

    XCTAssertTrue(
      AuthenticationToken.tokenCache is TokenCache,
      "Should be configured with expected concrete token cache"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenConnectionFactory() {
    AccessToken.graphRequestConnectionFactory = TestGraphRequestConnectionFactory()
    delegate.initializeSDK()

    XCTAssertTrue(
      AccessToken.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should be configured with expected concrete graph request connection factory"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresSettings() {
    Settings.shared.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      Settings.store === UserDefaults.standard,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertTrue(
      Settings.shared.appEventsConfigurationProvider === AppEventsConfigurationManager.shared,
      "Should be configured with the expected concrete app events configuration provider"
    )
    XCTAssertTrue(
      Settings.infoDictionaryProvider === Bundle.main,
      "Should be configured with the expected concrete info dictionary provider"
    )
    XCTAssertTrue(
      Settings.eventLogger === AppEvents.shared,
      "Should be configured with the expected concrete event logger"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresGraphRequestPiggybackManager() {
    delegate.initializeSDK()

    XCTAssertTrue(
      GraphRequestPiggybackManager.tokenWallet === AccessToken.self,
      "Should be configured with the expected concrete access token provider"
    )

    XCTAssertTrue(
      GraphRequestPiggybackManager.settings === Settings.shared,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertTrue(
      GraphRequestPiggybackManager.serverConfigurationProvider === ServerConfigurationManager.shared,
      "Should be configured with the expected concrete server configuration"
    )

    XCTAssertTrue(
      GraphRequestPiggybackManager.graphRequestFactory is GraphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
  }

  // TEMP: added to configurator tests as part of a complete test
  func testInitializingSdkConfiguresCurrentAccessTokenProviderForGraphRequest() {
    delegate.initializeSDK()

    XCTAssertTrue(
      GraphRequest.accessTokenProvider === AccessToken.self,
      "Should be configered with expected access token class."
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresWebDialogView() {
    delegate.initializeSDK()

    XCTAssertTrue(
      FBWebDialogView.webViewProvider is WebViewFactory,
      "Should be configured with the expected concrete web view provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresFeatureExtractor() {
    delegate.initializeSDK()
    XCTAssertTrue(
      FeatureExtractor.rulesFromKeyProvider === ModelManager.shared,
      "Should be configured with the expected concrete rules from key provider"
    )
  }

  func testInitializingSdkConfiguresImpressionLoggingButton() throws {
    ImpressionLoggingButton.resetClassDependencies()
    delegate.initializeSDK()

    let factory = try XCTUnwrap(
      ImpressionLoggingButton.impressionLoggerFactory as? ImpressionLoggerFactory,
      "Should be configured with the expected concrete logger factory"
    )
    XCTAssertTrue(
      factory.graphRequestFactory is GraphRequestFactory,
      "The impression factory should have the expected concrete graph request factory"
    )
    XCTAssertTrue(
      factory.eventLogger === AppEvents.shared,
      "The impression factory should have the expected concrete event logger"
    )
    XCTAssertTrue(
      factory.notificationCenter === NotificationCenter.default,
      "The impression factory should have the expected concrete notification center"
    )
    XCTAssertTrue(
      factory.accessTokenWallet === AccessToken.self,
      "The impression factory should have the expected concrete access token wallet"
    )
  }

  // MARK: - DidFinishLaunching

  func testDidFinishLaunchingLoadsServerConfiguration() {
    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertTrue(
      serverConfigurationProvider.loadServerConfigurationWasCalled,
      "Should load a server configuration on finishing launching the application"
    )
  }

  func testDidFinishLaunchingSetsProfileWithCache() {
    TestProfileProvider.stubbedCachedProfile = profile

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      TestProfileProvider.current,
      profile,
      "Should set the current profile to the value fetched from the cache"
    )
  }

  func testDidFinishLaunchingSetsProfileWithoutCache() {
    XCTAssertNil(
      TestProfileProvider.stubbedCachedProfile,
      "Setup should nil out the cached profile"
    )

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertNil(
      TestProfileProvider.current,
      "Should set the current profile to nil when the cache is empty"
    )
  }

  // MARK: - URL Opening

  func testOpeningURLChecksAEMFeatureAvailability() {
    delegate.application(
      UIApplication.shared,
      open: SampleURLs.validApp,
      options: [:]
    )
    XCTAssertTrue(
      featureChecker.capturedFeaturesContains(.AEM),
      "Opening a deep link should check if the AEM feature is enabled"
    )
  }

  // MARK: - Application Observers

  func testDefaultsObservers() {
    XCTAssertEqual(
      delegate.applicationObservers.count,
      0,
      "Should have no observers by default"
    )
  }

  func testAddingNewObserver() {
    delegate.addObserver(observer)

    XCTAssertEqual(
      delegate.applicationObservers.count,
      1,
      "Should be able to add a single observer"
    )
  }

  func testAddingDuplicateObservers() {
    delegate.addObserver(observer)
    delegate.addObserver(observer)

    XCTAssertEqual(
      delegate.applicationObservers.count,
      1,
      "Should only add one instance of a given observer"
    )
  }

  func testRemovingObserver() {
    delegate.addObserver(observer)
    delegate.removeObserver(observer)

    XCTAssertEqual(
      delegate.applicationObservers.count,
      0,
      "Should be able to remove observers that are present in the stored list"
    )
  }

  func testRemovingMissingObserver() {
    delegate.removeObserver(observer)

    XCTAssertEqual(
      delegate.applicationObservers.count,
      0,
      "Should not be able to remove absent observers"
    )
  }

  func testAppNotifyObserversWhenAppWillResignActive() {
    delegate.addObserver(observer)

    let notification = Notification(
      name: UIApplication.willResignActiveNotification,
      object: UIApplication.shared,
      userInfo: nil
    )
    delegate.applicationWillResignActive(notification)

    XCTAssertTrue(
      observer.wasWillResignActiveCalled,
      "Should inform observers when the application will resign active status"
    )
  }
} // swiftlint:disable:this file_length
