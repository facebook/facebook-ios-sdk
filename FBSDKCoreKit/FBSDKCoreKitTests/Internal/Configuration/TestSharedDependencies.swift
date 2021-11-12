/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum TestSharedDependencies {
  // swiftlint:disable:next function_body_length
  static func makeDependencies() -> SharedDependencies {
    SharedDependencies(
      accessTokenWallet: TestAccessTokenWallet.self,
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider(),
      applicationActivationNotifier: UninhabitedObject(),
      atePublisherFactory: TestAtePublisherFactory(),
      authenticationTokenWallet: TestAuthenticationTokenWallet.self,
      crashHandler: TestCrashHandler(),
      crashObserver: TestCrashObserver(),
      defaultDataStore: TestDataStore(),
      deviceInformationProvider: TestDeviceInformationProvider(),
      errorConfigurationProvider: TestErrorConfigurationProvider(),
      errorFactory: TestErrorFactory(),
      errorReporter: TestErrorReporter(),
      eventDeactivationManager: TestAppEventsParameterProcessor(),
      eventLogger: TestEventLogger(),
      featureChecker: TestFeatureManager(),
      gateKeeperManager: TestGateKeeperManager.self,
      graphRequestConnectionFactory: TestGraphRequestConnectionFactory(),
      graphRequestFactory: TestGraphRequestFactory(),
      infoDictionaryProvider: TestBundle(),
      loggerFactory: TestLoggerFactory(),
      macCatalystDeterminator: TestMacCatalystDeterminator(),
      operatingSystemVersionComparer: TestProcessInfo(),
      piggybackManagerProvider: TestGraphRequestPiggybackManagerProvider(),
      restrictiveDataFilterManager: TestAppEventsParameterProcessor(),
      serverConfigurationProvider: TestServerConfigurationProvider(),
      settings: TestSettings(),
      timeSpentRecordingFactory: TestTimeSpentRecorderFactory(),
      tokenCache: TestTokenCache(),
      urlSessionProxyFactory: TestURLSessionProxyFactory(),
      userDataStore: TestUserDataStore(),

      // Non-tvOS
      advertiserIDProvider: TestAdvertiserIDProvider(),
      aemNetworker: TestAEMNetworker(),
      appEventParametersExtractor: TestAppEventParametersExtractor(),
      appEventsDropDeterminer: TestAppEventsDropDeterminer(),
      appLinkFactory: TestAppLinkFactory(),
      appLinkTargetFactory: TestAppLinkTargetFactory(),
      appLinkURLFactory: TestAppLinkURLFactory(),
      codelessIndexer: TestCodelessEvents.self,
      dataExtractor: TestFileDataExtractor.self,
      fileManager: TestFileManager(),
      internalURLOpener: TestInternalURLOpener(),
      internalUtility: TestInternalUtility(),
      metadataIndexer: TestMetadataIndexer(),
      modelManager: TestOnDeviceMLModelManager(),
      notificationCenter: TestNotificationCenter(),
      profileSetter: TestProfileProvider.self,
      rulesFromKeyProvider: TestOnDeviceMLModelManager(),
      sessionDataTaskProvider: TestSessionProvider(),
      skadNetworkReporter: TestSKAdNetworkReporter(),
      suggestedEventsIndexer: TestSuggestedEventsIndexer(),
      swizzler: TestSwizzler.self,
      urlHoster: TestURLHoster(),
      userIDProvider: TestUserIDProvider(),
      webViewProvider: TestWebViewFactory()
    )
  }
}
