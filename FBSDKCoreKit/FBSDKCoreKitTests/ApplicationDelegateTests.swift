// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import XCTest

// swiftlint:disable type_body_length
class ApplicationDelegateTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional weak_delegate
  var delegate: ApplicationDelegate!
  var center = TestNotificationCenter()
  var featureChecker = TestFeatureManager()
  var appEvents = TestAppEvents()
  var store = UserDefaultsSpy()
  let observer = TestApplicationDelegateObserver()
  let settings = TestSettings()
  let backgroundEventLogger = TestBackgroundEventLogger(
    infoDictionaryProvider: TestBundle(),
    eventLogger: TestAppEvents()
  )
  let bitmaskKey = "com.facebook.sdk.kits.bitmask"
  lazy var profile = Profile(
    userID: name,
    firstName: nil,
    middleName: nil,
    lastName: nil,
    name: nil,
    linkURL: nil,
    refreshDate: nil
  )

  override class func setUp() {
    super.setUp()

    resetTestData()
  }

  override func setUp() {
    super.setUp()

    ApplicationDelegate.reset()
    delegate = ApplicationDelegate(
      notificationCenter: center,
      tokenWallet: TestAccessTokenWallet.self,
      settings: settings,
      featureChecker: featureChecker,
      appEvents: appEvents,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      store: store,
      authenticationTokenWallet: TestAuthenticationTokenWallet.self,
      profileProvider: TestProfileProvider.self,
      backgroundEventLogger: backgroundEventLogger
    )
  }

  override func tearDown() {
    super.tearDown()

    ApplicationDelegateTests.resetTestData()
  }

  static func resetTestData() {
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    TestServerConfigurationProvider.reset()
    TestSettings.reset()
    TestGateKeeperManager.reset()
    TestProfileProvider.reset()
  }

  func testDefaultDependencies() {
    XCTAssertEqual(
      ApplicationDelegate.shared.notificationObserver as? NotificationCenter,
      NotificationCenter.default,
      "Should use the default system notification center"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.tokenWallet is AccessToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.featureChecker as? FeatureManager,
      FeatureManager.shared,
      "Should use the default feature checker"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.appEvents as? AppEvents,
      AppEvents.singleton,
      "Should use the expected default app events instance"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.serverConfigurationProvider is ServerConfigurationManager.Type,
      "Should use the expected default server configuration provider"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.store as? UserDefaults,
      UserDefaults.standard,
      "Should use the expected default persistent store"
    )
    XCTAssertTrue(
      ApplicationDelegate.shared.authenticationTokenWallet is AuthenticationToken.Type,
      "Should use the expected default access token setter"
    )
    XCTAssertEqual(
      ApplicationDelegate.shared.settings as? Settings,
      Settings.shared,
      "Should use the expected default settings"
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
      delegate.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to create with a server configuration provider"
    )
    XCTAssertEqual(
      delegate.store as? UserDefaultsSpy,
      store,
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

  // MARK: - Initializing SDK

  func testInitializingSdkTriggersApplicationLifecycleNotificationsForAppEvents() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      appEvents.wasStartObservingApplicationLifecycleNotificationsCalled,
      "Should have app events start observing application lifecycle notifications upon initialization"
    )
  }

  func testInitializingSDKLogsAppEvent() {
    store.setValue(1, forKey: bitmaskKey)

    delegate._logSDKInitialize()

    XCTAssertEqual(
      appEvents.capturedEventName,
      "fb_sdk_initialize"
    )
    XCTAssertFalse(appEvents.capturedIsImplicitlyLogged)
  }

  func testInitializingSdkObservesSystemNotifications() {
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
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
      center.capturedAddObserverInvocations.contains(
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
      center.capturedAddObserverInvocations.contains(
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
        .url: SampleUrls.valid
      ]
    )

    XCTAssertEqual(
      appEvents.capturedSetSourceApplication,
      name,
      "Should set the source application based on the launch options"
    )
    XCTAssertEqual(
      appEvents.capturedSetSourceApplicationURL,
      SampleUrls.valid,
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

  // MARK: - Configuring Dependencies

  func testInitializingConfiguresError() {
    SDKError.reset()
    XCTAssertNil(
      SDKError.errorReporter,
      "Should not have an error reporter by default"
    )
    delegate.initializeSDK(launchOptions: [:])

    XCTAssertEqual(
      SDKError.errorReporter as? ErrorReport,
      ErrorReport.shared
    )
  }

  func testInitializingConfiguresModelManager() {
    ModelManager.reset()
    XCTAssertNil(ModelManager.shared.featureChecker, "Should not have a feature checker by default")
    XCTAssertNil(ModelManager.shared.graphRequestFactory, "Should not have a request factory by default")
    XCTAssertNil(ModelManager.shared.fileManager, "Should not have a file manager by default")
    XCTAssertNil(ModelManager.shared.store, "Should not have a data store by default")
    XCTAssertNil(ModelManager.shared.settings, "Should not have a settings by default")
    XCTAssertNil(ModelManager.shared.dataExtractor, "Should not have a data extractor by default")

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
  }

  // MARK: - DidFinishLaunching

  func testDidFinishLaunchingLoadsServerConfiguration() {
    delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)

    XCTAssertTrue(
      TestServerConfigurationProvider.loadServerConfigurationWasCalled,
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
      open: SampleUrls.validApp,
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
