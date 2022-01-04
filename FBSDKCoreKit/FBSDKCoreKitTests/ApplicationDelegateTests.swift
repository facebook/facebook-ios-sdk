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

    XCTAssertEqual(
      delegate.applicationObservers.count,
      0,
      "The delegate should have an empty hash table of application observers"
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
    XCTAssertEqual(
      delegate.applicationObservers.count,
      0,
      "The delegate should have an empty hash table of application observers"
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
