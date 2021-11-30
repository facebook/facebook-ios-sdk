/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitConfigurator.h"

#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppLinkNavigation+Internal.h"
#import "FBSDKAppLinkUtility+Internal.h"
#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKBridgeAPIRequest+Private.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKCodelessIndexer+Internal.h"
#import "FBSDKCrashShield+Internal.h"
#import "FBSDKError+Internal.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKGraphRequestPiggybackManager+Internal.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKModelManager.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKURL+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCoreKitConfigurator ()

@property (nonatomic) FBSDKSharedDependencies *dependencies;

@end

@implementation FBSDKCoreKitConfigurator

- (instancetype)initWithDependencies:(FBSDKSharedDependencies *)dependencies
{
  if ((self = [super init])) {
    _dependencies = dependencies;
  }

  return self;
}

- (void)configureTargets
{
  [self configureAccessToken];
  [self configureAppEvents];
  [self configureAppEventsConfigurationManager];
  [self configureAppEventsState];
  [self configureAppEventsUtility];
  [self configureButton];
  [self configureFeatureManager];
  [self configureGatekeeperManager];
  [self configureGraphRequest];
  [self configureGraphRequestConnection];
  [self configureGraphRequestPiggybackManager];
  [self configureInstrumentManager];
  [self configureInternalUtility];
  [self configureSDKError];
  [self configureServerConfigurationManager];
  [self configureSettings];

#if !TARGET_OS_TV
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

- (void)configureAccessToken
{
  [FBSDKAccessToken configureWithTokenCache:self.dependencies.tokenCache
              graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory
               graphRequestPiggybackManager:self.dependencies.piggybackManager];
}

- (void)configureAppEvents
{
  [FBSDKAppEvents.shared configureWithGateKeeperManager:self.dependencies.gateKeeperManager
                         appEventsConfigurationProvider:self.dependencies.appEventsConfigurationProvider
                            serverConfigurationProvider:self.dependencies.serverConfigurationProvider
                                    graphRequestFactory:self.dependencies.graphRequestFactory
                                         featureChecker:self.dependencies.featureChecker
                                       primaryDataStore:self.dependencies.defaultDataStore
                                                 logger:self.dependencies.logger
                                               settings:self.dependencies.settings
                                        paymentObserver:self.dependencies.paymentObserver
                                      timeSpentRecorder:self.dependencies.timeSpentRecorder
                                    appEventsStateStore:self.dependencies.appEventsStateStore
                    eventDeactivationParameterProcessor:self.dependencies.eventDeactivationManager
                restrictiveDataFilterParameterProcessor:self.dependencies.restrictiveDataFilterManager
                                    atePublisherFactory:self.dependencies.atePublisherFactory
                                 appEventsStateProvider:self.dependencies.appEventsStateProvider
                                   advertiserIDProvider:self.dependencies.advertiserIDProvider
                                          userDataStore:self.dependencies.userDataStore];
}

- (void)configureAppEventsConfigurationManager
{
  [FBSDKAppEventsConfigurationManager configureWithStore:self.dependencies.defaultDataStore
                                                settings:self.dependencies.settings
                                     graphRequestFactory:self.dependencies.graphRequestFactory
                           graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory];
}

- (void)configureAppEventsState
{
  FBSDKAppEventsState.eventProcessors = @[
    self.dependencies.eventDeactivationManager,
    self.dependencies.restrictiveDataFilterManager
  ];
}

- (void)configureAppEventsUtility
{
  FBSDKAppEventsUtility.shared.appEventsConfigurationProvider = self.dependencies.appEventsConfigurationProvider;
  FBSDKAppEventsUtility.shared.deviceInformationProvider = self.dependencies.deviceInformationProvider;
}

- (void)configureButton
{
  [FBSDKButton configureWithApplicationActivationNotifier:self.dependencies.applicationActivationNotifier
                                              eventLogger:self.dependencies.eventLogger
                                      accessTokenProvider:self.dependencies.accessTokenWallet];
}

- (void)configureFeatureManager
{
  [FBSDKFeatureManager.shared configureWithGateKeeperManager:self.dependencies.gateKeeperManager
                                                    settings:self.dependencies.settings
                                                       store:self.dependencies.defaultDataStore];
}

- (void)configureGatekeeperManager
{
  [FBSDKGateKeeperManager configureWithSettings:self.dependencies.settings
                            graphRequestFactory:self.dependencies.graphRequestFactory
                  graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory
                                          store:self.dependencies.defaultDataStore];
}

- (void)configureGraphRequest
{
  [FBSDKGraphRequest configureWithSettings:self.dependencies.settings
          currentAccessTokenStringProvider:self.dependencies.accessTokenWallet
             graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory];
}

- (void)configureGraphRequestConnection
{
  [FBSDKGraphRequestConnection configureWithURLSessionProxyFactory:self.dependencies.urlSessionProxyFactory
                                        errorConfigurationProvider:self.dependencies.errorConfigurationProvider
                                                  piggybackManager:self.dependencies.piggybackManager
                                                          settings:self.dependencies.settings
                                     graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory
                                                       eventLogger:self.dependencies.eventLogger
                                    operatingSystemVersionComparer:self.dependencies.operatingSystemVersionComparer
                                           macCatalystDeterminator:self.dependencies.macCatalystDeterminator
                                               accessTokenProvider:self.dependencies.accessTokenWallet
                                                 accessTokenSetter:self.dependencies.accessTokenWallet
                                                      errorFactory:self.dependencies.errorFactory
                                       authenticationTokenProvider:self.dependencies.authenticationTokenWallet];
}

- (void)configureGraphRequestPiggybackManager
{
  [FBSDKGraphRequestPiggybackManager configureWithTokenWallet:self.dependencies.accessTokenWallet
                                                     settings:self.dependencies.settings
                                  serverConfigurationProvider:self.dependencies.serverConfigurationProvider
                                          graphRequestFactory:self.dependencies.graphRequestFactory];
}

- (void)configureInstrumentManager
{
  [FBSDKInstrumentManager.shared configureWithFeatureChecker:self.dependencies.featureChecker
                                                    settings:self.dependencies.settings
                                               crashObserver:self.dependencies.crashObserver
                                               errorReporter:self.dependencies.errorReporter
                                                crashHandler:self.dependencies.crashHandler];
}

- (void)configureInternalUtility
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.dependencies.infoDictionaryProvider
                                                            loggerFactory:self.dependencies.loggerFactory];
}

- (void)configureSDKError
{
  [FBSDKError configureWithErrorReporter:self.dependencies.errorReporter];
}

- (void)configureServerConfigurationManager
{
  [FBSDKServerConfigurationManager.shared configureWithGraphRequestFactory:self.dependencies.graphRequestFactory
                                             graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory];
}

- (void)configureSettings
{
  [FBSDKSettings configureWithStore:self.dependencies.defaultDataStore
     appEventsConfigurationProvider:self.dependencies.appEventsConfigurationProvider
             infoDictionaryProvider:self.dependencies.infoDictionaryProvider
                        eventLogger:self.dependencies.eventLogger];
}

// MARK: - Non-tvOS

#if !TARGET_OS_TV

- (void)configureNonTVOSAppEvents
{
  [FBSDKAppEvents.shared configureNonTVComponentsWithOnDeviceMLModelManager:self.dependencies.modelManager
                                                            metadataIndexer:self.dependencies.metadataIndexer
                                                        skAdNetworkReporter:self.dependencies.skAdNetworkReporter
                                                            codelessIndexer:self.dependencies.codelessIndexer
                                                                   swizzler:self.dependencies.swizzler
                                                                aemReporter:self.dependencies.aemReporter];
}

- (void)configureAppLinkNavigation
{
  [FBSDKAppLinkNavigation configureWithSettings:self.dependencies.settings
                                      urlOpener:self.dependencies.internalURLOpener
                             appLinkEventPoster:self.dependencies.appLinkEventPoster
                                appLinkResolver:self.dependencies.appLinkResolver];
}

- (void)configureAppLinkURL
{
  [FBSDKURL configureWithSettings:self.dependencies.settings
                   appLinkFactory:self.dependencies.appLinkFactory
             appLinkTargetFactory:self.dependencies.appLinkTargetFactory
               appLinkEventPoster:self.dependencies.appLinkEventPoster];
}

- (void)configureAppLinkUtility
{
  [FBSDKAppLinkUtility configureWithGraphRequestFactory:self.dependencies.graphRequestFactory
                                 infoDictionaryProvider:self.dependencies.infoDictionaryProvider
                                               settings:self.dependencies.settings
                         appEventsConfigurationProvider:self.dependencies.appEventsConfigurationProvider
                                   advertiserIDProvider:self.dependencies.advertiserIDProvider
                                appEventsDropDeterminer:self.dependencies.appEventsDropDeterminer
                            appEventParametersExtractor:self.dependencies.appEventParametersExtractor
                                      appLinkURLFactory:self.dependencies.appLinkURLFactory
                                         userIDProvider:self.dependencies.userIDProvider
                                          userDataStore:self.dependencies.userDataStore];
}

- (void)configureAuthenticationStatusUtility
{
  [FBSDKAuthenticationStatusUtility configureWithProfileSetter:self.dependencies.profileSetter
                                       sessionDataTaskProvider:self.dependencies.sessionDataTaskProvider
                                             accessTokenWallet:self.dependencies.accessTokenWallet
                                     authenticationTokenWallet:self.dependencies.authenticationTokenWallet];
}

- (void)configureBridgeAPIRequest
{
  [FBSDKBridgeAPIRequest configureWithInternalURLOpener:self.dependencies.internalURLOpener
                                        internalUtility:self.dependencies.internalUtility
                                               settings:self.dependencies.settings];
}

- (void)configureCodelessIndexer
{
  [FBSDKCodelessIndexer configureWithGraphRequestFactory:self.dependencies.graphRequestFactory
                             serverConfigurationProvider:self.dependencies.serverConfigurationProvider
                                               dataStore:self.dependencies.defaultDataStore
                           graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory
                                                swizzler:self.dependencies.swizzler
                                                settings:self.dependencies.settings
                                    advertiserIDProvider:self.dependencies.advertiserIDProvider];
}

- (void)configureCrashShield
{
  [FBSDKCrashShield configureWithSettings:self.dependencies.settings
                      graphRequestFactory:self.dependencies.graphRequestFactory
                          featureChecking:self.dependencies.featureChecker];
}

- (void)configureFeatureExtractor
{
  [FBSDKFeatureExtractor configureWithRulesFromKeyProvider:self.dependencies.rulesFromKeyProvider];
}

- (void)configureModelManager
{
  [FBSDKModelManager.shared configureWithFeatureChecker:self.dependencies.featureChecker
                                    graphRequestFactory:self.dependencies.graphRequestFactory
                                            fileManager:self.dependencies.fileManager
                                                  store:self.dependencies.defaultDataStore
                                               settings:self.dependencies.settings
                                          dataExtractor:self.dependencies.dataExtractor
                                      gateKeeperManager:self.dependencies.gateKeeperManager
                                 suggestedEventsIndexer:self.dependencies.suggestedEventsIndexer
                                       featureExtractor:self.dependencies.featureExtractor];
}

- (void)configureProfile
{
  [FBSDKProfile configureWithDataStore:self.dependencies.defaultDataStore
                   accessTokenProvider:self.dependencies.accessTokenWallet
                    notificationCenter:self.dependencies.notificationCenter
                              settings:self.dependencies.settings
                             urlHoster:self.dependencies.urlHoster];
}

- (void)configureWebDialogView
{
  [FBSDKWebDialogView configureWithWebViewProvider:self.dependencies.webViewProvider
                                         urlOpener:self.dependencies.internalURLOpener];
}

#endif

@end

NS_ASSUME_NONNULL_END
