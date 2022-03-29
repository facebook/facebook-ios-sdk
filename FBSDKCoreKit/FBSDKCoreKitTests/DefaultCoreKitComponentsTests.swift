/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class DefaultCoreKitComponentsTests: XCTestCase {
  let components = CoreKitComponents.default

  // MARK: - All Platforms

  func testAccessTokenExpirer() throws {
    let expirer = try XCTUnwrap(
      components.accessTokenExpirer as? AccessTokenExpirer,
      "The default components should use an instance of AccessTokenExpirer as its access token expirer"
    )
    XCTAssertTrue(
      expirer.notificationCenter === components.notificationCenter,
      "The expirer should use the components' notification center"
    )
  }

  func testAccessTokenWallet() {
    XCTAssertTrue(
      components.accessTokenWallet === AccessToken.self,
      "The default components should use the AccessToken type as its access token wallet"
    )
  }

  func testAdvertiserIDProvider() {
    XCTAssertTrue(
      components.advertiserIDProvider === AppEventsUtility.shared,
      "The default components should use the shared AppEventsUtility as its advertise ID provider"
    )
  }

  func testAppEvents() throws {
    XCTAssertTrue(
      components.appEvents === AppEvents.shared,
      "The default components should use the shared AppEvents as its app events"
    )
  }

  func testAppEventsConfigurationProvider() {
    XCTAssertTrue(
      components.appEventsConfigurationProvider === AppEventsConfigurationManager.shared,
      """
      The default components should use the shared \
      AppEventsConfigurationManager as its app events configuration provider
      """
    )
  }

  func testAppEventsStateProvider() {
    XCTAssertTrue(
      components.appEventsStateProvider is AppEventsStateFactory,
      "The default components should use an instance of AppEventsStateFactory as its app events state provider"
    )
  }

  func testAppEventsStateStore() {
    XCTAssertTrue(
      components.appEventsStateStore === AppEventsStateManager.shared,
      "The default components should use the shared AppEventsStateManager as its app events state store"
    )
  }

  func testAppEventsUtility() {
    XCTAssertTrue(
      components.appEventsUtility === AppEventsUtility.shared,
      "The default components should use the shared AppEventsUtility as its app events utility"
    )
  }

  func testApplicationActivationNotifier() {
    XCTAssertTrue(
      components.getApplicationActivationNotifier() as AnyObject === ApplicationDelegate.shared,
      "The default components should use the shared ApplicationDelegate as its application activation notifier"
    )
  }

  func testATEPublisherFactory() throws {
    let factory = try XCTUnwrap(
      components.atePublisherFactory as? ATEPublisherFactory,
      "The default components should use an instance of ATEPublisherFactory as its ATE publisher factory"
    )
    XCTAssertTrue(
      factory.dataStore === components.defaultDataStore,
      "The factory should use the components' default data store"
    )
    XCTAssertTrue(
      factory.graphRequestFactory === components.graphRequestFactory,
      "The factory should use the components' graph request factory"
    )
    XCTAssertTrue(
      factory.settings === components.settings,
      "The factory should use the components' settings"
    )
    XCTAssertTrue(
      factory.deviceInformationProvider === components.deviceInformationProvider,
      "The factory should use the components' device information provider"
    )
  }

  func testAuthenticationTokenWallet() {
    XCTAssertTrue(
      components.authenticationTokenWallet === AuthenticationToken.self,
      "The default components should use the AuthenticationToken type as its authentication token wallet"
    )
  }

  func testCrashHandler() {
    XCTAssertTrue(
      components.crashHandler === CrashHandler.shared,
      "The default components should use the shared CrashHandler as its crash handler"
    )
  }

  func testCrashObserver() throws {
    let crashObserver = try XCTUnwrap(
      components.crashObserver as? CrashObserver,
      "The default components should use an instance of CrashObserver as its crash observer"
    )
    XCTAssertTrue(
      crashObserver.featureChecker === components.featureChecker,
      "The crash observer should use the components' feature checker"
    )
    XCTAssertTrue(
      crashObserver.graphRequestFactory === components.graphRequestFactory,
      "The crash observer should use the components' graph request factory"
    )
    XCTAssertTrue(
      crashObserver.settings === components.settings,
      "The crash observer should use the components' settings"
    )
    XCTAssertTrue(
      crashObserver.crashHandler === components.crashHandler,
      "The crash observer should use the components' crash handler"
    )
  }

  func testDefaultDataStore() {
    XCTAssertTrue(
      components.defaultDataStore === UserDefaults.standard,
      "The default components should use the standard UserDefaults as its default data store"
    )
  }

  func testDeviceInformationProvider() {
    XCTAssertTrue(
      components.deviceInformationProvider === AppEventsDeviceInfo.shared,
      "The default components should use the shared AppEventsDeviceInfo as its device information provider"
    )
  }

  func testDialogConfigurationMapBuilder() {
    XCTAssertTrue(
      components.dialogConfigurationMapBuilder is DialogConfigurationMapBuilder,
      """
      The default components should use an instance of \
      DialogConfigurationMapBuilder as its dialog configuration map builder
      """
    )
  }

  func testErrorConfigurationProvider() {
    XCTAssertTrue(
      components.errorConfigurationProvider is ErrorConfigurationProvider,
      "The default components should use an instance of ErrorConfigurationProvider as its error configuration provider"
    )
  }

  func testErrorFactory() throws {
    let factory = try XCTUnwrap(
      components.errorFactory as? ErrorFactory,
      "The default components should use an instance of ErrorFactory as its error factory"
    )
    XCTAssertTrue(
      factory.reporter === components.errorReporter,
      "The factory should use the components' error reporter"
    )
  }

  func testErrorReporter() {
    XCTAssertTrue(
      components.errorReporter === ErrorReporter.shared,
      "The default components should use the shared ErrorReporter as its error reporter"
    )
  }

  func testEventDeactivationManager() {
    XCTAssertTrue(
      components.eventDeactivationManager is EventDeactivationManager,
      "The default components should use an instance of EventDeactivationManager as its event deactivation manager"
    )
  }

  func testEventLogger() {
    XCTAssertTrue(
      components.eventLogger === components.appEvents,
      "The default components should use the components' app events as its event logger"
    )
  }

  func testFeatureChecker() {
    XCTAssertTrue(
      components.featureChecker === FeatureManager.shared,
      "The default components should use the shared FeatureManager as its feature checker"
    )
  }

  func testGateKeeperManager() {
    XCTAssertTrue(
      components.gateKeeperManager === GateKeeperManager.self,
      "The default components should use the GateKeeperManager type as its gate keeper manager"
    )
  }

  func testGraphRequestConnectionFactory() {
    XCTAssertTrue(
      components.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      """
      The default components should use an instance of \
      GraphRequestConnectionFactory as its graph request connection factory
      """
    )
  }

  func testGraphRequestFactory() {
    XCTAssertTrue(
      components.graphRequestFactory is GraphRequestFactory,
      "The default components should use an instance of GraphRequestFactory as its graph request factory"
    )
  }

  func testImpressionLoggerFactory() throws {
    let factory = try XCTUnwrap(
      components.impressionLoggerFactory as? ImpressionLoggerFactory,
      "The default components should use an instance of ImpressionLoggerFactory as its impression logger factory"
    )
    XCTAssertTrue(
      factory.graphRequestFactory === components.graphRequestFactory,
      "The factory should use the components' graph request factory"
    )
    XCTAssertTrue(
      factory.eventLogger === components.eventLogger,
      "The factory should use the components' app events"
    )
    XCTAssertTrue(
      factory.notificationCenter === components.notificationCenter,
      "The factory should use the components' notification center"
    )
    XCTAssertTrue(
      factory.accessTokenWallet === components.accessTokenWallet,
      "The factory should use the components' access token wallet"
    )
  }

  func testInfoDictionaryProvider() {
    XCTAssertTrue(
      components.infoDictionaryProvider === Bundle.main,
      "The default components should use the main Bundle as its info dictionary provider"
    )
  }

  func testInternalUtility() {
    XCTAssertTrue(
      components.internalUtility === InternalUtility.shared,
      "The default components should use the shared InternalUtility as its internal utility"
    )
  }

  func testLogger() {
    XCTAssertTrue(
      components.logger === Logger.self,
      "The default components should use the Logger type as its logger"
    )
  }

  func testLoggerFactory() {
    XCTAssertTrue(
      components.loggerFactory is LoggerFactory,
      "The default components should use an instance of LoggerFactory as its logger factory"
    )
  }

  func testMacCatalystDeterminator() {
    XCTAssertTrue(
      components.macCatalystDeterminator === ProcessInfo.processInfo,
      "The default components should use the default ProcessInfo as its Mac Catalyst determinator"
    )
  }

  func testNotificationCenter() {
    XCTAssertTrue(
      components.notificationCenter === NotificationCenter.default,
      "The default components should use the default NotificationCenter as its notification center"
    )
  }

  func testOperatingSystemVersionComparer() {
    XCTAssertTrue(
      components.operatingSystemVersionComparer === ProcessInfo.processInfo,
      "The default components should use the default ProcessInfo as its operating system version comparer"
    )
  }

  func testPaymentObserver() throws {
    let observer = try XCTUnwrap(
      components.paymentObserver as? PaymentObserver,
      "The default components should use an instance of PaymentObserver as its payment observer"
    )
    XCTAssertTrue(
      observer.paymentQueue === SKPaymentQueue.default(),
      "The observer should use the default SKPaymentQueue as its payment queue"
    )
    let factory = try XCTUnwrap(
      observer.requestorFactory as? PaymentProductRequestorFactory,
      "The observer should use an instance of PaymentProductRequestorFactory as its requestor factory"
    )
    XCTAssertTrue(
      factory.settings === components.settings,
      "The factory should use the components' settings"
    )
    XCTAssertTrue(
      factory.eventLogger === components.eventLogger,
      "The factory should use the components' app events"
    )
    XCTAssertTrue(
      factory.gateKeeperManager === components.gateKeeperManager,
      "The factory should use the components' gate keeper manager"
    )
    XCTAssertTrue(
      factory.store === components.defaultDataStore,
      "The factory should use the components' default data store"
    )
    XCTAssertTrue(
      factory.loggerFactory === components.loggerFactory,
      "The factory should use the components' logger factory"
    )
    XCTAssertTrue(
      factory.productsRequestFactory is ProductRequestFactory,
      "The factory should use an instance of ProductRequestFactory for its products request factory"
    )
    XCTAssertTrue(
      factory.appStoreReceiptProvider === Bundle(for: ApplicationDelegate.self),
      "The factory should use the bundle of the application delegate"
    )
  }

  func testPiggybackManager() throws {
    let manager = try XCTUnwrap(
      components.piggybackManager as? GraphRequestPiggybackManager,
      """
      The default components should use an instance of GraphRequestPiggybackManager as \
      its graph request piggyback manager
      """
    )
    XCTAssertIdentical(
      manager.tokenWallet,
      components.accessTokenWallet,
      "The piggyback manager should use the components' access token wallet"
    )

    XCTAssertIdentical(
      manager.settings,
      components.settings,
      "The piggyback manager should use the components' settings"
    )
    XCTAssertIdentical(
      manager.serverConfigurationProvider,
      components.serverConfigurationProvider,
      "The piggyback manager should use the components' server configuration provider"
    )
    XCTAssertIdentical(
      manager.graphRequestFactory,
      components.graphRequestFactory,
      "The piggyback manager should use the components' graph request factory"
    )
  }

  func testRestrictiveDataFilterManager() throws {
    let manager = try XCTUnwrap(
      components.restrictiveDataFilterManager as? RestrictiveDataFilterManager,
      """
      The default components should use an instance of \
      RestrictiveDataFilterManager as its restrictive data filter manager
      """
    )
    XCTAssertTrue(
      manager.serverConfigurationProvider === components.serverConfigurationProvider,
      "The factory should use the components' server configuration provider"
    )
  }

  func testServerConfigurationProvider() {
    XCTAssertTrue(
      components.serverConfigurationProvider === ServerConfigurationManager.shared,
      "The default components should use the shared ServerConfigurationManager as its server configuration provider"
    )
  }

  func testSettings() {
    XCTAssertTrue(
      components.settings === Settings.shared,
      "The default components should use the shared Settings as its settings"
    )
  }

  func testTimeSpentRecorder() throws {
    let recorder = try XCTUnwrap(
      components.timeSpentRecorder as? TimeSpentData,
      "The default components should use an instance of TimeSpentData as its time spent recorder"
    )
    XCTAssertTrue(
      recorder.eventLogger === components.eventLogger,
      "The recorder should use the components' event logger"
    )
    XCTAssertTrue(
      recorder.serverConfigurationProvider === components.serverConfigurationProvider,
      "The recorder should use the components' server configuration provider"
    )
  }

  func testTokenCache() throws {
    let cache = try XCTUnwrap(
      components.tokenCache as? TokenCache,
      "The default components should use an instance of TokenCache as its token cache"
    )
    XCTAssertTrue(
      cache.settings === components.settings,
      "The cache should use the components' settings"
    )

    let store = try XCTUnwrap(
      cache.keychainStore as? KeychainStore,
      "The cache should use an instance of KeychainStore as its keychain store"
    )

    let identifier = try XCTUnwrap(Bundle.main.bundleIdentifier)
    XCTAssertEqual(
      store.service,
      "\(DefaultKeychainServicePrefix).\(identifier)",
      "The keychain store's service should be composed of the default prefix and the main bundle identifier"
    )
    XCTAssertNil(
      store.accessGroup,
      "The keychain store's access group should be nil"
    )
  }

  func testURLSessionProxyFactory() {
    XCTAssertTrue(
      components.urlSessionProxyFactory is URLSessionProxyFactory,
      "The default components should use an instance of URLSessionProxyFactory as its URL session proxy factory"
    )
  }

  func testUserDataStore() {
    XCTAssertTrue(
      components.userDataStore is UserDataStore,
      "The default components should use an instance of UserDataStore as its user data store"
    )
  }

  // MARK: - Non-tvOS

  @available(iOS 14, *)
  func testAEMNetworker() {
    XCTAssertNotNil(
      components.aemNetworker as? _AEMNetworker,
      "The default components should use an instance of AEMNetworker as its AEM networker"
    )
  }

  func testAppEventParametersExtractor() {
    XCTAssertTrue(
      components.appEventParametersExtractor === AppEventsUtility.shared,
      "The default components should use the shared AppEventsUtility as its app event parameters extractor"
    )
  }

  func testAppEventsDropDeterminer() {
    XCTAssertTrue(
      components.appEventsDropDeterminer === AppEventsUtility.shared,
      "The default components should use the shared AppEventsUtility as its app events drop determiner"
    )
  }

  func testAppLinkEventPoster() {
    XCTAssertTrue(
      components.appLinkEventPoster is MeasurementEvent,
      "The default components should use an instance of MeasurementEvent as its app link event poster"
    )
  }

  func testAppLinkFactory() {
    XCTAssertTrue(
      components.appLinkFactory is AppLinkFactory,
      "The default components should use an instance of AppLinkFactory as its app link factory"
    )
  }

  func testAppLinkResolver() {
    XCTAssertTrue(
      components.appLinkResolver === WebViewAppLinkResolver.shared,
      "The default components should use the shared WebViewAppLinkResolver as its app link resolver"
    )
  }

  func testAppLinkTargetFactory() {
    XCTAssertTrue(
      components.appLinkTargetFactory is AppLinkTargetFactory,
      "The default components should use an instance of AppLinkTargetFactory as its app link target factory"
    )
  }

  func testAppLinkURLFactory() {
    XCTAssertTrue(
      components.appLinkURLFactory is AppLinkURLFactory,
      "The default components should use an instance of AppLinkURLFactory as its app link URL factory"
    )
  }

  func testBackgroundEventLogger() throws {
    let logger = try XCTUnwrap(
      components.backgroundEventLogger as? BackgroundEventLogger,
      "The default components should use an instance of BackgroundEventLogger as its background event logger"
    )
    XCTAssertTrue(
      logger.infoDictionaryProvider === components.infoDictionaryProvider,
      "The cache should use the components' info dictionary provider"
    )
    XCTAssertTrue(
      logger.eventLogger === components.eventLogger,
      "The cache should use the components' app events"
    )
  }

  func testCodelessIndexer() {
    XCTAssertTrue(
      components.codelessIndexer === CodelessIndexer.self,
      "The default components should use the CodelessIndexer type as its codeless indexer"
    )
  }

  func testDataExtractor() {
    XCTAssertTrue(
      components.dataExtractor === NSData.self,
      "The default components should use the NSData type as its data extractor"
    )
  }

  func testFeatureExtractor() {
    XCTAssertTrue(
      components.featureExtractor === FeatureExtractor.self,
      "The default components should use the FeatureExtractor type as its feature extractor"
    )
  }

  func testFileManager() {
    XCTAssertTrue(
      components.fileManager === FileManager.default,
      "The default components should use the default FileManager as its file manager"
    )
  }

  func testInternalURLOpener() {
    XCTAssertTrue(
      components.internalURLOpener === UIApplication.shared,
      "The default components should use the shared UIApplication as its internal URL opener"
    )
  }

  func testMetadataIndexer() throws {
    let indexer = try XCTUnwrap(
      components.metadataIndexer as? MetadataIndexer,
      "The default components should use an instance of MetadataIndexer as its metadata indexer"
    )
    XCTAssertTrue(
      indexer.userDataStore === components.userDataStore,
      "The indexer should use the components' user data store"
    )
    XCTAssertTrue(
      indexer.swizzler === components.swizzler,
      "The indexer should use the components' swizzler"
    )
  }

  func testModelManager() {
    XCTAssertTrue(
      components.modelManager === ModelManager.shared,
      "The default components should use the shared ModelManager as its model manager"
    )
  }

  func testProfileSetter() {
    XCTAssertTrue(
      components.profileSetter === Profile.self,
      "The default components should use the Profile type as its profile setter"
    )
  }

  func testRulesFromKeyProvider() {
    XCTAssertTrue(
      components.rulesFromKeyProvider === ModelManager.shared,
      "The default components should use the shared ModelManager as its rules from key provider"
    )
  }

  func testSessionDataTaskProvider() {
    XCTAssertTrue(
      components.sessionDataTaskProvider === URLSession.shared,
      "The default components should use the shared URLSession as its session data task provider"
    )
  }

  @available(iOS 11.3, *)
  func testSKAdNetworkReporter() throws {
    let reporter = try XCTUnwrap(
      components.skAdNetworkReporter as? SKAdNetworkReporter,
      "The default components should use an instance of SKAdNetworkReporter as its StoreKit ad network reporter"
    )
    XCTAssertTrue(
      reporter.graphRequestFactory === components.graphRequestFactory,
      "The reporter should use the components' graph request factory"
    )
    XCTAssertTrue(
      reporter.dataStore === components.defaultDataStore,
      "The reporter should use the components' default data store"
    )
    XCTAssertTrue(
      reporter.conversionValueUpdater === SKAdNetwork.self,
      "The reporter should use the SKAdNetwork type as its conversion value updater"
    )
  }

  func testSuggestedEventsIndexer() throws {
    let indexer = try XCTUnwrap(
      components.suggestedEventsIndexer as? SuggestedEventsIndexer,
      "The default components should use an instance of SuggestedEventsIndexer as its suggested events indexer"
    )
    XCTAssertTrue(
      indexer.graphRequestFactory === components.graphRequestFactory,
      "The indexer should use the components' graph request factory"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider === components.serverConfigurationProvider,
      "The indexer should use the components' server configuration provider"
    )
    XCTAssertTrue(
      indexer.swizzler === components.swizzler,
      "The indexer should use the components' swizzler"
    )
    XCTAssertTrue(
      indexer.settings === components.settings,
      "The indexer should use the components' settings"
    )
    XCTAssertTrue(
      indexer.eventLogger === components.eventLogger,
      "The indexer should use the components' event logger"
    )
    XCTAssertTrue(
      indexer.featureExtractor === components.featureExtractor,
      "The indexer should use the components' feature extractor"
    )
    XCTAssertTrue(
      indexer.eventProcessor === components.modelManager,
      "The indexer should use the components' model manager"
    )
  }

  func testSwizzler() {
    XCTAssertTrue(
      components.swizzler === Swizzler.self,
      "The default components should use the Swizzler type as its swizzler"
    )
  }

  func testURLHoster() {
    XCTAssertTrue(
      components.urlHoster === InternalUtility.shared,
      "The default components should use the shared InternalUtility as its URL hoster"
    )
  }

  func testUserIDProvider() {
    XCTAssertTrue(
      components.userIDProvider === components.appEvents,
      "The default components should use the components' app events as its user ID provider"
    )
  }

  func testWebViewProvider() {
    XCTAssertTrue(
      components.webViewProvider is WebViewFactory,
      "The default components should use an instance of WebViewFactory as its web view provider"
    )
  }
}
