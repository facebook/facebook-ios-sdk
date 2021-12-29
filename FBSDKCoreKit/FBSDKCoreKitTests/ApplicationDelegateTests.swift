/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class ApplicationDelegateTests: XCTestCase {

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
  var components: CoreKitComponents!
  var configurator: TestCoreKitConfigurator!
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
    components = TestCoreKitComponents.makeComponents(
      appEvents: appEvents,
      defaultDataStore: userDataStore,
      featureChecker: featureChecker,
      notificationCenter: notificationCenter,
      paymentObserver: paymentObserver,
      serverConfigurationProvider: serverConfigurationProvider,
      settings: settings,
      backgroundEventLogger: backgroundEventLogger
    )
    configurator = TestCoreKitConfigurator(components: components)

    makeDelegate()
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
    components = nil
    delegate = nil

    resetTestDependencies()

    super.tearDown()
  }

  func makeDelegate(usesTestConfigurator: Bool = true) {
    let configurator: CoreKitConfiguring = usesTestConfigurator
      ? configurator
      : CoreKitConfigurator(components: components)

    delegate = ApplicationDelegate(
      components: components,
      configurator: configurator
    )
  }

  func resetTestDependencies() {
    ApplicationDelegate.reset()
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    TestGateKeeperManager.reset()
    TestProfileProvider.reset()
  }

  func testDefaultComponentsAndConfiguration() throws {
    delegate = ApplicationDelegate()

    XCTAssertIdentical(
      delegate.components,
      CoreKitComponents.default,
      "An application delegate should be created with the default components by default"
    )

    let configurator = try XCTUnwrap(
      delegate.configurator as? CoreKitConfigurator,
      "An application delegate should be created with a concrete configurator by default"
    )
    XCTAssertIdentical(
      configurator.components,
      CoreKitComponents.default,
      "The configurator should be created with the default components by default"
    )
  }

  func testComponentsAndConfiguration() {
    let components = TestCoreKitComponents.makeComponents()
    let configurator = TestCoreKitConfigurator(components: components)
    delegate = ApplicationDelegate(components: components, configurator: configurator)

    XCTAssertIdentical(
      delegate.components,
      components,
      "An application delegate should be created with the provided components"
    )
    XCTAssertIdentical(
      delegate.configurator,
      configurator,
      "An application delegate should be created with the provided configurator"
    )
  }

  func testDefaultDependencies() {
    delegate = ApplicationDelegate.shared

    XCTAssertEqual(
      delegate.components.notificationCenter as? NotificationCenter,
      NotificationCenter.default,
      "Should use the default system notification center"
    )
    XCTAssertTrue(
      delegate.components.accessTokenWallet is AccessToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertEqual(
      delegate.components.featureChecker as? FeatureManager,
      FeatureManager.shared,
      "Should use the default feature checker"
    )
    XCTAssertEqual(
      delegate.components.appEvents as? AppEvents,
      AppEvents.shared,
      "Should use the expected default app events instance"
    )
    XCTAssertTrue(
      delegate.components.serverConfigurationProvider is ServerConfigurationManager,
      "Should use the expected default server configuration provider"
    )
    XCTAssertEqual(
      delegate.components.defaultDataStore as? UserDefaults,
      UserDefaults.standard,
      "Should use the expected default persistent store"
    )
    XCTAssertTrue(
      delegate.components.authenticationTokenWallet is AuthenticationToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertTrue(
      delegate.components.settings === Settings.shared,
      "Should use the expected default settings"
    )
    XCTAssertTrue(
      delegate.components.paymentObserver is PaymentObserver,
      "Should use the expected concrete payment observer"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      delegate.components.notificationCenter is TestNotificationCenter,
      "Should be able to create with a custom notification center"
    )
    XCTAssertTrue(
      delegate.components.accessTokenWallet is TestAccessTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
    XCTAssertEqual(
      delegate.components.featureChecker as? TestFeatureManager,
      featureChecker,
      "Should be able to create with a feature checker"
    )
    XCTAssertEqual(
      delegate.components.appEvents as? TestAppEvents,
      appEvents,
      "Should be able to create with an app events instance"
    )
    XCTAssertTrue(
      delegate.components.serverConfigurationProvider is TestServerConfigurationProvider,
      "Should be able to create with a server configuration provider"
    )
    XCTAssertEqual(
      delegate.components.defaultDataStore as? UserDefaultsSpy,
      userDataStore,
      "Should be able to create with a persistent store"
    )
    XCTAssertTrue(
      delegate.components.authenticationTokenWallet is TestAuthenticationTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
    XCTAssertEqual(
      delegate.components.settings as? TestSettings,
      settings,
      "Should be able to create with custom settings"
    )
    XCTAssertEqual(
      delegate.components.backgroundEventLogger as? TestBackgroundEventLogger,
      backgroundEventLogger,
      "Should be able to create with custom background event logger"
    )
  }

  func testCreatingConfiguresPaymentProductRequestorFactory() throws {
    let paymentObserver = try XCTUnwrap(ApplicationDelegate.shared.components.paymentObserver as? PaymentObserver)
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

  func testInitializingSDKPerformsDownstreamConfigurations() {
    delegate.initializeSDK()
    XCTAssertTrue(
      configurator.performConfigurationCalled,
      "Initializing the SDK should ask the configurator to perform downstream configuration"
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
    settings.isAutoLogAppEventsEnabled = true
    userDataStore.set(1, forKey: bitmaskKey)

    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertEqual(
      appEvents.capturedEventName,
      .initializeSDK,
      "Should log initialization when auto log app events is enabled"
    )
  }

  func testDidFinishLaunchingWithAutoLogDisabled() {
    settings.isAutoLogAppEventsEnabled = false
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
    settings.isAutoLogAppEventsEnabled = true

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
    settings.isAutoLogAppEventsEnabled = false

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
    makeDelegate(usesTestConfigurator: false)
    GraphRequestConnection.resetCanMakeRequests()
    delegate.initializeSDK()

    XCTAssertTrue(
      GraphRequestConnection.canMakeRequests,
      "Initializing the SDK should enable making graph requests"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresEventsProcessorsForAppEventsState() throws {
    makeDelegate(usesTestConfigurator: false)
    AppEvents.shared.reset()
    delegate.initializeSDK()

    XCTAssertEqual(AppEventsState.eventProcessors?.count, 2)
    XCTAssertIdentical(
      AppEventsState.eventProcessors?.first,
      components.eventDeactivationManager
    )
    XCTAssertIdentical(
      AppEventsState.eventProcessors?.last,
      components.restrictiveDataFilterManager
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
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppEventsConfigurationManager.shared.store,
      components.defaultDataStore,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertIdentical(
      AppEventsConfigurationManager.shared.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertIdentical(
      AppEventsConfigurationManager.shared.graphRequestFactory,
      components.graphRequestFactory,
      "Should be configured with the expected concrete request provider"
    )
    XCTAssertIdentical(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "Should be configured with the expected concrete connection provider"
    )
  }

  // MARK: - Configuring Dependencies

  // TEMP: added to configurator tests
  func testInitializingConfiguresAEMReporter() {
    makeDelegate(usesTestConfigurator: false)
    AEMReporter.reset()

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

    delegate.initializeSDK(launchOptions: [:])

    XCTAssertIdentical(
      AEMReporter.networker,
      components.aemNetworker,
      "AEMReporter should be configured with an AEM networker"
    )
    XCTAssertEqual(
      AEMReporter.appID,
      Settings.shared.appID,
      "AEMReporter should be configured with the settings' app ID"
    )
    XCTAssertIdentical(
      AEMReporter.reporter,
      components.skAdNetworkReporter,
      "AEMReporter should be configured with a SKAdNetwork reporter"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresError() {
    makeDelegate(usesTestConfigurator: false)
    SDKError.reset()
    XCTAssertNil(
      SDKError.errorReporter,
      "Should not have an error reporter by default"
    )
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertIdentical(
      SDKError.errorReporter,
      components.errorReporter
    )
  }

  func testInitializingConfiguresSuggestedEventsIndexer() throws {
    makeDelegate(usesTestConfigurator: false)
    ModelManager.reset()
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertIdentical(
      ModelManager.shared.suggestedEventsIndexer,
      components.suggestedEventsIndexer,
      "Should configure with a request provider of the expected type"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresModelManager() {
    makeDelegate(usesTestConfigurator: false)
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

    XCTAssertIdentical(
      ModelManager.shared.featureChecker,
      components.featureChecker,
      "Should configure with the expected concrete feature checker"
    )
    XCTAssertIdentical(
      ModelManager.shared.graphRequestFactory,
      components.graphRequestFactory,
      "Should configure with a request factory of the expected type"
    )
    XCTAssertIdentical(
      ModelManager.shared.fileManager,
      components.fileManager,
      "Should configure with the expected concrete file manager"
    )
    XCTAssertIdentical(
      ModelManager.shared.store,
      components.defaultDataStore,
      "Should configure with the expected concrete data store"
    )
    XCTAssertIdentical(
      ModelManager.shared.settings,
      components.settings,
      "Should configure with the expected concrete settings"
    )
    XCTAssertIdentical(
      ModelManager.shared.dataExtractor,
      components.dataExtractor,
      "Should configure with the expected concrete data extractor"
    )
    XCTAssertIdentical(
      ModelManager.shared.gateKeeperManager,
      components.gateKeeperManager,
      "Should configure with the expected concrete gatekeeper manager"
    )
    XCTAssertIdentical(
      ModelManager.shared.featureExtractor,
      components.featureExtractor,
      "Should configure with the expected feature extractor"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresGraphRequest() {
    makeDelegate(usesTestConfigurator: false)
    GraphRequest.resetClassDependencies()
    delegate.initializeSDK(launchOptions: [:])

    let request = GraphRequest(graphPath: name)
    XCTAssertIdentical(
      request.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "Should configure the graph request with a connection provider to use in creating new instances"
    )
    XCTAssertIdentical(
      GraphRequest.accessTokenProvider,
      components.accessTokenWallet,
      "Should configure the graph request type with the expected concrete token string provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresFeatureManager() {
    makeDelegate(usesTestConfigurator: false)
    FeatureManager.shared.resetDependencies()
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertIdentical(
      FeatureManager.shared.gateKeeperManager,
      components.gateKeeperManager,
      "Should configure with the expected concrete gatekeeper manager"
    )
    XCTAssertIdentical(
      FeatureManager.shared.settings,
      components.settings,
      "Should configure with the expected concrete settings"
    )
    XCTAssertIdentical(
      FeatureManager.shared.store,
      components.defaultDataStore,
      "Should configure with the expected concrete data store"
    )
  }

  // TEMP: added to configurator tests -- need to check same feature checker
  // and settings for crash observer
  func testInitializingConfiguresInstrumentManager() throws {
    makeDelegate(usesTestConfigurator: false)
    InstrumentManager.reset()
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertIdentical(
      InstrumentManager.shared.crashObserver,
      components.crashObserver,
      "Should configure with a crash observer"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresAppLinkUtility() {
    makeDelegate(usesTestConfigurator: false)
    AppLinkUtility.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppLinkUtility.graphRequestFactory,
      components.graphRequestFactory,
      "Should configure with the expected graph request factory"
    )
    XCTAssertIdentical(
      AppLinkUtility.infoDictionaryProvider,
      components.infoDictionaryProvider,
      "Should configure with the expected info dictionary provider"
    )
    XCTAssertIdentical(
      AppLinkUtility.settings,
      components.settings,
      "Should configure with the expected settings"
    )
    XCTAssertIdentical(
      AppLinkUtility.appEventsConfigurationProvider,
      components.appEventsConfigurationProvider,
      "Should configure with the expected app events configuration manager"
    )
    XCTAssertIdentical(
      AppLinkUtility.advertiserIDProvider,
      components.advertiserIDProvider,
      "Should configure with the expected advertiser id provider"
    )
    XCTAssertIdentical(
      AppLinkUtility.appEventsDropDeterminer,
      components.appEventsDropDeterminer,
      "Should configure with the expected app events drop determiner"
    )
    XCTAssertIdentical(
      AppLinkUtility.appEventParametersExtractor,
      components.appEventParametersExtractor,
      "Should configure with the expected app events parameter extractor"
    )
    XCTAssertIdentical(
      AppLinkUtility.appLinkURLFactory,
      components.appLinkURLFactory,
      "Should configure with the expected app link URL factory"
    )
    XCTAssertIdentical(
      AppLinkUtility.userIDProvider,
      components.userIDProvider,
      "Should configure with the expected user id provider"
    )
    XCTAssertIdentical(
      AppLinkUtility.userDataStore,
      components.userDataStore,
      "Should configure with the expected user data store"
    )
  }

  func testInitializingCreatesPaymentObserver() throws {
    let observer = try XCTUnwrap(
      ApplicationDelegate.shared.components.paymentObserver as? PaymentObserver
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
    makeDelegate(usesTestConfigurator: false)
    let manager = ServerConfigurationManager.shared
    manager.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      manager.graphRequestFactory,
      components.graphRequestFactory
    )
    XCTAssertIdentical(
      manager.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory
    )
    XCTAssertIdentical(
      manager.dialogConfigurationMapBuilder,
      components.dialogConfigurationMapBuilder
    )
  }

  // TEMP: added to configurator tests
  func testInitializingConfiguresAppLinkURL() {
    makeDelegate(usesTestConfigurator: false)
    AppLinkURL.reset()

    delegate.initializeSDK()

    XCTAssertIdentical(
      AppLinkURL.settings,
      components.settings,
      "Should configure with the expected settings"
    )
    XCTAssertIdentical(
      AppLinkURL.appLinkFactory,
      components.appLinkFactory,
      "Should configure with the expected app link factory"
    )
    XCTAssertIdentical(
      AppLinkURL.appLinkTargetFactory,
      components.appLinkTargetFactory,
      "Should configure with the expected app link target factory"
    )
    XCTAssertIdentical(
      AppLinkURL.appLinkEventPoster,
      components.appLinkEventPoster,
      "Should configure with the expected app link event poster"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresBridgeAPIRequest() {
    makeDelegate(usesTestConfigurator: false)
    BridgeAPIRequest.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertIdentical(
      BridgeAPIRequest.internalUtility,
      components.internalUtility,
      "Should configure with the expected internal utility"
    )
    XCTAssertIdentical(
      BridgeAPIRequest.settings,
      components.settings,
      "Should configure with the expected settings"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresAppEventsUtility() {
    makeDelegate(usesTestConfigurator: false)
    AppEventsUtility.shared.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppEventsUtility.shared.appEventsConfigurationProvider,
      components.appEventsConfigurationProvider,
      "Should configure with the expected app events configuration provider"
    )
    XCTAssertIdentical(
      AppEventsUtility.shared.deviceInformationProvider,
      components.deviceInformationProvider,
      "Should configure with the expected device information provider"
    )
    XCTAssertIdentical(
      AppEventsUtility.shared.settings,
      components.settings,
      "Should configure with the expected settings"
    )
    XCTAssertIdentical(
      AppEventsUtility.shared.internalUtility,
      components.internalUtility,
      "Should configure with the expected internal utility"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresGraphRequestConnection() {
    makeDelegate(usesTestConfigurator: false)
    GraphRequestConnection.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertIdentical(
      GraphRequestConnection.sessionProxyFactory,
      components.urlSessionProxyFactory,
      "A graph request connection should have the correct concrete session provider by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.errorConfigurationProvider,
      components.errorConfigurationProvider,
      "A graph request connection should have the correct error configuration provider by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.piggybackManager,
      components.piggybackManager,
      "A graph request connection should have the correct piggyback manager provider by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.settings,
      components.settings,
      "A graph request connection should have the correct settings type by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "A graph request connection should have the correct connection factory by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.eventLogger,
      components.eventLogger,
      "A graph request connection should have the correct events logger by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.operatingSystemVersionComparer,
      components.operatingSystemVersionComparer,
      "A graph request connection should have the correct operating system version comparer by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.macCatalystDeterminator,
      components.macCatalystDeterminator,
      "A graph request connection should have the correct Mac Catalyst determinator by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.accessTokenProvider,
      components.accessTokenWallet,
      "A graph request connection should have the correct access token provider by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.accessTokenSetter,
      components.accessTokenWallet,
      "A graph request connection should have the correct access token setter by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.errorFactory,
      components.errorFactory,
      "A graph request connection should have an error factory by default"
    )
    XCTAssertIdentical(
      GraphRequestConnection.authenticationTokenProvider,
      components.authenticationTokenWallet,
      "A graph request connection should have the correct authentication token provider by default"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSDKConfiguresAuthenticationStatusUtility() {
    makeDelegate(usesTestConfigurator: false)
    AuthenticationStatusUtility.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AuthenticationStatusUtility.profileSetter,
      components.profileSetter,
      "Should configure with the expected profile setter"
    )
    XCTAssertIdentical(
      AuthenticationStatusUtility.sessionDataTaskProvider,
      components.sessionDataTaskProvider,
      "Should configure with the expected session data task provider"
    )
    XCTAssertIdentical(
      AuthenticationStatusUtility.accessTokenWallet,
      components.accessTokenWallet,
      "Should configure with the expected access token"
    )
    XCTAssertIdentical(
      AuthenticationStatusUtility.authenticationTokenWallet,
      components.authenticationTokenWallet,
      "Should configure with the expected authentication token"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresInternalUtility() {
    makeDelegate(usesTestConfigurator: false)
    InternalUtility.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      InternalUtility.shared.infoDictionaryProvider,
      components.infoDictionaryProvider,
      "Should be configured with the expected concrete info dictionary provider"
    )
    XCTAssertIdentical(
      InternalUtility.shared.loggerFactory,
      components.loggerFactory,
      "Should be configured with the expected concrete logger factory"
    )
    XCTAssertIdentical(
      InternalUtility.shared.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresSharedAppEventsDeviceInfo() {
    makeDelegate(usesTestConfigurator: false)
    AppEventsDeviceInfo.shared.resetDependencies()

    delegate.initializeSDK()

    XCTAssertIdentical(
      AppEventsDeviceInfo.shared.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAppLinkNavigation() {
    makeDelegate(usesTestConfigurator: false)
    AppLinkNavigation.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppLinkNavigation.default,
      components.appLinkResolver,
      "Should be configured with the expected app link resolver"
    )
    XCTAssertIdentical(
      AppLinkNavigation.settings,
      components.settings,
      "Should be configured with the expected settings"
    )
    XCTAssertIdentical(
      AppLinkNavigation.appLinkEventPoster,
      components.appLinkEventPoster,
      "Should be configured with the expected app link event poster"
    )
    XCTAssertIdentical(
      AppLinkNavigation.appLinkResolver,
      components.appLinkResolver,
      "Should be configured with the expected app link resolver"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresButtonSuperclass() {
    makeDelegate(usesTestConfigurator: false)
    ApplicationDelegate.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      FBButton.applicationActivationNotifier as AnyObject,
      components.getApplicationActivationNotifier() as AnyObject,
      "Should be configured with the expected concrete application activation notifier"
    )
    XCTAssertIdentical(
      FBButton.eventLogger,
      components.eventLogger,
      "Should be configured with the expected concrete app events"
    )
    XCTAssertIdentical(
      FBButton.accessTokenProvider,
      components.accessTokenWallet,
      "Should be configured with the expected concrete access token provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAppEvents() throws {
    makeDelegate(usesTestConfigurator: false)
    AppEvents.shared.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppEvents.shared.gateKeeperManager,
      components.gateKeeperManager,
      "Initializing the SDK should set gate keeper manager for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.appEventsConfigurationProvider,
      components.appEventsConfigurationProvider,
      "Initializing the SDK should set AppEvents configuration provider for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.serverConfigurationProvider,
      components.serverConfigurationProvider,
      "Initializing the SDK should set server configuration provider for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.graphRequestFactory,
      components.graphRequestFactory,
      "Initializing the SDK should set graph request factory for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.featureChecker,
      components.featureChecker,
      "Initializing the SDK should set feature checker for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.primaryDataStore,
      components.defaultDataStore,
      "Should be configured with the expected concrete primary data store"
    )
    XCTAssertIdentical(
      AppEvents.shared.logger,
      components.logger,
      "Initializing the SDK should set concrete logger for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.settings,
      components.settings,
      "Initializing the SDK should set concrete settings for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.paymentObserver,
      components.paymentObserver,
      "Initializing the SDK should set concrete payment observer for event logging"
    )

    XCTAssertIdentical(
      AppEvents.shared.timeSpentRecorder,
      components.timeSpentRecorder,
      "Initializing the SDK should set concrete time spent recorder for event logging"
    )

    XCTAssertIdentical(
      AppEvents.shared.appEventsStateStore,
      components.appEventsStateStore,
      "Initializing the SDK should set concrete state store for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.eventDeactivationParameterProcessor,
      components.eventDeactivationManager,
      "Initializing the SDK should set concrete event deactivation parameter processor for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.restrictiveDataFilterParameterProcessor,
      components.restrictiveDataFilterManager,
      "Initializing the SDK should set concrete restrictive data filter parameter processor for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.atePublisherFactory,
      components.atePublisherFactory,
      "Initializing the SDK should set concrete ate publisher factory for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.appEventsStateProvider,
      components.appEventsStateProvider,
      "Initializing the SDK should set concrete AppEvents state provider for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.advertiserIDProvider,
      components.advertiserIDProvider,
      "Initializing the SDK should set concrete advertiser ID provider"
    )
    XCTAssertIdentical(
      AppEvents.shared.userDataStore,
      components.userDataStore,
      "Initializing the SDK should set the expected concrete user data store"
    )
    XCTAssertIdentical(
      AppEvents.shared.appEventsUtility,
      components.appEventsUtility,
      "Initializing the SDK should set concrete app events utility"
    )
    XCTAssertIdentical(
      AppEvents.shared.internalUtility,
      components.internalUtility,
      "Initializing the SDK should set concrete internal utility"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringNonTVAppEventsDependencies() throws {
    makeDelegate(usesTestConfigurator: false)
    AppEvents.shared.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AppEvents.shared.onDeviceMLModelManager,
      components.modelManager,
      "Initializing the SDK should set concrete on device model manager for event logging"
    )

    XCTAssertIdentical(
      AppEvents.shared.metadataIndexer,
      components.metadataIndexer,
      "Initializing the SDK should set a concrete metadata indexer for event logging"
    )

    XCTAssertIdentical(
      AppEvents.shared.skAdNetworkReporter,
      components.skAdNetworkReporter,
      "Initializing the SDK should set concrete SKAdNetworkReporter for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.swizzler,
      components.swizzler,
      "Initializing the SDK should set concrete swizzler for event logging"
    )
    XCTAssertIdentical(
      AppEvents.shared.codelessIndexer,
      components.codelessIndexer,
      "Initializing the SDK should set concrete codeless indexer"
    )
    XCTAssertIdentical(
      AppEvents.shared.aemReporter,
      components.aemReporter,
      "Initializing the SDK should set the concrete AEM reporter"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresGateKeeperManager() {
    makeDelegate(usesTestConfigurator: false)
    GateKeeperManager.reset()
    delegate.initializeSDK()

    XCTAssertTrue(
      GateKeeperManager.canLoadGateKeepers,
      "Initializing the SDK should enable loading gatekeepers"
    )

    XCTAssertIdentical(
      GateKeeperManager.graphRequestFactory,
      components.graphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertIdentical(
      GateKeeperManager.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "Should be configured with the expected concrete graph request connection provider"
    )
    XCTAssertIdentical(
      GateKeeperManager.store,
      components.defaultDataStore,
      "Should be configured with the expected concrete data store"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringCodelessIndexer() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      CodelessIndexer.graphRequestFactory,
      components.graphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertIdentical(
      CodelessIndexer.serverConfigurationProvider,
      components.serverConfigurationProvider,
      "Should be configured with the expected concrete server configuration provider"
    )
    XCTAssertIdentical(
      CodelessIndexer.dataStore,
      components.defaultDataStore,
      "Should be configured with the standard user defaults"
    )
    XCTAssertIdentical(
      CodelessIndexer.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "Should be configured with the expected concrete graph request connection provider"
    )
    XCTAssertIdentical(
      CodelessIndexer.swizzler,
      components.swizzler,
      "Should be configured with the expected concrete swizzler"
    )
    XCTAssertIdentical(
      CodelessIndexer.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertIdentical(
      CodelessIndexer.advertiserIDProvider,
      components.advertiserIDProvider,
      "Should be configured with the expected concrete advertiser identifier provider"
    )
  }

  // TEMP: added to configurator tests
  func testConfiguringCrashShield() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      CrashShield.settings,
      components.settings,
      "Should be configured with the expected settings"
    )
    XCTAssertIdentical(
      CrashShield.graphRequestFactory,
      components.graphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
    XCTAssertIdentical(
      CrashShield.featureChecking,
      components.featureChecker,
      "Should be configured with the expected concrete Feature manager"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenCache() throws {
    makeDelegate(usesTestConfigurator: false)
    AccessToken.tokenCache = nil
    delegate.initializeSDK()

    XCTAssertIdentical(
      AccessToken.tokenCache,
      components.tokenCache,
      "Should be configured with expected concrete token cache"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenGraphRequestPiggybackManager() {
    makeDelegate(usesTestConfigurator: false)
    AccessToken.graphRequestPiggybackManager = nil
    delegate.initializeSDK()

    XCTAssertIdentical(
      AccessToken.graphRequestPiggybackManager,
      components.piggybackManager,
      "Should be configured with expected concrete graph request piggyback manager"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresProfile() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      Profile.dataStore,
      components.defaultDataStore,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertIdentical(
      Profile.accessTokenProvider,
      components.accessTokenWallet,
      "Should be configured with the expected concrete token provider"
    )
    XCTAssertIdentical(
      Profile.notificationCenter,
      components.notificationCenter,
      "Should be configured with the expected concrete notification center"
    )
    XCTAssertIdentical(
      Profile.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertIdentical(
      Profile.urlHoster,
      components.urlHoster,
      "Should be configured with the expected concrete URL hoster"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAuthenticationTokenCache() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      AuthenticationToken.tokenCache,
      components.tokenCache,
      "Should be configured with expected concrete token cache"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresAccessTokenConnectionFactory() {
    makeDelegate(usesTestConfigurator: false)
    AccessToken.graphRequestConnectionFactory = TestGraphRequestConnectionFactory()
    delegate.initializeSDK()

    XCTAssertIdentical(
      AccessToken.graphRequestConnectionFactory,
      components.graphRequestConnectionFactory,
      "Should be configured with expected concrete graph request connection factory"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresSettings() {
    makeDelegate(usesTestConfigurator: false)
    Settings.shared.reset()
    delegate.initializeSDK()

    XCTAssertIdentical(
      Settings.shared.store,
      components.defaultDataStore,
      "Should be configured with the expected concrete data store"
    )
    XCTAssertIdentical(
      Settings.shared.appEventsConfigurationProvider,
      components.appEventsConfigurationProvider,
      "Should be configured with the expected concrete app events configuration provider"
    )
    XCTAssertIdentical(
      Settings.shared.infoDictionaryProvider,
      components.infoDictionaryProvider,
      "Should be configured with the expected concrete info dictionary provider"
    )
    XCTAssertIdentical(
      Settings.shared.eventLogger,
      components.eventLogger,
      "Should be configured with the expected concrete event logger"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresGraphRequestPiggybackManager() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      GraphRequestPiggybackManager.tokenWallet,
      components.accessTokenWallet,
      "Should be configured with the expected concrete access token provider"
    )

    XCTAssertIdentical(
      GraphRequestPiggybackManager.settings,
      components.settings,
      "Should be configured with the expected concrete settings"
    )
    XCTAssertIdentical(
      GraphRequestPiggybackManager.serverConfigurationProvider,
      components.serverConfigurationProvider,
      "Should be configured with the expected concrete server configuration"
    )

    XCTAssertIdentical(
      GraphRequestPiggybackManager.graphRequestFactory,
      components.graphRequestFactory,
      "Should be configured with the expected concrete graph request provider"
    )
  }

  // TEMP: added to configurator tests as part of a complete test
  func testInitializingSdkConfiguresCurrentAccessTokenProviderForGraphRequest() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      GraphRequest.accessTokenProvider,
      components.accessTokenWallet,
      "Should be configered with expected access token class."
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresWebDialogView() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      FBWebDialogView.webViewProvider,
      components.webViewProvider,
      "Should be configured with the expected concrete web view provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresFeatureExtractor() {
    makeDelegate(usesTestConfigurator: false)
    delegate.initializeSDK()

    XCTAssertIdentical(
      FeatureExtractor.rulesFromKeyProvider,
      components.rulesFromKeyProvider,
      "Should be configured with the expected concrete rules from key provider"
    )
  }

  // TEMP: added to configurator tests
  func testInitializingSdkConfiguresImpressionLoggingButton() throws {
    makeDelegate(usesTestConfigurator: false)
    ImpressionLoggingButton.resetClassDependencies()
    delegate.initializeSDK()

    XCTAssertIdentical(
      ImpressionLoggingButton.impressionLoggerFactory,
      components.impressionLoggerFactory,
      "Should be configured with the expected concrete logger factory"
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
}
