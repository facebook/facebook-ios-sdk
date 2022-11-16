/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

/**
 An `ApplicationDelegate` is designed to post-process the results from Facebook Login
 or Facebook Dialogs (or any action that requires switching over to the native Facebook
 app or Safari).

 The methods in this class are designed to mirror those in `UIApplicationDelegate`, and you
 should call them in the respective methods in your application delegate implementation.
 */
@objcMembers
@objc(FBSDKApplicationDelegate)
public final class ApplicationDelegate: NSObject {

  var applicationObservers = NSHashTable<FBSDKApplicationObserving>(options: .weakMemory)
  let components: CoreKitComponents
  let configurator: CoreKitConfiguring
  var isAppLaunched = false
  private var hasInitializeBeenCalled = false
  var applicationState = UIApplication.State.active {
    didSet {
      components.appEvents.setApplicationState(applicationState)
    }
  }

  private static let kitsBitmaskKey = "com.facebook.sdk.kits.bitmask"

  /// Gets the singleton instance.
  @objc(sharedInstance)
  public private(set) static var shared = ApplicationDelegate()

  override convenience init() {
    let components = CoreKitComponents.default
    self.init(components: components, configurator: CoreKitConfigurator(components: components))
  }

  init(components: CoreKitComponents, configurator: CoreKitConfiguring) {
    self.components = components
    self.configurator = configurator
    super.init()
  }

  /**
   Initializes the SDK.

   If you are using the SDK within the context of the `UIApplication` lifecycle, do not use this method.
   Instead use `application(_:didFinishLaunchingWithOptions:)`.

   As part of SDK initialization, basic auto logging of app events will occur, this can be
   controlled via the 'FacebookAutoLogAppEventsEnabled' key in your project's Info.plist file.
   */
  public func initializeSDK() {
    initializeSDK(launchOptions: [:])
  }

  func initializeSDK(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    guard !hasInitializeBeenCalled else { return }

    hasInitializeBeenCalled = true

    // DO NOT MOVE THIS CALL
    // Dependencies MUST be configured before they are used
    configurator.performConfiguration()

    logInitialization()
    addObservers()
    components.appEvents.startObservingApplicationLifecycleNotifications()
    _ = application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
    handleDeferredActivationIfNeeded()
    enableInstrumentation()

    #if !os(tvOS)
    logBackgroundRefreshStatus()
    initializeAppLink()
    #endif

    configureSourceApplication(launchOptions: launchOptions)
  }

  @available(tvOS, unavailable)
  private func initializeAppLink() {
    initializeMeasurementListener()
    logIfAutoAppLinkEnabled()
  }

  private func handleDeferredActivationIfNeeded() {
    // If SDK initialization is deferred until after the applicationDidBecomeActive notification is received,
    // then we need to manually perform this work in case it hasn't happened at all.
    if UIApplication.shared.applicationState == .active {
      applicationDidBecomeActive(nil)
    }
  }

  private func configureSourceApplication(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    // Set the SourceApplication for time spent data. This is not going to update the value
    // if the app has already launched.
    components.appEvents.setSourceApplication(
      launchOptions?[.sourceApplication] as? String,
      open: launchOptions?[.url] as? URL
    )

    // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
    components.appEvents.registerAutoResetSourceApplication()
    components.internalUtility.validateFacebookReservedURLSchemes()
  }

  @available(tvOS, unavailable)
  private func initializeMeasurementListener() {
    #if !os(tvOS)
    // Register Listener for App Link measurement events
    _MeasurementEventListener(eventLogger: components.appEvents, sourceApplicationTracker: components.appEvents)
      .registerForAppLinkMeasurementEvents()
    #endif
  }

  @available(tvOS, unavailable)
  private func logBackgroundRefreshStatus() {
    #if !os(tvOS)
    components.backgroundEventLogger.logBackgroundRefreshStatus(UIApplication.shared.backgroundRefreshStatus)
    #endif
  }

  private func logInitialization() {
    components.settings.logWarnings()
    components.settings.logIfSDKSettingsChanged()
    components.settings.recordInstall()
  }

  private func enableInstrumentation() {
    components.featureChecker.check(.instrument) { enabled in
      if enabled {
        _InstrumentManager.shared.enable()
      }
    }
  }

  private func addObservers() {
    components.notificationCenter.fb_addObserver(
      self,
      selector: #selector(applicationDidEnterBackground(_:)),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    components.notificationCenter.fb_addObserver(
      self,
      selector: #selector(applicationDidBecomeActive(_:)),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    components.notificationCenter.fb_addObserver(
      self,
      selector: #selector(applicationWillResignActive(_:)),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    #if !os(tvOS)
    addObserver(_BridgeAPI.shared)
    #endif
  }

  // MARK: - UIApplicationDelegate-like interface

  /**
   Call this method from the `UIApplicationDelegate.application(_:continue:restorationHandler:)` method
   of your application delegate. It should be invoked in order to properly process the web URL (universal link)
   once the end user is redirected to your app.

   - Parameters:
     - application: The application as passed to `UIApplicationDelegate.application(_:continue:restorationHandler:).
     - userActivity: The user activity as passed to `UIApplicationDelegate.application(_:continue:restorationHandler:)`.

   - Returns: `true` if the URL was intended for the Facebook SDK, `false` if not.
   */
  @discardableResult
  @objc(application:continueUserActivity:)
  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity
  ) -> Bool {
    guard
      userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else { return false }

    return self.application(application, open: url, options: [:])
  }

  /**
   Call this method from the `UIApplicationDelegate.application(_:open:options:)` method
   of your application delegate. It should be invoked for the proper processing of responses during interaction
   with the native Facebook app or Safari as part of an SSO authorization flow or Facebook dialogs.

   - Parameters:
     - application: The application as passed to `UIApplicationDelegate.application(_:open:options:)`.
     - url: The URL as passed to `UIApplicationDelegate.application(_:open:options:)`.
     - options: The options dictionary as passed to `UIApplicationDelegate.application(_:open:options:)`.

   - Returns: `true` if the URL was intended for the Facebook SDK, `false` if not.
   */
  @discardableResult
  @objc(application:openURL:options:)
  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any]
  ) -> Bool {
    self.application(
      application,
      open: url,
      sourceApplication: options[.sourceApplication] as? String,
      annotation: options[.annotation]
    )
  }

  /**
   Call this method from the `UIApplicationDelegate.application(_:openL:sourceApplication:annotation:)` method
   of your application delegate. It should be invoked for the proper processing of responses during interaction
   with the native Facebook app or Safari as part of an SSO authorization flow or Facebook dialogs.

   - Parameters:
     - application: The application as passed to `UIApplicationDelegate.application(_:open:sourceApplication:annotation:)`.
     - url: The URL as passed to `UIApplicationDelegate.application(_:open:sourceApplication:annotation:)`.
     - sourceApplication: The source application as passed to `UIApplicationDelegate.application(_:open:sourceApplication:annotation:)`.
     - annotation: The annotation as passed to `UIApplicationDelegate.application(_:open:sourceApplication:annotation:)`.

   - Returns: `true` if the URL was intended for the Facebook SDK, `false` if not.
   */
  @discardableResult
  @objc(application:openURL:sourceApplication:annotation:)
  public func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    components.appEvents.setSourceApplication(sourceApplication, open: url)

    #if !os(tvOS)
    components.featureChecker.check(.AEM) { enabled in
      guard enabled else { return }

      let featureChecker = self.components.featureChecker

      AEMReporter.setCatalogMatchingEnabled(featureChecker.isEnabled(.aemCatalogMatching))
      AEMReporter.setConversionFilteringEnabled(featureChecker.isEnabled(.aemConversionFiltering))
      AEMReporter.setAdvertiserRuleMatchInServerEnabled(featureChecker.isEnabled(.aemAdvertiserRuleMatchInServer))
      AEMReporter.enable()
      AEMReporter.handle(url)
    }
    #endif

    var handled = false
    applicationObservers.allObjects.forEach { observer in
      let observerHandled = observer.application?(
        application,
        open: url,
        sourceApplication: sourceApplication,
        annotation: annotation
      )

      if observerHandled ?? false {
        handled = true
      }
    }

    if handled {
      return true
    } else {
      logIfAppLinkEvent(url: url)
      return false
    }
  }

  // MARK: Finish Launching

  /**
   Call this method from the `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)` method
   of your application delegate. It should be invoked for the proper use of the Facebook SDK.
   As part of SDK initialization, basic auto-logging of app events will occur; this can be
   controlled via the `FacebookAutoLogAppEventsEnabled` key in the project's Info.plist file.

   - Parameters:
     - application: The application as passed to `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.
     - launchOptions: The launch options as passed to `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.

   - Returns: `true` if there are any added application observers that themselves return true from calling `application(_:didFinishLaunchingWithOptions:)`.
     Otherwise will return `false`.

   - Note: If this method is called after calling `initializeSDK`, then the return value will always be `false`.
   */
  @discardableResult
  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    guard
      !isAppLaunched,
      !hasInitializeBeenCalled
    else { return false }

    initializeSDK(launchOptions: launchOptions)
    isAppLaunched = true

    initializeTokenCache()
    fetchServerConfiguration()

    if components.settings.isAutoLogAppEventsEnabled {
      logSDKInitialize()
    }

    #if !os(tvOS)
    initializeProfile()
    checkAuthentication()
    #endif

    return notifyLaunchObservers(application: application, launchOptions: launchOptions)
  }

  private func initializeTokenCache() {
    components.accessTokenWallet.current = components.accessTokenWallet.tokenCache?.accessToken
  }

  private func fetchServerConfiguration() {
    components.serverConfigurationProvider.loadServerConfiguration(completionBlock: nil)
  }

  @available(tvOS, unavailable)
  private func initializeProfile() {
    #if !os(tvOS)
    components.profileSetter.current = components.profileSetter.fetchCachedProfile()
    #endif
  }

  @available(tvOS, unavailable)
  private func checkAuthentication() {
    #if !os(tvOS)
    components.authenticationTokenWallet.current = components.authenticationTokenWallet.tokenCache?.authenticationToken
    _AuthenticationStatusUtility.checkAuthenticationStatus()
    #endif
  }

  private func notifyLaunchObservers(
    application: UIApplication,
    launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var someObserverHandledLaunch = false
    applicationObservers.allObjects.forEach { observer in
      let observerHandled = observer.application?(
        application,
        didFinishLaunchingWithOptions: launchOptions
      )

      if observerHandled ?? false {
        someObserverHandledLaunch = true
      }
    }

    return someObserverHandledLaunch
  }

  // MARK: Entering Background

  func applicationDidEnterBackground(_ notification: Notification) {
    applicationState = .background
    applicationObservers.allObjects.forEach { observer in
      observer.applicationDidEnterBackground?(notification.object as? UIApplication)
    }
  }

  func applicationDidBecomeActive(_ notification: Notification?) {
    applicationState = .active

    // Auto log basic events in case auto-logging of app events is enabled
    if components.settings.isAutoLogAppEventsEnabled {
      components.appEvents.activateApp()
    }

    #if !os(tvOS)
    components.skAdNetworkReporter?.checkAndRevokeTimer()
    #endif

    applicationObservers.allObjects.forEach { observer in
      observer.applicationDidBecomeActive?(notification?.object as? UIApplication)
    }
  }

  func applicationWillResignActive(_ notification: Notification) {
    applicationState = .active
    applicationObservers.allObjects.forEach { observer in
      observer.applicationWillResignActive?(notification.object as? UIApplication)
    }
  }

  // MARK: - Internal Methods

  // MARK: FBSDKApplicationObserving

  /**
   Adds an observer that will be informed about application lifecycle events.

   - Note: Observers are weakly held
   */
  public func addObserver(_ observer: FBSDKApplicationObserving) {
    applicationObservers.add(observer)
  }

  /// Removes an observer so that it will no longer be informed about application lifecycle events.
  public func removeObserver(_ observer: FBSDKApplicationObserving) {
    applicationObservers.remove(observer)
  }

  private func logIfAppLinkEvent(url: URL) {
    guard let query = url.query else { return }

    let parameters = BasicUtility.dictionary(withQueryString: query)
    guard
      let appLinkDataString = parameters["al_applink_data"],
      let rawData = appLinkDataString.data(using: .utf8),
      let appLinkData = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any]
    else { return }

    var logData = [AppEvents.ParameterName: Any]()

    let targetURLString = appLinkData["target_url"] as? String
    if let targetURL = targetURLString.flatMap(URL.init(string:)) {
      logData[.targetURL] = targetURL.absoluteString
      logData[.targetURLHost] = targetURL.host
    }

    if let referrerData = appLinkData["referer_data"] as? [String: Any] {
      logData[.referralTargetURL] = referrerData["target_url"]
      logData[.referralURL] = referrerData["url"]
      logData[.referralAppName] = referrerData["app_name"]
    }

    logData[.inputURL] = url.absoluteString
    logData[.inputURLScheme] = url.scheme

    components.appEvents.logInternalEvent(
      .appLinkInboundEvent,
      parameters: logData,
      isImplicitlyLogged: true
    )
  }

  func logSDKInitialize() {
    let frameworkFlagMap: [String: AppEvents.ParameterName] = [
      "FBSDKLoginManager": .isLoginLibraryIncluded,
      "FBSDKAutoLog": .isMarketingLibraryIncluded,
      "FBSDKMessengerButton": .isMessengerLibraryIncluded,
      "FBSDKPlacesManager": .isPlacesLibraryIncluded,
      "FBSDKShareDialog": .isShareLibraryIncluded,
      "FBSDKTVInterfaceFactory": .isTVLibraryIncluded,
    ]

    var bitmask = 0
    var bit = 0
    var parameters: [AppEvents.ParameterName: Any] = [.isCoreKitIncluded: 1]

    frameworkFlagMap.forEach { className, parameterName in
      if objc_lookUpClass(className) != nil {
        parameters[parameterName] = 1
        bitmask |= 1 << bit
      }

      bit += 1
    }

    let existingBitmask = components.defaultDataStore.fb_integer(forKey: Self.kitsBitmaskKey)
    if existingBitmask != bitmask {
      components.defaultDataStore.fb_setInteger(bitmask, forKey: Self.kitsBitmaskKey)
      components.appEvents.logInternalEvent(
        .initializeSDK,
        parameters: parameters,
        isImplicitlyLogged: false
      )
    }
  }

  @available(tvOS, unavailable)
  private func logIfAutoAppLinkEnabled() {
    #if !os(tvOS)
    let enabled = components.infoDictionaryProvider.fb_object(forInfoDictionaryKey: "FBSDKAutoAppLinkEnabled") as? Bool
    if enabled ?? false {
      var parameters = [AppEvents.ParameterName: Any]()
      if !AppLinkUtility.isMatchURLScheme("fb\(components.settings.appID ?? "nil")") {
        let warning = "You haven't set the Auto App Link URL scheme: fb<YOUR APP ID>"
        parameters[.schemeWarning] = warning
        print(warning)
      }

      components.appEvents.logInternalEvent(
        .autoAppLink,
        parameters: parameters,
        isImplicitlyLogged: true
      )
    }
    #endif
  }

  // MARK: - Testability

  #if DEBUG
  func resetHasInitializeBeenCalled() {
    hasInitializeBeenCalled = false
  }

  func resetApplicationObserverCache() {
    applicationObservers = NSHashTable<FBSDKApplicationObserving>(options: .weakMemory)
  }
  #endif
}

// swiftformat:disable:next extensionaccesscontrol
fileprivate extension AppEvents.Name {
  static let appLinkInboundEvent = Self("fb_al_inbound")
  static let autoAppLink = Self("fb_auto_applink")
}

// swiftformat:disable:next extensionaccesscontrol
fileprivate extension AppEvents.ParameterName {
  static let targetURL = Self("targetURL")
  static let targetURLHost = Self("targetURLHost")
  static let referralTargetURL = Self("referralTargetURL")
  static let referralURL = Self("referralURL")
  static let referralAppName = Self("referralAppName")
  static let inputURL = Self("inputURL")
  static let inputURLScheme = Self("inputURLScheme")
  static let isCoreKitIncluded = Self("core_lib_included")
  static let isLoginLibraryIncluded = Self("login_lib_included")
  static let isMarketingLibraryIncluded = Self("marketing_lib_included")
  static let isMessengerLibraryIncluded = Self("messenger_lib_included")
  static let isPlacesLibraryIncluded = Self("places_lib_included")
  static let isShareLibraryIncluded = Self("share_lib_included")
  static let isTVLibraryIncluded = Self("tv_lib_included")
  static let schemeWarning = Self("SchemeWarning")
}
