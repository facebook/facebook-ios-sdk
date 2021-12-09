/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum TestCoreKitComponents {

  static func makeComponents() -> CoreKitComponents {
    CoreKitComponents(
      accessTokenExpirer: TestAccessTokenExpirer(),
      accessTokenWallet: TestAccessTokenWallet.self,
      advertiserIDProvider: TestAdvertiserIDProvider(),
      appEvents: TestAppEvents(),
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider(),
      appEventsStateProvider: TestAppEventsStateProvider(),
      appEventsStateStore: TestAppEventsStateStore(),
      appEventsUtility: TestAppEventsUtility(),
      applicationActivationNotifier: UninhabitedObject(),
      atePublisherFactory: TestATEPublisherFactory(),
      authenticationTokenWallet: TestAuthenticationTokenWallet.self,
      crashHandler: TestCrashHandler(),
      crashObserver: TestCrashObserver(),
      defaultDataStore: TestDataStore(),
      deviceInformationProvider: TestDeviceInformationProvider(),
      dialogConfigurationMapBuilder: TestDialogConfigurationMapBuilder(),
      errorConfigurationProvider: TestErrorConfigurationProvider(),
      errorFactory: TestErrorFactory(),
      errorReporter: TestErrorReporter(),
      eventDeactivationManager: TestAppEventsParameterProcessor(),
      eventLogger: TestEventLogger(),
      featureChecker: TestFeatureManager(),
      gateKeeperManager: TestGateKeeperManager.self,
      graphRequestConnectionFactory: TestGraphRequestConnectionFactory(),
      graphRequestFactory: TestGraphRequestFactory(),
      impressionLoggerFactory: TestImpressionLoggerFactory(),
      infoDictionaryProvider: TestBundle(),
      logger: TestLogger.self,
      loggerFactory: TestLoggerFactory(),
      macCatalystDeterminator: TestMacCatalystDeterminator(),
      operatingSystemVersionComparer: TestProcessInfo(),
      paymentObserver: TestPaymentObserver(),
      piggybackManager: TestGraphRequestPiggybackManager.self,
      restrictiveDataFilterManager: TestAppEventsParameterProcessor(),
      serverConfigurationProvider: TestServerConfigurationProvider(),
      settings: TestSettings(),
      timeSpentRecorder: TestTimeSpentRecorder(),
      tokenCache: TestTokenCache(),
      urlSessionProxyFactory: TestURLSessionProxyFactory(),
      userDataStore: TestUserDataStore(),

      // Non-tvOS
      aemNetworker: TestAEMNetworker(),
      aemReporter: TestAEMReporter.self,
      appEventParametersExtractor: TestAppEventParametersExtractor(),
      appEventsDropDeterminer: TestAppEventsDropDeterminer(),
      appLinkEventPoster: TestAppLinkEventPoster(),
      appLinkFactory: TestAppLinkFactory(),
      appLinkResolver: TestAppLinkResolver(),
      appLinkTargetFactory: TestAppLinkTargetFactory(),
      appLinkURLFactory: TestAppLinkURLFactory(),
      backgroundEventLogger: TestBackgroundEventLogger(),
      codelessIndexer: TestCodelessEvents.self,
      dataExtractor: TestFileDataExtractor.self,
      featureExtractor: TestFeatureExtractor.self,
      fileManager: TestFileManager(),
      internalURLOpener: TestInternalURLOpener(),
      internalUtility: TestInternalUtility(),
      metadataIndexer: TestMetadataIndexer(),
      modelManager: TestOnDeviceMLModelManager(),
      notificationCenter: TestNotificationCenter(),
      profileSetter: TestProfileProvider.self,
      rulesFromKeyProvider: TestOnDeviceMLModelManager(),
      sessionDataTaskProvider: TestSessionProvider(),
      skAdNetworkReporter: TestSKAdNetworkReporter(),
      suggestedEventsIndexer: TestSuggestedEventsIndexer(),
      swizzler: TestSwizzler.self,
      urlHoster: TestURLHoster(),
      userIDProvider: TestUserIDProvider(),
      webViewProvider: TestWebViewFactory()
    )
  }
}
