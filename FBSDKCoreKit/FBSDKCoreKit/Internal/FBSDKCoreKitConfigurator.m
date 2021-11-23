/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCoreKitConfigurator.h"

#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKAppLinkUtility+Internal.h"
#import "FBSDKAuthenticationStatusUtility.h"
#import "FBSDKBridgeAPIRequest+Private.h"
#import "FBSDKButton+Internal.h"
#import "FBSDKError+Internal.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKModelManager.h"
#import "FBSDKServerConfigurationManager.h"
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
  [self configureAppEventsConfigurationManager];
  [self configureAppEventsUtility];
  [self configureButton];
  [self configureFeatureManager];
  [self configureGraphRequest];
  [self configureGraphRequestConnection];
  [self configureInstrumentManager];
  [self configureInternalUtility];
  [self configureSDKError];
  [self configureServerConfigurationManager];

#if !TARGET_OS_TV
  [self configureAppLinkURL];
  [self configureAppLinkUtility];
  [self configureAuthenticationStatusUtility];
  [self configureBridgeAPIRequest];
  [self configureFeatureExtractor];
  [self configureModelManager];
  [self configureWebDialogView];
#endif
}

- (void)configureAppEventsConfigurationManager
{
  [FBSDKAppEventsConfigurationManager configureWithStore:self.dependencies.defaultDataStore
                                                settings:self.dependencies.settings
                                     graphRequestFactory:self.dependencies.graphRequestFactory
                           graphRequestConnectionFactory:self.dependencies.graphRequestConnectionFactory];
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
                                          piggybackManagerProvider:self.dependencies.piggybackManagerProvider
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

// MARK: - Non-tvOS

#if !TARGET_OS_TV

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

- (void)configureWebDialogView
{
  [FBSDKWebDialogView configureWithWebViewProvider:self.dependencies.webViewProvider
                                         urlOpener:self.dependencies.internalURLOpener];
}

#endif

@end

NS_ASSUME_NONNULL_END
