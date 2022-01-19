/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitConfigurator.h"

#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppLinkNavigation+Internal.h"
#import "FBSDKAppLinkUtility+Internal.h"
#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKBridgeAPIRequest+Private.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKCodelessIndexer+Internal.h"
#import "FBSDKCrashShield+Internal.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKImpressionLoggingButton+Internal.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKModelManager.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKURL+Internal.h"
#import "FBSDKWebDialogView+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCoreKitConfigurator ()

@property (nonatomic) FBSDKCoreKitComponents *components;

@end

@implementation FBSDKCoreKitConfigurator

- (instancetype)initWithComponents:(FBSDKCoreKitComponents *)components
{
  if ((self = [super init])) {
    _components = components;
  }

  return self;
}

- (void)performConfiguration
{
  [self configureAccessToken];
  [self configureAppEvents];
  [self configureAppEventsConfigurationManager];
  [self configureAppEventsDeviceInfo];
  [self configureAppEventsState];
  [self configureAppEventsUtility];
  [self configureAuthenticationToken];
  [self configureButton];
  [self configureErrorFactory];
  [self configureFeatureManager];
  [self configureGatekeeperManager];
  [self configureGraphRequest];
  [self configureGraphRequestConnection];
  [self configureImpressionLoggingButton];
  [self configureInstrumentManager];
  [self configureInternalUtility];
  [self configureServerConfigurationManager];
  [self configureSettings];

#if !TARGET_OS_TV
  [self configureAEMReporter];
  [self configureNonTVOSAppEvents];
  [self configureAppLinkNavigation];
  [self configureAppLinkURL];
  [self configureAppLinkUtility];
  [self configureAuthenticationStatusUtility];
  [self configureBridgeAPIRequest];
  [self configureCodelessIndexer];
  [self configureCrashShield];
  [self configureFeatureExtractor];
  [self configureModelManager];
  [self configureProfile];
  [self configureWebDialogView];
#endif
}

// MARK: - All platforms

- (void)configureAccessToken
{
  [FBSDKAccessToken configureWithTokenCache:self.components.tokenCache
              graphRequestConnectionFactory:self.components.graphRequestConnectionFactory
               graphRequestPiggybackManager:self.components.piggybackManager
                               errorFactory:self.components.errorFactory];
}

- (void)configureAppEvents
{
  [FBSDKAppEvents.shared configureWithGateKeeperManager:self.components.gateKeeperManager
                         appEventsConfigurationProvider:self.components.appEventsConfigurationProvider
                            serverConfigurationProvider:self.components.serverConfigurationProvider
                                    graphRequestFactory:self.components.graphRequestFactory
                                         featureChecker:self.components.featureChecker
                                       primaryDataStore:self.components.defaultDataStore
                                                 logger:self.components.logger
                                               settings:self.components.settings
                                        paymentObserver:self.components.paymentObserver
                                      timeSpentRecorder:self.components.timeSpentRecorder
                                    appEventsStateStore:self.components.appEventsStateStore
                    eventDeactivationParameterProcessor:self.components.eventDeactivationManager
                restrictiveDataFilterParameterProcessor:self.components.restrictiveDataFilterManager
                                    atePublisherFactory:self.components.atePublisherFactory
                                 appEventsStateProvider:self.components.appEventsStateProvider
                                   advertiserIDProvider:self.components.advertiserIDProvider
                                          userDataStore:self.components.userDataStore
                                       appEventsUtility:self.components.appEventsUtility
                                        internalUtility:self.components.internalUtility];
}

- (void)configureAppEventsConfigurationManager
{
  [FBSDKAppEventsConfigurationManager.shared configureWithStore:self.components.defaultDataStore
                                                       settings:self.components.settings
                                            graphRequestFactory:self.components.graphRequestFactory
                                  graphRequestConnectionFactory:self.components.graphRequestConnectionFactory];
}

- (void)configureAppEventsDeviceInfo
{
  [FBSDKAppEventsDeviceInfo.shared configureWithSettings:self.components.settings];
}

- (void)configureAppEventsState
{
  FBSDKAppEventsState.eventProcessors = @[
    self.components.eventDeactivationManager,
    self.components.restrictiveDataFilterManager
  ];
}

- (void)configureAppEventsUtility
{
  [FBSDKAppEventsUtility.shared configureWithAppEventsConfigurationProvider:self.components.appEventsConfigurationProvider
                                                  deviceInformationProvider:self.components.deviceInformationProvider
                                                                   settings:self.components.settings
                                                            internalUtility:self.components.internalUtility
                                                               errorFactory:self.components.errorFactory];
}

- (void)configureAuthenticationToken
{
  FBSDKAuthenticationToken.tokenCache = self.components.tokenCache;
}

- (void)configureButton
{
  [FBSDKButton configureWithApplicationActivationNotifier:self.components.getApplicationActivationNotifier()
                                              eventLogger:self.components.eventLogger
                                      accessTokenProvider:self.components.accessTokenWallet];
}

- (void)configureErrorFactory
{
  [FBSDKErrorFactory configureWithDefaultReporter:self.components.errorReporter];
}

- (void)configureFeatureManager
{
  [FBSDKFeatureManager.shared configureWithGateKeeperManager:self.components.gateKeeperManager
                                                    settings:self.components.settings
                                                       store:self.components.defaultDataStore];
}

- (void)configureGatekeeperManager
{
  [FBSDKGateKeeperManager configureWithSettings:self.components.settings
                            graphRequestFactory:self.components.graphRequestFactory
                  graphRequestConnectionFactory:self.components.graphRequestConnectionFactory
                                          store:self.components.defaultDataStore];
}

- (void)configureGraphRequest
{
  [FBSDKGraphRequest configureWithSettings:self.components.settings
          currentAccessTokenStringProvider:self.components.accessTokenWallet
             graphRequestConnectionFactory:self.components.graphRequestConnectionFactory];
}

- (void)configureGraphRequestConnection
{
  [FBSDKGraphRequestConnection configureWithURLSessionProxyFactory:self.components.urlSessionProxyFactory
                                        errorConfigurationProvider:self.components.errorConfigurationProvider
                                                  piggybackManager:self.components.piggybackManager
                                                          settings:self.components.settings
                                     graphRequestConnectionFactory:self.components.graphRequestConnectionFactory
                                                       eventLogger:self.components.eventLogger
                                    operatingSystemVersionComparer:self.components.operatingSystemVersionComparer
                                           macCatalystDeterminator:self.components.macCatalystDeterminator
                                               accessTokenProvider:self.components.accessTokenWallet
                                                 accessTokenSetter:self.components.accessTokenWallet
                                                      errorFactory:self.components.errorFactory
                                       authenticationTokenProvider:self.components.authenticationTokenWallet];
  [FBSDKGraphRequestConnection setCanMakeRequests];
}

- (void)configureImpressionLoggingButton
{
  [FBSDKImpressionLoggingButton configureWithImpressionLoggerFactory:self.components.impressionLoggerFactory];
}

- (void)configureInstrumentManager
{
  [FBSDKInstrumentManager.shared configureWithFeatureChecker:self.components.featureChecker
                                                    settings:self.components.settings
                                               crashObserver:self.components.crashObserver
                                               errorReporter:self.components.errorReporter
                                                crashHandler:self.components.crashHandler];
}

- (void)configureInternalUtility
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.components.infoDictionaryProvider
                                                            loggerFactory:self.components.loggerFactory
                                                                 settings:self.components.settings
                                                             errorFactory:self.components.errorFactory];
}

- (void)configureServerConfigurationManager
{
  [FBSDKServerConfigurationManager.shared configureWithGraphRequestFactory:self.components.graphRequestFactory
                                             graphRequestConnectionFactory:self.components.graphRequestConnectionFactory
                                             dialogConfigurationMapBuilder:self.components.dialogConfigurationMapBuilder];
}

- (void)configureSettings
{
  [FBSDKSettings.sharedSettings configureWithStore:self.components.defaultDataStore
                    appEventsConfigurationProvider:self.components.appEventsConfigurationProvider
                            infoDictionaryProvider:self.components.infoDictionaryProvider
                                       eventLogger:self.components.eventLogger];
}

// MARK: - Non-tvOS

#if !TARGET_OS_TV

- (void)configureAEMReporter
{
  if (@available(iOS 14.0, *)) {
    [FBAEMReporter configureWithNetworker:self.components.aemNetworker
                                    appID:self.components.settings.appID
                                 reporter:self.components.skAdNetworkReporter];
  }
}

- (void)configureNonTVOSAppEvents
{
  [FBSDKAppEvents.shared configureNonTVComponentsWithOnDeviceMLModelManager:self.components.modelManager
                                                            metadataIndexer:self.components.metadataIndexer
                                                        skAdNetworkReporter:self.components.skAdNetworkReporter
                                                            codelessIndexer:self.components.codelessIndexer
                                                                   swizzler:self.components.swizzler
                                                                aemReporter:self.components.aemReporter];
}

- (void)configureAppLinkNavigation
{
  [FBSDKAppLinkNavigation configureWithSettings:self.components.settings
                                      urlOpener:self.components.internalURLOpener
                             appLinkEventPoster:self.components.appLinkEventPoster
                                appLinkResolver:self.components.appLinkResolver];
}

- (void)configureAppLinkURL
{
  [FBSDKURL configureWithSettings:self.components.settings
                   appLinkFactory:self.components.appLinkFactory
             appLinkTargetFactory:self.components.appLinkTargetFactory
               appLinkEventPoster:self.components.appLinkEventPoster];
}

- (void)configureAppLinkUtility
{
  [FBSDKAppLinkUtility configureWithGraphRequestFactory:self.components.graphRequestFactory
                                 infoDictionaryProvider:self.components.infoDictionaryProvider
                                               settings:self.components.settings
                         appEventsConfigurationProvider:self.components.appEventsConfigurationProvider
                                   advertiserIDProvider:self.components.advertiserIDProvider
                                appEventsDropDeterminer:self.components.appEventsDropDeterminer
                            appEventParametersExtractor:self.components.appEventParametersExtractor
                                      appLinkURLFactory:self.components.appLinkURLFactory
                                         userIDProvider:self.components.userIDProvider
                                          userDataStore:self.components.userDataStore];
}

- (void)configureAuthenticationStatusUtility
{
  [FBSDKAuthenticationStatusUtility configureWithProfileSetter:self.components.profileSetter
                                       sessionDataTaskProvider:self.components.sessionDataTaskProvider
                                             accessTokenWallet:self.components.accessTokenWallet
                                     authenticationTokenWallet:self.components.authenticationTokenWallet];
}

- (void)configureBridgeAPIRequest
{
  [FBSDKBridgeAPIRequest configureWithInternalURLOpener:self.components.internalURLOpener
                                        internalUtility:self.components.internalUtility
                                               settings:self.components.settings];
}

- (void)configureCodelessIndexer
{
  [FBSDKCodelessIndexer configureWithGraphRequestFactory:self.components.graphRequestFactory
                             serverConfigurationProvider:self.components.serverConfigurationProvider
                                               dataStore:self.components.defaultDataStore
                           graphRequestConnectionFactory:self.components.graphRequestConnectionFactory
                                                swizzler:self.components.swizzler
                                                settings:self.components.settings
                                    advertiserIDProvider:self.components.advertiserIDProvider];
}

- (void)configureCrashShield
{
  [FBSDKCrashShield configureWithSettings:self.components.settings
                      graphRequestFactory:self.components.graphRequestFactory
                          featureChecking:self.components.featureChecker];
}

- (void)configureFeatureExtractor
{
  [FBSDKFeatureExtractor configureWithRulesFromKeyProvider:self.components.rulesFromKeyProvider];
}

- (void)configureModelManager
{
  [FBSDKModelManager.shared configureWithFeatureChecker:self.components.featureChecker
                                    graphRequestFactory:self.components.graphRequestFactory
                                            fileManager:self.components.fileManager
                                                  store:self.components.defaultDataStore
                                               settings:self.components.settings
                                          dataExtractor:self.components.dataExtractor
                                      gateKeeperManager:self.components.gateKeeperManager
                                 suggestedEventsIndexer:self.components.suggestedEventsIndexer
                                       featureExtractor:self.components.featureExtractor];
}

- (void)configureProfile
{
  [FBSDKProfile configureWithDataStore:self.components.defaultDataStore
                   accessTokenProvider:self.components.accessTokenWallet
                    notificationCenter:self.components.notificationCenter
                              settings:self.components.settings
                             urlHoster:self.components.urlHoster];
}

- (void)configureWebDialogView
{
  [FBSDKWebDialogView configureWithWebViewProvider:self.components.webViewProvider
                                         urlOpener:self.components.internalURLOpener
                                      errorFactory:self.components.errorFactory];
}

#endif

@end

NS_ASSUME_NONNULL_END
